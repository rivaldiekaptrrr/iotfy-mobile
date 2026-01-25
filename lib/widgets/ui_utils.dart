import 'package:flutter/material.dart';

class DataLoadingShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const DataLoadingShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<DataLoadingShimmer> createState() => _DataLoadingShimmerState();
}

class _DataLoadingShimmerState extends State<DataLoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _controller.value, 0.0),
              end: Alignment(1.0 + _controller.value, 0.0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class ValueTransition extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final Widget? prefix;
  final Widget? suffix;

  const ValueTransition({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (prefix != null) prefix!,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
             return FadeTransition(
               opacity: animation,
               child: SizeTransition(
                 sizeFactor: animation,
                 axis: Axis.horizontal,
                 axisAlignment: -1.0,
                 child: child,
               ),
             );
          },
          child: Text(
            value,
            key: ValueKey<String>(value),
            style: style,
          ),
        ),
        if (suffix != null) suffix!,
      ],
    );
  }
}
