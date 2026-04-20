import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../providers/mqtt_providers.dart';

class JoystickPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const JoystickPanel({super.key, required this.config});

  @override
  ConsumerState<JoystickPanel> createState() => _JoystickPanelState();
}

class _JoystickPanelState extends ConsumerState<JoystickPanel> {
  Offset _stickPosition = Offset.zero;
  final double _radius = 60.0; // Max distance
  
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Center is (width/2, height/2) which we'll handle in layout via FractionalTranslation or similar.
      // But standard way: keep stick pos relative to center (0,0)
      
      // We assume Gesture Detector is centered on the joystick base
      // delta comes in.
      
      Offset newPos = _stickPosition + details.delta;
      double distance = newPos.distance;
      
      if (distance > _radius) {
        newPos = Offset(
          (newPos.dx / distance) * _radius,
          (newPos.dy / distance) * _radius,
        );
      }
      _stickPosition = newPos;
    });
    
    _publish();
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _stickPosition = Offset.zero;
    });
    _publish();
  }
  
  void _publish() {
    if (widget.config.publishTopic == null) return;

    final service = ref.read(mqttServiceProvider);
    // Normalize to -1.0 to 1.0
    double x = (_stickPosition.dx / _radius);
    double y = -(_stickPosition.dy / _radius);

    String payload;
    if (widget.config.isJsonPayload && widget.config.jsonPattern != null) {
      // Use JSON Pattern
      String result = widget.config.jsonPattern!;
      result = result.replaceAll('<x>', x.toStringAsFixed(2));
      result = result.replaceAll('<y>', y.toStringAsFixed(2));
      result = result.replaceAll('<timestamp>', DateTime.now().millisecondsSinceEpoch.toString());
      result = result.replaceAll('<iso-timestamp>', DateTime.now().toIso8601String());
      payload = result;
    } else {
      // Default JSON format
      payload = '{"x": ${x.toStringAsFixed(2)}, "y": ${y.toStringAsFixed(2)}}';
    }

    service.publish(
      widget.config.publishTopic!,
      payload,
      retain: false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(widget.config.title, style: Theme.of(context).textTheme.titleSmall),
          Expanded(
            child: Center(
              child: Container(
                width: _radius * 2.5,
                height: _radius * 2.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Base crosshair
                      Divider(color: Theme.of(context).dividerColor),
                      VerticalDivider(color: Theme.of(context).dividerColor),
                      // Stick
                      Transform.translate(
                        offset: _stickPosition,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.config.color,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                            gradient: RadialGradient(
                              colors: [
                                widget.config.color.withValues(alpha: 0.8),
                                widget.config.color,
                              ],
                              center: const Alignment(-0.2, -0.2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
