import 'package:flutter/material.dart';
import 'package:kreta_api/kreta_api.dart';

import 'package:firka_common/ui/components/grade_helpers.dart';
import 'package:firka_common/ui/theme/style.dart';

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
    return Container(
      width: diameter,
      height: diameter,
      decoration: ShapeDecoration(
        color: color,
        shape: CircleBorder(eccentricity: 1),
      ),
      child: Center(child: child),
    );
  }
}
