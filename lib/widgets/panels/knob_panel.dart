import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class KnobPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const KnobPanel({super.key, required this.config});

  @override
  ConsumerState<KnobPanel> createState() => _KnobPanelState();
}

class _KnobPanelState extends ConsumerState<KnobPanel> {
  double _currentValue = 0;
  
  @override
  void initState() {
    super.initState();
    _currentValue = widget.config.minValue ?? 0;
  }

  void _updateValue(double angle) {
     // Convert angle (radians) to value
     // Angle 0 is top. We map -135deg to +135deg (total 270)
     // 0 radians usually right in Flutter.
     // Let's rely on standard drag logic. 
     // We will send MQTT on end.
  }

  void _publishValue() {
     if (widget.config.publishTopic != null) {
       ref.read(mqttServiceProvider).publish(
         widget.config.publishTopic!, 
         _currentValue.toStringAsFixed(1), // precision?
         retain: false 
       );
     }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
           Text(widget.config.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1),
           const Spacer(),
           _KnobWidget(
              min: widget.config.minValue ?? 0,
              max: widget.config.maxValue ?? 100,
              value: _currentValue,
              color: widget.config.color,
              onChanged: (val) {
                setState(() => _currentValue = val);
              },
              onChangeEnd: (val) {
                _publishValue();
              },
           ),
           const Spacer(),
           Text("${_currentValue.toStringAsFixed(1)} ${widget.config.unit ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      )
    );
  }
}

class _KnobWidget extends StatefulWidget {
  final double min;
  final double max;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _KnobWidget({
    required this.min, 
    required this.max, 
    required this.value, 
    required this.color,
    required this.onChanged,
    required this.onChangeEnd
  });

  @override
  State<_KnobWidget> createState() => _KnobWidgetState();
}

class _KnobWidgetState extends State<_KnobWidget> {
  
  void _handlePan(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    // atan2(y, x) returns angle from -pi to pi.
    // 0 is right (3 o'clock).
    // We want 0-value at roughly 7 o'clock (+135 deg) to 5 o'clock (+45 deg next cycle?)
    // This is tricky. Let's simplify: simple angle tracking.
    
    double angle = math.atan2(dy, dx); 
    // angle is -pi to pi.
    // Shift so bottom (-pi/2) is start?
    
    // Easier approach: Use a rotary slider logic.
    // But for MVP, let's just assume simple vertical drag changes value? 
    // No, user asked for knob.
    
    // Convert to 0..2pi
    if (angle < 0) angle += 2 * math.pi;
    
    // We want 135 deg to 405 deg (270deg range)
    // 135 deg = 2.35 rad (approx). 
    // Start at 3/4 pi (135 deg specific, bottom-left) -> 2.356
    // End at 1/4 pi (45 deg, bottom-right) -> 0.785 (wrapped)
    
    // Let's implement visual map relative to "Up" (-pi/2).
    // ...
    // Fallback: Vertical drag controls value, knob rotates visually. Much easier.
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
         // Sensitivity
         double delta = -details.primaryDelta! / 200; // Up increases
         double range = widget.max - widget.min;
         double newValue = (widget.value + delta * range).clamp(widget.min, widget.max);
         widget.onChanged(newValue);
      },
      onVerticalDragEnd: (_) => widget.onChangeEnd(widget.value),
      child: CustomPaint(
        size: const Size(120, 120),
        painter: _KnobPainter(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          color: widget.color,
          context: context,
        ),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;
  final BuildContext context;

  _KnobPainter({required this.value, required this.min, required this.max, required this.color, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = math.min(size.width/2, size.height/2) - 5;
    
    final paint = Paint()
      ..color = Theme.of(context).colorScheme.surfaceContainerHighest
      ..style = PaintingStyle.fill;
      
    // Draw background circle
    canvas.drawCircle(center, radius, paint);
    
    // Draw indicator line/dot
    // Map value to angle.
    // -135deg (left-bottom) to +135deg (right-bottom)
    // range 270 deg = 4.71 rad.
    // start -3/4 pi = -2.356 rad (from vertical up? No, usually 0 is right).
    
    // 0 = Right.
    // Start = 135deg (down-left) = 3/4 pi = 2.356 rad.
    // End = 405deg (down-right) = 7/4 pi = 5.49 rad? Or 45 deg = 0.785 rad.
    
    // Let's use 0 is UP (-pi/2).
    // Start = -135 deg = -2.356 rad.
    // End = 135 deg = 2.356 rad.
    // Total range 270.
    
    double percent = (value - min) / (max - min);
    double startAngle = -math.pi * 0.75; // -135 from vertical up? 
    // Normal circle: 0 is Right, -pi/2 is Top.
    // We want Start at -225 deg (from 0? no)
    // Let's just do math.pi * 0.75 (135) to math.pi * 2.25 (405)
    
    double totalAngle = math.pi * 1.5; // 270deg
    double angle = (math.pi * 0.75) + (percent * totalAngle); // Start at 135 deg (bottom left)
    
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
      
    // Draw Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius), 
      math.pi * 0.75, 
      percent * totalAngle, 
      false, 
      markerPaint
    );
    
    // Draw Knob Cap
    final capRadius = radius * 0.8;
    // Shadow
    canvas.drawCircle(center, capRadius, Paint()..color = Colors.black12..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    // Knob body
    canvas.drawCircle(center, capRadius, Paint()..color = Theme.of(context).cardColor);
    
    // Dot
    final dotDist = capRadius * 0.7;
    final dx = center.dx + dotDist * math.cos(angle);
    final dy = center.dy + dotDist * math.sin(angle);
    
    canvas.drawCircle(Offset(dx, dy), 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter old) => old.value != value;
}
