import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';

class LinearGaugePanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const LinearGaugePanel({super.key, required this.config});

  @override
  ConsumerState<LinearGaugePanel> createState() => _LinearGaugePanelState();
}

class _LinearGaugePanelState extends ConsumerState<LinearGaugePanel> {
  double _currentValue = 0;
  // ignore: unused_field
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
    // Determine color based on threshold
    Color barColor = Colors.blue;
    if (widget.config.criticalThreshold != null && _currentValue >= widget.config.criticalThreshold!) {
      barColor = Colors.red;
    } else if (widget.config.warningThreshold != null && _currentValue >= widget.config.warningThreshold!) {
      barColor = Colors.orange;
    } else {
      barColor = widget.config.color;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Expanded(
                 child: Text(
                   widget.config.title, 
                   style: Theme.of(context).textTheme.titleMedium, 
                   maxLines: 1, 
                   overflow: TextOverflow.ellipsis
                 )
               ),
               Text(
                 "${_currentValue.toStringAsFixed(widget.config.decimalPlaces)} ${widget.config.unit ?? ''}", 
                 style: const TextStyle(fontWeight: FontWeight.bold)
               ),
            ],
          ),
          const Expanded(child: SizedBox()),
          SfLinearGauge(
            minimum: widget.config.minValue ?? 0,
            maximum: widget.config.maxValue ?? 100,
            orientation: LinearGaugeOrientation.horizontal,
            axisTrackStyle: LinearAxisTrackStyle(
              thickness: 16,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              edgeStyle: LinearEdgeStyle.bothCurve,
            ),
            barPointers: [
              LinearBarPointer(
                value: _currentValue,
                color: barColor,
                thickness: 16,
                edgeStyle: LinearEdgeStyle.bothCurve,
                animationDuration: 1000,
              )
            ],
            markerPointers: [
              if (widget.config.warningThreshold != null)
                LinearShapePointer(
                   value: widget.config.warningThreshold!,
                   color: Colors.orange,
                   position: LinearElementPosition.outside,
                   shapeType: LinearShapePointerType.invertedTriangle,
                ),
              if (widget.config.criticalThreshold != null)
                LinearShapePointer(
                   value: widget.config.criticalThreshold!,
                   color: Colors.red,
                   position: LinearElementPosition.outside,
                   shapeType: LinearShapePointerType.invertedTriangle,
                ),
            ],
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
