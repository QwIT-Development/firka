import 'package:flutter/material.dart';

class FirkaButton extends StatelessWidget {
  final String text;
  final Color bgColor;
  final TextStyle fontStyle;
  final Icon? icon;

  const FirkaButton(
      {required this.text,
      required this.bgColor,
      required this.fontStyle,
      this.icon,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    SizedBox(width: 8),
                    Text(text, style: fontStyle),
                  ],
                )
              : Text(text, style: fontStyle)),
    );
  }
}
