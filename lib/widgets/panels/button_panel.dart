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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        final minDimension = constraints.maxWidth < constraints.maxHeight 
            ? constraints.maxWidth 
            : constraints.maxHeight;
        
        // Icon size scales with widget size (30% of min dimension, clamped)
        final iconSize = (minDimension * 0.25).clamp(24.0, 80.0);
        // Icon container padding scales too
        final iconPadding = (minDimension * 0.08).clamp(12.0, 32.0);
        // Title font size scales
        final titleSize = (minDimension * 0.08).clamp(12.0, 24.0);
        
        return Material(
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
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(minDimension * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        color: (isConnected ? config.color : scheme.outline).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon ?? Icons.touch_app,
                        size: iconSize,
                        color: isConnected ? config.color : scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: minDimension * 0.05),
                    Text(
                      config.title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isConnected) ...[
                      SizedBox(height: minDimension * 0.03),
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
      },
    );
  }

  void _onButtonPressed(WidgetRef ref) {
    if (config.publishTopic == null) return;

    final service = ref.read(mqttServiceProvider);
    String payload;

    if (config.isJsonPayload && config.jsonPattern != null) {
      // Use JSON Pattern and replace variables
      payload = _processJsonPattern(config.jsonPattern!, config.onPayload ?? '1');
    } else {
      // Use plain payload
      payload = config.onPayload ?? 'ON';
    }

    service.publish(
      config.publishTopic!,
      payload,
      qos: config.qos,
    );
  }

  String _processJsonPattern(String pattern, String value) {
    // Replace common variables in JSON pattern
    String result = pattern;
    result = result.replaceAll('<value>', value);
    result = result.replaceAll('<payload>', value);
    result = result.replaceAll('<button-payload>', value);
    result = result.replaceAll('<timestamp>', DateTime.now().millisecondsSinceEpoch.toString());
    result = result.replaceAll('<iso-timestamp>', DateTime.now().toIso8601String());
    // Add more variables as needed
    return result;
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