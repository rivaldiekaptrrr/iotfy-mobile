import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';
import '../../utils/icon_helper.dart';

class ButtonPanel extends ConsumerWidget {
  final PanelWidgetConfig config;

  const ButtonPanel({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;
    final isError = connectionStatus.value == ConnectionStatus.error;
    final lastError = ref.read(mqttServiceProvider).lastError;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (!isConnected) {
            _showConnectionWarning(context, lastError);
            return;
          }
          _onButtonPressed(ref);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (config.iconCodePoint != null && IconHelper.getIcon(config.iconCodePoint) != null)
                Icon(
                  IconHelper.getIcon(config.iconCodePoint)!,
                  size: 48,
                  color: isConnected ? config.color : scheme.onSurfaceVariant,
                ),
              const SizedBox(height: 12),
              Text(
                config.title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (!isConnected) ...[
                const SizedBox(height: 8),
                Text(
                  isError ? 'MQTT error' : 'Disconnected',
                  style: TextStyle(color: isError ? Colors.orange : Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                if (isError && lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      lastError,
                      style: const TextStyle(color: Colors.orange, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onButtonPressed(WidgetRef ref) {
    if (config.publishTopic == null || config.onPayload == null) return;

    final service = ref.read(mqttServiceProvider);
    service.publish(
      config.publishTopic!,
      config.onPayload!,
      qos: config.qos,
    );
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