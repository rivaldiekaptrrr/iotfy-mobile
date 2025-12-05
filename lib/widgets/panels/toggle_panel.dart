import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class TogglePanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const TogglePanel({super.key, required this.config});

  @override
  ConsumerState<TogglePanel> createState() => _TogglePanelState();
}

class _TogglePanelState extends ConsumerState<TogglePanel> {
  bool _isOn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
  }

  void _subscribeToTopic() {
    if (widget.config.subscribeTopic != null) {
      final service = ref.read(mqttServiceProvider);
      service.subscribe(widget.config.subscribeTopic!, qos: widget.config.qos);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<app_mqtt.MqttMessageData>>(mqttMessagesProvider, (_, next) {
      next.whenData((message) {
        if (message.topic == widget.config.subscribeTopic) {
          setState(() {
            _isOn = message.payload.toUpperCase() == widget.config.onPayload?.toUpperCase();
            _isLoading = false;
          });
        }
      });
    });

    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.config.icon != null)
              Icon(
                widget.config.icon,
                size: 32,
                color: widget.config.color,
              ),
            const SizedBox(height: 8),
            Text(
              widget.config.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Switch(
                value: _isOn,
                onChanged: isConnected
                    ? (value) {
                        _toggleSwitch(value);
                      }
                    : null,
                activeColor: widget.config.color,
              ),
            const SizedBox(height: 8),
            if (!isConnected)
              const Text(
                'Disconnected',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSwitch(bool value) {
    if (widget.config.publishTopic == null) return;

    setState(() {
      _isLoading = true;
      _isOn = value;
    });

    final service = ref.read(mqttServiceProvider);
    final payload = value ? widget.config.onPayload! : widget.config.offPayload!;
    
    service.publish(
      widget.config.publishTopic!,
      payload,
      qos: widget.config.qos,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
}