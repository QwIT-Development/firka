import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:firka/core/bloc/theme_cubit.dart';
import 'package:firka/ui/theme/style.dart';

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
          offset: Offset(0, 2),
        ),
      ],
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );

    if (!shadow) {
      return ClipRRect(borderRadius: borderRadius, child: child);
    }

    final isLight = context.watch<ThemeCubit>().state.isLightMode;
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
