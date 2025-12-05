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

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isConnected ? () => _onButtonPressed(ref) : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (config.iconCodePoint != null && IconHelper.getIcon(config.iconCodePoint) != null)
                Icon(
                  IconHelper.getIcon(config.iconCodePoint)!,
                  size: 48,
                  color: isConnected ? config.color : Colors.grey,
                ),
              const SizedBox(height: 12),
              Text(
                config.title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (!isConnected) ...[
                const SizedBox(height: 8),
                const Text(
                  'Disconnected',
                  style: TextStyle(color: Colors.red, fontSize: 12),
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
}