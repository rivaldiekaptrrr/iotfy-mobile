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

    // No Card wrapper - handled by PanelContainer
    final icon = IconHelper.getIcon(widget.config.iconCodePoint);
    
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 140),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 32,
                color: _isOn ? widget.config.color : scheme.onSurfaceVariant,
              ),
            if (icon != null) const SizedBox(height: 8),
            Text(
              widget.config.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
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
                trackOutlineColor: WidgetStatePropertyAll(scheme.outlineVariant),
              ),
            const SizedBox(height: 8),
            if (!isConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isError ? Colors.red : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isError ? 'Error' : 'Offline',
                  style: TextStyle(color: isError ? Colors.red : Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
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