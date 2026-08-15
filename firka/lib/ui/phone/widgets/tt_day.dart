import 'package:firka/core/extensions.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka_common/core/debug_helper.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'lesson.dart';

class TimeTableDayWidget extends StatelessWidget {
  final List<LessonCacheModel> lessons;
  final List<LessonCacheModel> events;
  final Future<void> Function()? onRefresh;

  const TimeTableDayWidget(
    this.lessons,
    this.events, {
    this.onRefresh,
    super.key,
  });

  static String simplifyEventName(String e) {
    return e
        .replaceAll(" (Nem órarendi nap)", "")
        .replaceAll(" (Hétfő)", "")
        .replaceAll(" (Kedd)", "")
        .replaceAll(" (Szerda)", "")
        .replaceAll(" (Csütörtök)", "")
        .replaceAll(" (Péntek)", "")
        .replaceAll(" (Szombat)", "")
        .replaceAll(" (Vasárnap)", "")
        .replaceAll(
          "Tanítás nélküli munkanap",
          initData.l10n.tt_non_instructional_day,
        )
        .replaceAll("Munkaszüneti nap", initData.l10n.tt_public_holiday)
        .replaceAll("Tavaszi szünet", initData.l10n.tt_spring_break)
        .replaceAll("Téli szünet", initData.l10n.tt_winter_break)
        .replaceAll("Őszi szünet", initData.l10n.tt_autumn_break)
        .replaceAll("Tanítási nap", initData.l10n.tt_instructional_day)
        .replaceAll("Első félév vége", initData.l10n.tt_first_semester_end)
        .replaceAll("Ünnepnap", initData.l10n.tt_holiday)
        .replaceAll("Pihenőnap", initData.l10n.tt_rest_day)
        .replaceAll(
          "Első tanítási nap",
          initData.l10n.tt_first_instructional_day,
        )
        .replaceAll(
          "Utolsó tanítási nap",
          initData.l10n.tt_last_instructional_day,
        )
        .replaceAll(
          "Utolsó tanítási nap a végzős évfolyamokon",
          initData.l10n.tt_last_instructional_day_graduates,
        )
        .replaceAll("Egész napos kirándulás", initData.l10n.tt_full_day_trip)
        .replaceAll("negyedév vége", initData.l10n.tt_quarter_end);
  }

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 70 + 16 + 20, left: 20, right: 20),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/images/logos/dave.svg",
                    width: 48,
                    height: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    initData.l10n.tt_no_classes_l1,
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                  Text(
                    initData.l10n.tt_no_classes_l2,
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                  if (events.isNotEmpty)
                    ...events.map(
                      (event) => Center(
                        child: Text(
                          simplifyEventName(event.name),
                          style: appStyle.fonts.B_16R.apply(
                            color: appStyle.colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> ttLessons = List.empty(growable: true);
    for (final event in events) {
      ttLessons.add(
        FirkaCard.single(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.all(16),
          child: Text(
            simplifyEventName(event.name),
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        ),
      );
    }

    if (events.isNotEmpty) {
      ttLessons.add(SizedBox());
    }

    var showBreak = Settings.ttToastBreaks.value;

    for (var i = 0; i < lessons.length; i++) {
      var lesson = lessons[i];
      var nextLesson = lessons.length > i + 1 ? lessons[i + 1] : null;
      ttLessons.add(
        LessonWidget(
          initData,
          lesson,
          active: timeNow().isBetween(
            i > 0 ? lessons[i - 1].end : lesson.start,
            lesson.end,
          ),
        ),
      );

      if (!showBreak || nextLesson == null) {
        continue;
      }

      var breakMins = nextLesson.start.difference(lesson.end).inMinutes;
      ttLessons.add(
        FirkaCard(
          color: appStyle.colors.cardTranslucent,
          margin: EdgeInsets.all(0),
          padding: EdgeInsets.symmetric(vertical: 11, horizontal: 16),
          shadow: false,
          left: [
            Text(
              initData.l10n.breakTxt,
              style: appStyle.fonts.B_14SB.copyWith(
                color: appStyle.colors.textSecondary,
              ),
            ),
          ],
          right: [
            Text(
              "$breakMins ${breakMins > 1 ? initData.l10n.starting_min_plural : initData.l10n.starting_min}",
              style: appStyle.fonts.B_14R.copyWith(
                color: appStyle.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 70 + 16 + 20, left: 20, right: 20),
      child: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (ttLessons.length == index) {
              return SizedBox(height: 55);
            }
            return ttLessons[index];
          },
          itemCount: ttLessons.length + 1,
        ),
      ),
    );
  }
}
