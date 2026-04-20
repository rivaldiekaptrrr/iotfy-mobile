import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class StatusPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const StatusPanel({super.key, required this.config});

  @override
  ConsumerState<StatusPanel> createState() => _StatusPanelState();
}

class _StatusPanelState extends ConsumerState<StatusPanel>
    with SingleTickerProviderStateMixin {
  String? _lastPayload;
  DateTime? _lastUpdated;
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>>
  _messageSub;
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 2.0,
      end: 15.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _subscribeToTopic();
    _messageSub = ref.listenManual<AsyncValue<app_mqtt.MqttMessageData>>(
      mqttMessagesProvider,
      (_, next) {
        next.whenData((message) {
          if (message.topic == widget.config.subscribeTopic) {
            setState(() {
              _lastPayload = message.payload;
              _lastUpdated = DateTime.now();
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
    _controller.dispose();
    _messageSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;

    // Determine status
    bool isActive = false;
    bool isOff = false;

    if (_lastPayload != null) {
      if (_lastPayload == widget.config.onPayload) {
        isActive = true;
      } else if (_lastPayload == widget.config.offPayload) {
        isOff = true;
      }
    }

    final activeColor = widget.config.color;
    final warningColor = Colors.orange;

    Color stateColor;
    String stateText;
    IconData stateIcon;

    if (!isConnected) {
      stateColor = Colors.grey.withValues(alpha: 0.5);
      stateText = 'Offline';
      stateIcon = Icons.wifi_off;
    } else if (_lastPayload == null) {
      stateColor = Colors.grey.withValues(alpha: 0.3);
      stateText = 'Waiting...';
      stateIcon = Icons.hourglass_empty;
    } else if (isActive) {
      stateColor = activeColor;
      stateText = _lastPayload!;
      stateIcon = Icons.check_circle;
    } else if (isOff) {
      stateColor = Colors.grey;
      stateText = _lastPayload!;
      stateIcon = Icons.power_settings_new;
    } else {
      stateColor = warningColor;
      stateText = _lastPayload!;
      stateIcon = Icons.warning_amber_rounded;
    }

    // Override icon if user selected one
    if (widget.config.icon != null) {
      stateIcon = widget.config.icon!;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.config.title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: AnimatedBuilder(
              key: ValueKey(
                stateText + stateColor.toString(),
              ), // Rebuild when state changes
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stateColor.withValues(alpha: 0.2),
                    border: Border.all(color: stateColor, width: 4),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: stateColor.withValues(alpha: 0.6),
                              blurRadius:
                                  _glowAnimation.value, // Breathing glow
                              spreadRadius: _glowAnimation.value / 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(stateIcon, size: 40, color: stateColor),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              stateText,
              key: ValueKey(stateText),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: stateColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          if (_lastUpdated != null)
            Text(
              'Updated: ${_lastUpdated!.toLocal().toString().split('.')[0].split(' ')[1]}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}
