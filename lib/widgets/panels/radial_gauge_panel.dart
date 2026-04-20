import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';

class RadialGaugePanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const RadialGaugePanel({super.key, required this.config});

  @override
  ConsumerState<RadialGaugePanel> createState() => _RadialGaugePanelState();
}

class _RadialGaugePanelState extends ConsumerState<RadialGaugePanel> {
  double _currentValue = 0;
  String? _error;
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>> _messageSub;

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

  void _updateValue(String payload) {
    try {
      final val = double.parse(payload);
      setState(() {
        _currentValue = val.clamp(
          widget.config.minValue ?? 0, 
          widget.config.maxValue ?? 100
        );
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid';
      });
    }
  }

  @override
  void dispose() {
    _messageSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
           Text(widget.config.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1),
           const SizedBox(height: 8),
           Expanded(
             child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    showLabels: false,
                    showTicks: false,
                    startAngle: 270,
                    endAngle: 270,
                    minimum: widget.config.minValue ?? 0,
                    maximum: widget.config.maxValue ?? 100,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.2,
                      thicknessUnit: GaugeSizeUnit.factor,
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: _currentValue,
                        width: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                        color: widget.config.color,
                        cornerStyle: CornerStyle.bothCurve,
                        enableAnimation: true,
                      )
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        positionFactor: 0.1,
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentValue.toStringAsFixed(widget.config.decimalPlaces),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: scheme.onSurface),
                            ),
                            if (widget.config.unit != null)
                             Text(widget.config.unit!, style: TextStyle(fontSize: 12, color: scheme.outline)),
                          ],
                        ),
                      )
                    ],
                  )
                ],
             ),
           ),
           if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 10))
        ],
      ),
    );
  }
}
