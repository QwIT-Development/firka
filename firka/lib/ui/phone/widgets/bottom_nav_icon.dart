import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../model/style.dart';
import '../../widget/firka_icon.dart';

class BottomNavIconWidget extends StatelessWidget {
  final void Function() onTap;
  final bool active;
  final Uint8List icon;
  final String text;
  final Color iconColor;
  final Color textColor;

  const BottomNavIconWidget(this.onTap, this.active, this.icon, this.text,
      this.iconColor, this.textColor,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FirkaIconWidget(FirkaIconType.Majesticons, icon,
                      color: iconColor, size: 24)
                  .build(context),
              const SizedBox(height: 4),
              Text(
                text,
                style: active ? appStyle.fonts.B_12SB : appStyle.fonts.B_12R,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
