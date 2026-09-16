import 'dart:math' as math;

import 'package:core_flutter/common/color_opacity.dart';
import 'package:flutter/material.dart';

class WidgetWait extends StatefulWidget {
  final Color? color;
  final double? strokeWidth, size;
  final double? value;
  const WidgetWait({super.key, this.color, this.strokeWidth, this.size, this.value});

  @override
  State<WidgetWait> createState() => _WidgetWaitState();
}

class _WidgetWaitState extends State<WidgetWait> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null) {
      return CustomPaint(
        size: Size(widget.size ?? 25, widget.size ?? 25),
        painter: CircularSegmentPainter(
            color: widget.color ?? ProgressIndicatorTheme.of(context).color ?? Theme.of(context).colorScheme.primary,
            strokeWidth: widget.strokeWidth ?? 3,
            value: widget.value,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2.0 * math.pi,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size ?? 25, widget.size ?? 25),
        painter: CircularSegmentPainter(
            color: widget.color ?? ProgressIndicatorTheme.of(context).color ?? Theme.of(context).colorScheme.primary,
            strokeWidth: widget.strokeWidth ?? 3
        ),
      ),
    );
  }
}

class CircularSegmentPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double? value;
  CircularSegmentPainter({ required this.strokeWidth, required this.color, this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final double effectiveStrokeWidth = strokeWidth;
    final double side = math.min(size.width, size.height);
    final Rect rect = Offset(
          (size.width - side) / 2 + effectiveStrokeWidth / 2,
          (size.height - side) / 2 + effectiveStrokeWidth / 2
        ) &
        Size(side - effectiveStrokeWidth, side - effectiveStrokeWidth);

    final Paint backgroundPaint = Paint()
      ..color = color.op2
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, backgroundPaint);

    final Paint foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveStrokeWidth
      ..strokeCap = StrokeCap.round;

    const double startAngle = -90 * math.pi / 180;
    
    final double sweepAngle = value != null 
        ? (value!.clamp(0.0, 1.0)) * 360 * math.pi / 180
        : 100 * math.pi / 180;

    canvas.drawArc(rect, startAngle, sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(CircularSegmentPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.value != value;
  }
}