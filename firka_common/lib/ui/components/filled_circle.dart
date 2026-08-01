import 'package:flutter/material.dart';

class FilledCircle extends StatelessWidget {
  final double diameter;
  final Color color;
  final Widget child;

  const FilledCircle({
    required this.diameter,
    required this.child,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Material(
        shape: const CircleBorder(),
        color: color,
        child: Center(child: child),
      ),
    );
  }
}
