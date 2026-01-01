import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class TerminalPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const TerminalPanel({super.key, required this.config});

  @override
  ConsumerState<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends ConsumerState<TerminalPanel> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
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
            _addLog(message.payload);
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

  void _addLog(String payload) {
    setState(() {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      _logs.insert(0, "[$timeStr] $payload"); // Insert at top
      if (_logs.length > 50) _logs.removeLast(); // Remove oldest (now at bottom)
    });
    // Scroll to top to see new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSub.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Hacker theme
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '> ${widget.config.title}', 
            style: const TextStyle(color: Colors.green, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(color: Colors.green, height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(
                  _logs[index],
                  style: const TextStyle(
                    color: Colors.greenAccent, 
                    fontFamily: 'monospace', 
                    fontSize: 12
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
