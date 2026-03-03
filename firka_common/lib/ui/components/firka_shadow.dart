import 'package:flutter/material.dart';

import 'package:firka_common/ui/theme/style.dart';

class FirkaShadow extends StatelessWidget {
  final Widget child;
  final bool shadow;
  final double radius;
  final bool? isLightMode;

  const FirkaShadow({
    required this.shadow,
    required this.child,
    this.radius = 16.0,
    this.isLightMode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLight =
        isLightMode ?? Theme.of(context).brightness == Brightness.light;
    final borderRadius = BorderRadius.circular(radius);

    final shadowBox = BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.rectangle,
      boxShadow: [
        BoxShadow(
          color: appStyle.colors.shadowColor,
          spreadRadius: -4,
          blurRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
      borderRadius: BorderRadius.all(Radius.circular(radius)),
    );

    if (!shadow) {
      return ClipRRect(borderRadius: borderRadius, child: child);
    }

    if (isLight) {
      return child;
    } else {
      return Container(
        decoration: shadowBox,
        child: ClipRRect(borderRadius: borderRadius, child: child),
      );
    }
  }
}
