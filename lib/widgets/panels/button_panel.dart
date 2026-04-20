import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';
import '../../utils/icon_helper.dart';

class ButtonPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const ButtonPanel({super.key, required this.config});

  @override
  ConsumerState<ButtonPanel> createState() => _ButtonPanelState();
}

class _ButtonPanelState extends ConsumerState<ButtonPanel> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;
    final isError = connectionStatus.value == ConnectionStatus.error;
    final lastError = ref.read(mqttServiceProvider).lastError;
    final scheme = Theme.of(context).colorScheme;

    final icon = IconHelper.getIcon(widget.config.iconCodePoint);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minDimension = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        final iconSize = (minDimension * 0.25).clamp(24.0, 80.0);
        final iconPadding = (minDimension * 0.08).clamp(12.0, 32.0);
        final titleSize = (minDimension * 0.08).clamp(12.0, 24.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              // visual delay for better feel
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) setState(() => _isPressed = false);
              });

              if (!isConnected) {
                _showConnectionWarning(context, lastError);
                return;
              }
              _onButtonPressed(ref);
            },
            child: AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeInOut,
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
                          color:
                              (isConnected
                                      ? widget.config.color
                                      : scheme.outline)
                                  .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: _isPressed
                              ? [] // No shadow when pressed (simulates being pushed in)
                              : [
                                  BoxShadow(
                                    color:
                                        (isConnected
                                                ? widget.config.color
                                                : Colors.black)
                                            .withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Icon(
                          icon ?? Icons.touch_app,
                          size: iconSize,
                          color: isConnected
                              ? widget.config.color
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: minDimension * 0.05),
                      Text(
                        widget.config.title,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isError ? Colors.red : Colors.grey)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isError ? 'Error' : 'Offline',
                            style: TextStyle(
                              color: isError ? Colors.red : Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onButtonPressed(WidgetRef ref) {
    if (widget.config.publishTopic == null) return;

    final service = ref.read(mqttServiceProvider);
    String payload;

    if (widget.config.isJsonPayload && widget.config.jsonPattern != null) {
      payload = _processJsonPattern(
        widget.config.jsonPattern!,
        widget.config.onPayload ?? '1',
      );
    } else {
      payload = widget.config.onPayload ?? 'ON';
    }

    service.publish(
      widget.config.publishTopic!,
      payload,
      qos: widget.config.qos,
    );
  }

  String _processJsonPattern(String pattern, String value) {
    String result = pattern;
    result = result.replaceAll('<value>', value);
    result = result.replaceAll('<payload>', value);
    result = result.replaceAll('<button-payload>', value);
    result = result.replaceAll(
      '<timestamp>',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
    result = result.replaceAll(
      '<iso-timestamp>',
      DateTime.now().toIso8601String(),
    );
    return result;
  }

  void _showConnectionWarning(BuildContext context, String? lastError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lastError != null
              ? 'Tidak dapat publish: $lastError'
              : 'Koneksi MQTT belum tersambung',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
