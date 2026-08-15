import 'package:flutter/material.dart';

import 'package:firka_common/ui/theme/style.dart';

class CounterDigitWidget extends StatelessWidget {
  final String c;

  const CounterDigitWidget(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: appStyle.colors.buttonSecondaryFill,
      ),
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(
        c,
        textAlign: TextAlign.center,
        style: appStyle.fonts.H_16px.apply(color: appStyle.colors.textPrimary),
      ),
    );
  }
}
