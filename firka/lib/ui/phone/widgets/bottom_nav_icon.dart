import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../model/style.dart';
import '../../widget/firka_icon.dart';

class BottomNavIconWidget extends StatelessWidget {
  final void Function() onTap;
  final bool active;
  final dynamic icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final bool isProfilePicture;

  const BottomNavIconWidget(this.onTap, this.active, this.icon, this.text,
      this.iconColor, this.textColor,
      {this.isProfilePicture = false, super.key});

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
              if (isProfilePicture && icon != null)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: MemoryImage(icon as Uint8List),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                FirkaIconWidget(FirkaIconType.majesticons, icon as Uint8List,
                      color: iconColor, size: 24)
                  .build(context),
              const SizedBox(height: 4),
              Text(
                text,
                style: active
                    ? appStyle.fonts.B_12SB
                        .apply(color: appStyle.colors.textPrimary)
                    : appStyle.fonts.B_12R
                        .apply(color: appStyle.colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
