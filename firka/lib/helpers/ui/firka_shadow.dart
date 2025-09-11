import 'package:firka/main.dart';
import 'package:flutter/material.dart';

import '../../ui/model/style.dart';

class FirkaShadow extends StatelessWidget {
  final Widget child;
  final bool shadow;

  const FirkaShadow({required this.shadow, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8.0);

    final shadowBox = BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.rectangle,
        boxShadow: [
          BoxShadow(
              color: appStyle.colors.shadowColor,
              spreadRadius: -4,
              blurRadius: 0,
              offset: Offset(0, 2))
        ],
        borderRadius: BorderRadius.all(Radius.circular(16)));

    if (!shadow) {
      return ClipRRect(borderRadius: borderRadius, child: child);
    }

    if (isLightMode.value) {
      return child;
    } else {
      return Container(
        decoration: shadowBox,
        child: ClipRRect(borderRadius: borderRadius, child: child),
      );
    }
  }
}
