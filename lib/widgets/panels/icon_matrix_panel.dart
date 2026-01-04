import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class IconMatrixPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const IconMatrixPanel({super.key, required this.config});

  @override
  ConsumerState<IconMatrixPanel> createState() => _IconMatrixPanelState();
}

class _IconMatrixPanelState extends ConsumerState<IconMatrixPanel> {
  int _statusMask = 0;
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
      final val = int.parse(payload);
      setState(() {
        _statusMask = val;
      });
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _messageSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine labels
    List<String> labels = widget.config.options ?? [];
    if (labels.isEmpty) {
      labels = List.generate(9, (i) => "S${i + 1}");
    }
    
    // Grid size depends on count. Let's aim for 3x3 max for now or dynamic.
    // If labels > 9, scroll?
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(widget.config.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              itemCount: labels.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 80,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final isOn = (_statusMask & (1 << index)) != 0;
                return Container(
                  decoration: BoxDecoration(
                    color: isOn ? (widget.config.colorValue != null ? Color(widget.config.colorValue!) : Colors.green) : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOn ? Colors.transparent : Theme.of(context).dividerColor,
                    )
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOn ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isOn ? Colors.white : Theme.of(context).disabledColor,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isOn ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
