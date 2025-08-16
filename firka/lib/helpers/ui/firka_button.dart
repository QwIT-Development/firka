import 'package:flutter/material.dart';

class FirkaButton extends StatelessWidget {
  final String text;
  final Color bgColor;
  final TextStyle fontStyle;

  const FirkaButton(
      {required this.text,
      required this.bgColor,
      required this.fontStyle,
      super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Add shadows
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(text, style: fontStyle)),
    );
  }
}
