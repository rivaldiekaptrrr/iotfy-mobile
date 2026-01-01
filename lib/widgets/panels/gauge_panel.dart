import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class GaugePanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const GaugePanel({super.key, required this.config});

  @override
  ConsumerState<GaugePanel> createState() => _GaugePanelState();
}

class _GaugePanelState extends ConsumerState<GaugePanel> {
  double _currentValue = 0;
  String? _error;
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>> _messageSub;
  DateTime? _lastUpdated;
  double? _lastValue;

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
    _messageSub = ref.listenManual<AsyncValue<app_mqtt.MqttMessageData>>(
      mqttMessagesProvider,
      (_, next) {
        next.whenData((message) {
          if (message.topic == widget.config.subscribeTopic) {
            _updateValue(message.payload);
          }
        });
      },
    );
  }

  void _subscribeToTopic() {
    if (widget.config.subscribeTopic != null) {
      final service = ref.read(mqttServiceProvider);
      service.subscribe(widget.config.subscribeTopic!, qos: widget.config.qos);
    }
  }

  @override
  void dispose() {
    _messageSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;
    final isError = connectionStatus.value == ConnectionStatus.error;
    final lastError = ref.read(mqttServiceProvider).lastError;
    final scheme = Theme.of(context).colorScheme;

    // Simplified without Card wrapper as it is handled by PanelContainer
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.config.title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              : !isConnected
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.wifi_off,
                          color: isError ? Colors.red : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isError ? 'MQTT Error' : 'Offline',
                          style: TextStyle(
                            color: isError ? Colors.red : Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  )
                  : SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          startAngle: 180,
                          endAngle: 0,
                          canScaleToFit: true,
                          showLabels: false,
                          showTicks: false,
                          minimum: widget.config.minValue ?? 0,
                          maximum: widget.config.maxValue ?? 100,
                          axisLineStyle: AxisLineStyle(
                            thickness: 0.18,
                            thicknessUnit: GaugeSizeUnit.factor,
                            color: scheme.surfaceContainerHighest,
                            cornerStyle: CornerStyle.bothCurve,
                          ),
                          ranges: <GaugeRange>[
                            // Normal Range (Min to Warning or Critical or Max)
                            GaugeRange(
                              startValue: widget.config.minValue ?? 0,
                              endValue: widget.config.warningThreshold ?? widget.config.criticalThreshold ?? widget.config.maxValue ?? 100,
                              color: Colors.green, // Or using widget.config.color? Usually "Safe" is green.
                              startWidth: 0.18,
                              endWidth: 0.18,
                              sizeUnit: GaugeSizeUnit.factor,
                            ),
                            if (widget.config.warningThreshold != null)
                              GaugeRange(
                                startValue: widget.config.warningThreshold!,
                                endValue: widget.config.criticalThreshold ?? widget.config.maxValue ?? 100,
                                color: Colors.orange,
                                startWidth: 0.18,
                                endWidth: 0.18,
                                sizeUnit: GaugeSizeUnit.factor,
                              ),
                             if (widget.config.criticalThreshold != null)
                              GaugeRange(
                                startValue: widget.config.criticalThreshold!,
                                endValue: widget.config.maxValue ?? 100,
                                color: Colors.red,
                                startWidth: 0.18,
                                endWidth: 0.18,
                                sizeUnit: GaugeSizeUnit.factor,
                              ),
                          ],
                          pointers: <GaugePointer>[
                             NeedlePointer(
                               value: _currentValue,
                               needleLength: 0.6,
                               lengthUnit: GaugeSizeUnit.factor,
                               needleStartWidth: 1,
                               needleEndWidth: 5,
                               knobStyle: KnobStyle(
                                 knobRadius: 0.05,
                                 sizeUnit: GaugeSizeUnit.factor,
                                 color: scheme.onSurface,
                               ),
                               gradient: LinearGradient(
                                 colors: [scheme.primary, scheme.tertiary],
                                 begin: Alignment.topCenter,
                                 end: Alignment.bottomCenter
                               ),
                               animationType: AnimationType.easeOutBack,
                               enableAnimation: true,
                               animationDuration: 800,
                             ),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              widget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentValue.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurface,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  if (widget.config.unit != null && widget.config.unit!.isNotEmpty)
                                    Text(
                                      widget.config.unit!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.secondary,
                                      ),
                                    ),
                                ],
                              ),
                              angle: 90,
                              positionFactor: 0.1,
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  void _updateValue(String payload) {
    try {
      final value = double.parse(payload);
      setState(() {
        _currentValue = value.clamp(
          widget.config.minValue ?? 0,
          widget.config.maxValue ?? 100,
        );
        _error = null;
        _lastUpdated = DateTime.now();
        _lastValue = value;
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid data';
      });
    }
  }
}