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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 180),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.config.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (!isConnected)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isError ? Icons.error_outline : Icons.wifi_off,
                        color: isError ? Colors.red : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isError ? 'MQTT Error' : 'Offline',
                        style: TextStyle(
                          color: isError ? Colors.red : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: SfRadialGauge(
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
                        thickness: 0.2,
                        thicknessUnit: GaugeSizeUnit.factor,
                        color: scheme.surfaceContainerHighest,
                        cornerStyle: CornerStyle.bothCurve,
                      ),
                      pointers: <GaugePointer>[
                        RangePointer(
                          value: _currentValue,
                          width: 0.2,
                          sizeUnit: GaugeSizeUnit.factor,
                          cornerStyle: CornerStyle.bothCurve,
                          gradient: SweepGradient(
                            colors: [
                              widget.config.color.withOpacity(0.5),
                              widget.config.color,
                            ],
                            stops: const <double>[0.25, 0.75],
                          ),
                          enableAnimation: true,
                          animationDuration: 1000,
                          animationType: AnimationType.easeOutBack,
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
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onSurface,
                                  letterSpacing: -1,
                                ),
                              ),
                              if (widget.config.unit != null && widget.config.unit!.isNotEmpty)
                                Text(
                                  widget.config.unit!,
                                  style: TextStyle(
                                    fontSize: 12,
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
            if (isError && lastError != null)
               Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  lastError,
                  style: const TextStyle(color: Colors.orange, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (_lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Updated ${_lastUpdated!.toLocal().toIso8601String().substring(11, 19)}',
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
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