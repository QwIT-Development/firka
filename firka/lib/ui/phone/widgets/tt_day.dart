import 'package:firka/core/settings.dart';
import 'package:firka_common/firka_common.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'lesson.dart';

class TimeTableDayWidget extends StatelessWidget {
  final AppInitialization data;
  final DateTime date;
  final List<Lesson> week;
  final List<Lesson> lessons;
  final List<Lesson> events;
  final List<Test> tests;
  final List<Lesson> day;

  const TimeTableDayWidget(
    this.data,
    this.date,
    this.week,
    this.lessons,
    this.events,
    this.tests,
    this.day, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget ttBody;

    if (lessons.isEmpty) {
      ttBody = Column(
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
            data.l10n.tt_no_classes_l1,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textSecondary,
            ),
          ),
          Text(
            data.l10n.tt_no_classes_l2,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textSecondary,
            ),
          ),
          if (events.isNotEmpty)
            ...events.map(
              (event) => Center(
                child: Text(
                  event.name
                  .replaceAll(" (Nem órarendi nap)", "")
                  .replaceAll(" (Hétfő)", "")
                  .replaceAll(" (Kedd)", "")
                  .replaceAll(" (Szerda)", "")
                  .replaceAll(" (Csütörtök)", "")
                  .replaceAll(" (Péntek)", "")
                  .replaceAll(" (Szombat)", "")
                  .replaceAll(" (Vasárnap)", "")
                  .replaceAll("Tanítás nélküli munkanap", data.l10n.tt_non_instructional_day)
                  .replaceAll("Munkaszüneti nap", data.l10n.tt_public_holiday)
                  .replaceAll("Tavaszi szünet", data.l10n.tt_spring_break)
                  .replaceAll("Téli szünet", data.l10n.tt_winter_break)
                  .replaceAll("Őszi szünet", data.l10n.tt_autumn_break)
                  .replaceAll("Tanítási nap", data.l10n.tt_instructional_day)
                  .replaceAll("Első félév vége", data.l10n.tt_first_semester_end)
                  .replaceAll("Ünnepnap", data.l10n.tt_holiday)
                  .replaceAll("Pihenőnap", data.l10n.tt_rest_day)
                  .replaceAll("Első tanítási nap", data.l10n.tt_first_instructional_day)
                  .replaceAll("Utolsó tanítási nap", data.l10n.tt_last_instructional_day)
                  .replaceAll("Utolsó tanítási nap a végzős évfolyamokon", data.l10n.tt_last_instructional_day_graduates)
                  .replaceAll("Egész napos kirándulás", data.l10n.tt_full_day_trip)
                  .replaceAll("negyedév vége", data.l10n.tt_quarter_end),
                  style: appStyle.fonts.B_16R.apply(
                    color: appStyle.colors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      List<Widget> ttLessons = List.empty(growable: true);
      for (var i = 0; i < events.length; i++) {
        var event = events[i];
        ttLessons.add(
          FirkaCard.single(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.all(16),
            child: Text(
              event.name,
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

      var showBreak = data.settings
          .group("settings")
          .subGroup("timetable_toast")
          .boolean("breaks");

      for (var i = 0; i < lessons.length; i++) {
        var lesson = lessons[i];
        var nextLesson = lessons.length > i + 1 ? lessons[i + 1] : null;
        ttLessons.add(
          LessonWidget(
            data,
            lesson,
            tests.firstWhereOrNull(
              (test) => test.lessonNumber == lesson.lessonNumber,
            ),
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

      ttBody = Padding(
        padding: const EdgeInsets.only(top: 70 + 16 + 20, left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [...ttLessons, SizedBox(height: 55)],
          ),
        ),
      );
    }

    return ttBody;
  }
}
