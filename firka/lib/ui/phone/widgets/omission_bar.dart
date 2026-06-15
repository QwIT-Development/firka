import 'package:firka/app/app_state.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:intl/intl.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/ui/components/grade.dart';
import 'package:firka/ui/components/grade_helpers.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/theme/style.dart';

class OmissionBar extends StatelessWidget {
  final List<Omission> omissions;

  const OmissionBar({super.key, required this.omissions});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime start = now.copyWith(month: 9, day: 1);
    DateTime startOfTheYear = now.isBefore(start)
        ? start.subtract(Duration(days: 365))
        : start;

    Map<int, Color> dayToColor = omissions.fold(
      Map.identity(),
      (map, o) => map
        ..putIfAbsent(
          o.date.difference(startOfTheYear).inDays,
          () => o.state == OmissionState.excused
              ? appStyle.colors.accent
              : o.state == OmissionState.unexcused
              ? appStyle.colors.errorAccent
              : appStyle.colors.warningAccent,
        ),
    );

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: List.generate(now.difference(startOfTheYear).inDays, (i) {
          return Expanded(
            child: Container(
              height: 12,
              color: dayToColor[i] ?? appStyle.colors.a15p,
            ),
          );
        }),
      ),
    );

    return FirkaCard.single(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          bar,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat.MMMM(
                  initData.l10n.localeName,
                ).format(startOfTheYear).firstUpper(),
                style: appStyle.fonts.B_14R.copyWith(
                  color: appStyle.colors.textSecondary,
                ),
              ),
              Text(
                initData.l10n.now,
                style: appStyle.fonts.B_14R.copyWith(
                  color: appStyle.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
