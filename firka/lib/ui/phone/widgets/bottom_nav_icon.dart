import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/firka_icon.dart';

class BottomNavIconWidget extends StatelessWidget {
  final void Function() onTap;
  final bool active;
  final dynamic icon;
  final String text;
  final bool isProfilePicture;

  const BottomNavIconWidget(
    this.onTap,
    this.active,
    this.icon,
    this.text, {
    this.isProfilePicture = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
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
              FirkaIconWidget(
                FirkaIconType.majesticons,
                icon as Uint8List,
                color: active
                    ? appStyle.colors.accent
                    : appStyle.colors.secondary.withAlpha(128),
                size: 24,
              ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: appStyle.fonts.B_14R.apply(
                  color: active
                      ? appStyle.colors.textPrimary
                      : appStyle.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
