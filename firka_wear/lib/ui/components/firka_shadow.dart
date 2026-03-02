import 'package:flutter/material.dart';

import 'package:firka_wear/ui/theme/style.dart';

class FirkaShadow extends StatelessWidget {
  final Widget child;
  final bool shadow;
  final double radius;

  const FirkaShadow({
    required this.shadow,
    required this.child,
    this.radius = 16.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    final shadowBox = BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.rectangle,
      boxShadow: [
        BoxShadow(
          color: wearStyle.colors.shadowColor,
          spreadRadius: -4,
          blurRadius: 0,
          offset: Offset(0, 2),
        ),
      ],
      borderRadius: borderRadius,
    );

    if (!shadow) {
      return ClipRRect(borderRadius: borderRadius, child: child);
    }

    return Container(
      decoration: shadowBox,
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}
