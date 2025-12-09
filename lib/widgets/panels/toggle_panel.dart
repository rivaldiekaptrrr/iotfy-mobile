import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';
import '../../utils/icon_helper.dart';

class TogglePanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const TogglePanel({super.key, required this.config});

  @override
  ConsumerState<TogglePanel> createState() => _TogglePanelState();
}

class _TogglePanelState extends ConsumerState<TogglePanel> {
  bool _isOn = false;
  bool _isLoading = false;
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
            setState(() {
              _isOn = message.payload.toUpperCase() == widget.config.onPayload?.toUpperCase();
              _isLoading = false;
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
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;
    final isError = connectionStatus.value == ConnectionStatus.error;
    final lastError = ref.read(mqttServiceProvider).lastError;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.config.iconCodePoint != null && IconHelper.getIcon(widget.config.iconCodePoint) != null)
              Icon(
                IconHelper.getIcon(widget.config.iconCodePoint)!,
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
                onChanged: (value) {
                  if (!isConnected) {
                    _showConnectionWarning(context, lastError);
                    return;
                  }
                  _toggleSwitch(value);
                },
                activeColor: widget.config.color,
                trackOutlineColor: MaterialStatePropertyAll(scheme.outlineVariant),
              ),
            const SizedBox(height: 8),
            if (!isConnected)
              Text(
                isError ? 'MQTT error' : 'Disconnected',
                style: TextStyle(color: isError ? Colors.orange : Colors.red, fontSize: 12),
              ),
            if (isError && lastError != null)
              Text(
                lastError,
                style: const TextStyle(color: Colors.orange, fontSize: 11),
                textAlign: TextAlign.center,
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

  void _showConnectionWarning(BuildContext context, String? lastError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lastError != null ? 'Tidak dapat publish: $lastError' : 'Koneksi MQTT belum tersambung'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}