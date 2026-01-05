import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class LiquidTankPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const LiquidTankPanel({super.key, required this.config});

  @override
  ConsumerState<LiquidTankPanel> createState() => _LiquidTankPanelState();
}

class _LiquidTankPanelState extends ConsumerState<LiquidTankPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentValue = 0;
  String? _error;
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>>
  _messageSub;

  @override
  void initState() {
    super.initState();
    // Faster animation for more dynamic feel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _subscribeToTopic();
    _messageSub = ref.listenManual<AsyncValue<app_mqtt.MqttMessageData>>(
      mqttMessagesProvider,
      (_, next) {
        next.whenData((message) {
          if (message.topic == widget.config.subscribeTopic) {
            _updateValue(message.payload);
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

  void _updateValue(String payload) {
    try {
      final val = double.parse(payload);
      setState(() {
        _currentValue = val.clamp(
          widget.config.minValue ?? 0,
          widget.config.maxValue ?? 100,
        );
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid';
      });
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
    // Calculate target percentage
    final targetPercent =
        (_currentValue - (widget.config.minValue ?? 0)) /
        ((widget.config.maxValue ?? 100) - (widget.config.minValue ?? 0));
    final clampedTarget = targetPercent.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            widget.config.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tank visuals
                AspectRatio(
                  aspectRatio: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(50), // Capsule shape
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surfaceContainerHighest
                              .withOpacity(0.1),
                          Theme.of(context).colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                        ],
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Glass reflection effect
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            width: 10,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        // Water with Smooth Transition
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: clampedTarget),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves
                              .elasticOut, // Physics effect (bouncy water)
                          builder: (context, animatedPercent, child) {
                            return AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return ClipPath(
                                  clipper: WaveClipper(
                                    _controller.value,
                                    animatedPercent,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          widget.config.color.withOpacity(0.7),
                                          widget.config.color,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        // Levels Lines
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            4,
                            (index) => Container(
                              height: 1,
                              color: Colors.black12,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated Counting Text
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: _currentValue),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      if (widget.config.unit != null)
                        Text(
                          widget.config.unit!,
                          style: TextStyle(color: Theme.of(context).hintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animationValue;
  final double percentage;

  WaveClipper(this.animationValue, this.percentage);

  @override
  Path getClip(Size size) {
    if (percentage == 0) return Path();

    final path = Path();
    final height = size.height * percentage;
    final baseHeight = size.height - height;

    path.moveTo(0, baseHeight);

    // Improved double wave for more realism
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        baseHeight +
            math.sin(
                  (i / size.width * 2 * math.pi) +
                      (animationValue * 2 * math.pi),
                ) *
                5 + // Main wave
            math.sin(
                  (i / size.width * 4 * math.pi) +
                      (animationValue * 2 * math.pi),
                ) *
                2, // Secondary ripple
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => true;
}
