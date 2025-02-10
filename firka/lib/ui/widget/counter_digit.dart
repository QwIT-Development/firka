import 'package:firka/ui/model/style.dart';
import 'package:flutter/material.dart';

class CounterDigitWidget extends StatelessWidget {
  final String c;
  final TextStyle? style;

  const CounterDigitWidget(this.c, this.style, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.transparent,
      color: appStyle.colors.buttonSecondaryFill,
      child: Padding(
        padding: EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
        child: Text(
          c,
          style: style,
        ),
      ),
    );
  }
}
