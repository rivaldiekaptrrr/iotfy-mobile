import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class CompassPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const CompassPanel({super.key, required this.config});

  @override
  ConsumerState<CompassPanel> createState() => _CompassPanelState();
}

class _CompassPanelState extends ConsumerState<CompassPanel> {
  double _heading = 0;
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
        _heading = val % 360; // Ensure 0-360
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
           Text(widget.config.title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1),
           Expanded(
             child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    startAngle: 270,
                    endAngle: 270,
                    minimum: 0,
                    maximum: 360,
                    showLabels: false,
                    showTicks: true,
                    majorTickStyle: const MajorTickStyle(length: 0.1, lengthUnit: GaugeSizeUnit.factor),
                    minorTickStyle: const MinorTickStyle(length: 0.05, lengthUnit: GaugeSizeUnit.factor),
                    axisLabelStyle: const GaugeTextStyle(fontSize: 12),
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.05,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: _heading,
                        needleLength: 0.6,
                        lengthUnit: GaugeSizeUnit.factor,
                        needleStartWidth: 1,
                        needleEndWidth: 5,
                        needleColor: Colors.red,
                        knobStyle: KnobStyle(knobRadius: 0.05, color: scheme.onSurface),
                        enableAnimation: true,
                        animationDuration: 800,
                      )
                    ],
                    annotations: <GaugeAnnotation>[
                      const GaugeAnnotation(angle: 270, positionFactor: 0.4, widget: Text('N', style: TextStyle(fontWeight: FontWeight.bold))),
                      const GaugeAnnotation(angle: 0, positionFactor: 0.4, widget: Text('E', style: TextStyle(fontWeight: FontWeight.bold))),
                      const GaugeAnnotation(angle: 90, positionFactor: 0.4, widget: Text('S', style: TextStyle(fontWeight: FontWeight.bold))),
                      const GaugeAnnotation(angle: 180, positionFactor: 0.4, widget: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                      
                      GaugeAnnotation(
                        angle: 90, 
                        positionFactor: 0.8,
                        widget: Text(
                          "${_heading.toStringAsFixed(0)}°",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.primary),
                        ),
                      )
                    ],
                  )
                ],
             ),
           ),
        ],
      ),
    );
  }
}
