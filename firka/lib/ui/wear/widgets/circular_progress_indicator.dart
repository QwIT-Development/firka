import 'dart:math';

import 'package:flutter/material.dart';

class CircularProgressIndicatorWidget extends StatefulWidget {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Size screenSize;

  const CircularProgressIndicatorWidget({
    super.key,
    required this.progress,
    required this.screenSize,
    this.strokeWidth = 8.0,
    required this.color,
  });

  @override
  _CircularProgressIndicatorWidgetState createState() =>
      _CircularProgressIndicatorWidgetState();
}

class _CircularProgressIndicatorWidgetState
    extends State<CircularProgressIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation =
        Tween<double>(begin: 0.0, end: widget.progress).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: CircularProgressPainter(
            progress: _animation.value,
            strokeWidth: widget.strokeWidth,
            color: widget.color,
            screenSize: widget.screenSize,
          ),
          child: SizedBox.expand(), // Fill the entire screen
        );
      },
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Size screenSize;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(screenSize.width / 2, screenSize.height / 4.7);
    final radius =
        min(screenSize.width, screenSize.height) / 2 - strokeWidth / 2;
    final startAngle = -pi / 2;
    var sweepAngle = 2 * pi * progress;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (sweepAngle >= 6) {
      sweepAngle -= 0.6;
    } else {
      sweepAngle -= 0.35;

      if (sweepAngle > 5.4) sweepAngle = 5.4;
    }
    if (sweepAngle <= 0) sweepAngle = 0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + 0.3,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
