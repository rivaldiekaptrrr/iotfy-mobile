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

    final icon = IconHelper.getIcon(config.iconCodePoint);
    
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 140),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isConnected ? config.color : scheme.outline).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Icons.touch_app,
                    size: 36,
                    color: isConnected ? config.color : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  config.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isConnected) ...[
                  const SizedBox(height: 8),
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
              ],
            ),
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