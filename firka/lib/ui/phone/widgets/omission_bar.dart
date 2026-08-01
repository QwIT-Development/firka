import 'package:firka/app/app_state.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka_common/core/debug_helper.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka_common/ui/components/grade.dart';
import 'package:firka_common/core/grade_helper.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/theme/style.dart';

class OmissionBar extends StatelessWidget {
  const OmissionBar({super.key});

  static Color stateToColor(OmissionCacheModel? o) {
    if (o == null) {
      return appStyle.colors.a15p;
    }
    switch (o.state) {
      case OmissionState.excused:
        return appStyle.colors.accent;
      case OmissionState.unexcused:
        return appStyle.colors.errorAccent;
      default:
        return appStyle.colors.warningAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = timeNow();
    DateTime startOfTheYear = now.getFirstSchoolDay();

    final dates = initData.client!.cache
        .getTimeTable()
        .between(startOfTheYear, now)
        .findAllSync()
        .map((l) => l.start.getMidnight())
        .toSet();

    final omittedDates = initData.client!.cache
        .getOmissions()
        .findAllSync()
        .groupList((o) => o.lesson.loadAndGet()!.start);

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: dates
            .map(
              (i) => Expanded(
                child: Container(
                  height: 12,
                  color: stateToColor(omittedDates[i]?.firstOrNull),
                ),
              ),
            )
            .toList(),
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
