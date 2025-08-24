import 'package:firka/helpers/extensions.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../model/style.dart';

class BottomTimeTableNavIconWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final void Function() onTap;
  final bool active;
  final DateTime date;

  const BottomTimeTableNavIconWidget(
      this.l10n, this.onTap, this.active, this.date,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onTap();
      },
      child: Card(
        color:
            active ? appStyle.colors.buttonSecondaryFill : Colors.transparent,
        shadowColor: Colors.transparent,
        child: SizedBox(
            width: 40,
            height: 54,
            child: Column(
              children: [
                SizedBox(height: 6),
                Text(date.format(l10n, FormatMode.da),
                    style: appStyle.fonts.H_16px
                        .apply(color: appStyle.colors.textPrimary)),
                Text(
                  date.format(l10n, FormatMode.dd),
                  style: appStyle.fonts.B_14R
                      .apply(color: appStyle.colors.textSecondary),
                )
              ],
            )),
      ),
    );
  }
}
