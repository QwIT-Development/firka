import 'package:firka/core/extensions.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:flutter/material.dart';

import 'package:firka/ui/theme/style.dart';

class BottomTimeTableNavIconWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final void Function() onTap;
  final bool active;
  final DateTime? date;

  const BottomTimeTableNavIconWidget(
    this.l10n,
    this.onTap,
    this.active,
    this.date, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onTap();
      },
      child: Container(
        width: 40,
        height: 54,
        decoration: ShapeDecoration(
          shadows: active
              ? [
                  BoxShadow(
                    color: appStyle.colors.shadowColor,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: active
              ? appStyle.colors.buttonSecondaryFill
              : Colors.transparent,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: date != null
                ? [
                    Text(
                      date!.format(l10n, FormatMode.da),
                      style: appStyle.fonts.H_16px.apply(
                        color: active
                            ? appStyle.colors.textPrimary
                            : appStyle.colors.textTeritary,
                      ),
                    ),
                    Text(
                      date!.format(l10n, FormatMode.dd),
                      style: appStyle.fonts.B_16R.apply(
                        color: active
                            ? appStyle.colors.textSecondary
                            : appStyle.colors.textTeritary,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}
