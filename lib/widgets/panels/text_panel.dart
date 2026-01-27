import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';

class TextPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const TextPanel({super.key, required this.config});

  @override
  ConsumerState<TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends ConsumerState<TextPanel> {
  String? _lastPayload;
  DateTime? _lastUpdated;
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>>
  _messageSub;

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
    _messageSub = ref.listenManual<AsyncValue<app_mqtt.MqttMessageData>>(
      mqttMessagesProvider,
      (_, next) {
        next.whenData((message) {
          if (message.topic == widget.config.subscribeTopic) {
            setState(() {
              _lastPayload = message.payload;
              _lastUpdated = DateTime.now();
            });
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (widget.config.icon != null) ...[
                Icon(widget.config.icon, color: widget.config.color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.config.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: widget.config.icon != null
                      ? TextAlign.left
                      : TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _lastPayload ?? 'Waiting...',
                  key: ValueKey(_lastPayload),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _lastPayload != null
                        ? widget.config.color
                        : Theme.of(context).disabledColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (_lastUpdated != null)
            Text(
              'Updated: ${_lastUpdated!.toLocal().toString().split('.')[0].split(' ')[1]}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
