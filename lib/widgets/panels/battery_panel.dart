import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';

class BatteryPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const BatteryPanel({super.key, required this.config});

  @override
  ConsumerState<BatteryPanel> createState() => _BatteryPanelState();
}

class _BatteryPanelState extends ConsumerState<BatteryPanel> {
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
        _currentValue = val;
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
    // Assuming 0-100 or user configured min/max mapped to 0-1
    double percent = (_currentValue - (widget.config.minValue ?? 0)) / 
                     ((widget.config.maxValue ?? 100) - (widget.config.minValue ?? 0));
    percent = percent.clamp(0.0, 1.0);
    
    // Choose color
    Color batColor = Colors.green;
    if (percent <= 0.2) {
      batColor = Colors.red;
    } else if (percent <= 0.5) {
      batColor = Colors.orange;
    }
    
    // Override if user selected generic color and it's not default blue
    if (widget.config.colorValue != null) {
        // Only use user color if they explicitly set something other than simple default?
        // Or blend it. Let's stick to Green/Orange/Red for battery logic unless forced.
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Expanded(child: Text(widget.config.title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1)),
               Text('${(percent * 100).toInt()}%', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          // Battery Icon drawn manually or Stack
          SizedBox(
            height: 60,
            width: 120, // Wide aspect
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                   // Body
                 Container(
                   decoration: BoxDecoration(
                     border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 4),
                     borderRadius: BorderRadius.circular(8),
                   ),
                 ),
                 // Terminal (Nipple)
                 Positioned(
                   right: 0,
                   child: Container(
                     width: 8,
                     height: 20,
                     margin: const EdgeInsets.only(right: 0), // actually outside?
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.outlineVariant,
                       borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4))
                     ),
                   ),
                 ),
                 // Fill
                 FractionallySizedBox(
                   widthFactor: percent, // slightly less to fit inside borders?
                   child: Container(
                     margin: const EdgeInsets.all(6), // inside border
                     decoration: BoxDecoration(
                       color: batColor,
                       borderRadius: BorderRadius.circular(4),
                     ),
                   ),
                 ),
                 // Charging Bolt? (Optional, if we knew state)
                 if (_currentValue > 0) // Just always show bolt if ... nah.
                   const Center(child: Icon(Icons.electric_bolt, color: Colors.white30, size: 24)),
              ],
            ),
          ),
          const Spacer(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 10))
        ],
      ),
    );
  }
}
