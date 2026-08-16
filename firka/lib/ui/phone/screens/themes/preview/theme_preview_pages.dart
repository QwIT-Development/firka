import "dart:collection";

import "package:firka/app/app_state.dart";
import "package:firka/core/extensions.dart";
import "package:firka/ui/phone/screens/themes/preview/theme_page_preview.dart";
import "package:firka/ui/phone/screens/themes/preview/theme_preview_data.dart";
import "package:firka/ui/phone/widgets/bottom_tt_icon.dart";
import "package:firka/ui/phone/widgets/grade_chart.dart";
import "package:firka/ui/phone/widgets/grade_summary_bar.dart";
import "package:firka/ui/phone/widgets/home_main_welcome.dart";
import "package:firka/ui/phone/widgets/info_card.dart";
import "package:firka/ui/phone/widgets/lesson_slider.dart";
import "package:firka/ui/phone/widgets/omission_bar.dart";
import "package:firka/ui/phone/widgets/tt_day.dart";
import "package:firka/ui/shared/class_icon.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/shared/grade_small_card.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/core/grade_helper.dart";
import "package:firka_common/data/models/omission_cache_model.dart";
import "package:firka_common/data/models/subject_cache_model.dart";
import "package:firka_common/ui/components/filled_circle.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:flutter/material.dart";
import "package:kreta_api/kreta_api.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

List<Widget> buildThemePreviewCarouselItems({
  required AppInitialization data,
  required ThemePreviewData preview,
}) {
  return [
    ThemePagePreview(
      data: data,
      activeTab: ThemePreviewNavTab.home,
      body: ThemePreviewHomeMain(data: data, preview: preview),
    ),
    ThemePagePreview(
      data: data,
      activeTab: ThemePreviewNavTab.grades,
      body: ThemePreviewHomeGrades(data: data, preview: preview),
    ),
    ThemePagePreview(
      data: data,
      activeTab: ThemePreviewNavTab.timetable,
      body: ThemePreviewHomeTimetable(data: data, preview: preview),
    ),
    ThemePagePreview(
      data: data,
      activeTab: ThemePreviewNavTab.timetable,
      body: ThemePreviewHomeTimetableMonthly(data: data, preview: preview),
    ),
    ThemePagePreview(
      data: data,
      activeTab: ThemePreviewNavTab.omissions,
      body: ThemePreviewHomeOmissions(data: data, preview: preview),
    ),
    ThemePagePreview(
      data: data,
      activeTab: ThemePreviewNavTab.grades,
      body: ThemePreviewHomeGradesSubject(data: data, preview: preview),
    ),
  ];
}

class ThemePreviewHomeMain extends StatelessWidget {
  final AppInitialization data;
  final ThemePreviewData preview;

  const ThemePreviewHomeMain({
    super.key,
    required this.data,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final noticeBoardWidgets = <(Widget, DateTime)>[];
    for (final item in preview.messages) {
      noticeBoardWidgets.add((InfoCard.messageItem(item), item.createdAt));
    }
    for (final test in preview.tests) {
      noticeBoardWidgets.add((InfoCard.test(test), test.createdAt));
    }
    noticeBoardWidgets.sort(
      (a, b) => b.$2.difference(a.$2).inMilliseconds,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          WelcomeWidget(
            data.l10n,
            preview.now,
            preview.student,
            preview.homeLessons,
          ),
          const SizedBox(height: 48),
          LessonSlider(preview.homeLessons, 0),
          const SizedBox(height: 24),
          ...noticeBoardWidgets
              .groupList((e) => e.$2)
              .entries
              .map(
                (e) => Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key.format(data.l10n, FormatMode.main),
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textSecondary,
                      ),
                    ),
                    ...e.value.map((v) => v.$1),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class ThemePreviewHomeGrades extends StatelessWidget {
  final AppInitialization data;
  final ThemePreviewData preview;

  const ThemePreviewHomeGrades({
    super.key,
    required this.data,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final allGrades = preview.grades;
    final subjectAverage = allGrades.getSubjectAverage();
    final roundedSubjectAverage = allGrades.getRoundedSubjectAverage();

    final gradeCards = <Widget>[];
    for (final subject
        in preview.subjects.toList()
          ..sort((a, b) => a.name.compareTo(b.name))) {
      gradeCards.add(
        GradeSmallCard(
          allGrades.getAverageBySubject(subject),
          null,
          subject,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headingText(data.l10n.subjects),
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          GradeChart(grades: allGrades),
          const SizedBox(height: 10),
          GradeSummaryBar(grades: allGrades, l10n: data.l10n),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Text(
                  data.l10n.your_subjects,
                  style: appStyle.fonts.H_14px.apply(
                    color: appStyle.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  spacing: 16,
                  mainAxisSize: MainAxisSize.min,
                  children: gradeCards,
                ),
                const SizedBox(height: 16),
                Text(
                  data.l10n.data,
                  style: appStyle.fonts.B_16SB.apply(
                    color: appStyle.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                FirkaCard(
                  left: [
                    Text(
                      data.l10n.subject_avg,
                      style: appStyle.fonts.B_16SB.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                  right: [
                    if (subjectAverage != null)
                      _avgPill(subjectAverage, filled: true),
                  ],
                ),
                FirkaCard(
                  left: [
                    Text(
                      data.l10n.subject_avg_rounded,
                      style: appStyle.fonts.B_16SB.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                  right: [
                    if (roundedSubjectAverage != null)
                      _avgPill(roundedSubjectAverage, filled: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avgPill(double value, {required bool filled}) {
    return Container(
      width: 48,
      height: 26,
      decoration: ShapeDecoration(
        color: filled ? getGradeColor(value).withAlpha(38) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Center(
        child: Text(
          value.toStringAsFixed(2),
          style: appStyle.fonts.B_16R.apply(color: getGradeColor(value)),
        ),
      ),
    );
  }
}

class ThemePreviewHomeTimetable extends StatelessWidget {
  final AppInitialization data;
  final ThemePreviewData preview;

  const ThemePreviewHomeTimetable({
    super.key,
    required this.data,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final day = DateTime(
      preview.now.year,
      preview.now.month,
      preview.now.day,
    );
    final monday = day.getMonday();
    final tabDays = [
      for (var i = 0; i < 5; i++) monday.add(Duration(days: i)),
    ];

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TimeTableDayWidget(preview.timetableLessons, const []),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Center(
                child: Wrap(
                  spacing: 16,
                  children: [
                    for (final d in tabDays)
                      BottomTimeTableNavIconWidget(
                        data.l10n,
                        () {},
                        d.isAtSameMomentAs(day),
                        d,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 74 + 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      headingText(data.l10n.timetable),
                      style: appStyle.fonts.H_H2.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.tableSolid,
                          size: 20,
                          color: appStyle.colors.accent,
                        ),
                        FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.settingsCogSolid,
                          size: 20,
                          color: appStyle.colors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FirkaIconWidget(
                      FirkaIconType.icons,
                      "dropdownLeft",
                      size: 24,
                      color: appStyle.colors.accent,
                    ),
                    Text(
                      monday.format(data.l10n, FormatMode.yyyymmddwedd),
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    FirkaIconWidget(
                      FirkaIconType.icons,
                      "dropdownRight",
                      size: 24,
                      color: appStyle.colors.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ThemePreviewHomeTimetableMonthly extends StatelessWidget {
  final AppInitialization data;
  final ThemePreviewData preview;

  const ThemePreviewHomeTimetableMonthly({
    super.key,
    required this.data,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final now = preview.now;
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
    final gridStart = currentMonthStart
        .subtract(Duration(days: currentMonthStart.weekday - 1))
        .subtract(const Duration(days: 7));

    final ttDays = <Widget>[];
    var lessonCountMonth = 0;
    var testCountMonth = 0;
    var omissionCountMonth = 0;

    for (var i = 0; i < 49; i++) {
      final d = DateTime(
        gridStart.year,
        gridStart.month,
        gridStart.day + i,
      );
      final key = DateTime(d.year, d.month, d.day);
      final meta = preview.monthDayMeta[key] ??
          const ThemePreviewMonthDay(lessonCount: 0, hasTest: false);
      final outOfRange =
          d.isBefore(currentMonthStart) || d.isAfter(currentMonthEnd);
      final isToday = !outOfRange &&
          now.year == d.year &&
          now.day == d.day &&
          now.month == d.month;

      if (!outOfRange) {
        lessonCountMonth += meta.lessonCount;
        if (meta.hasTest) testCountMonth++;
        if (meta.omission != null) omissionCountMonth++;
      }

      Color bodyBgColor = appStyle.colors.a15p;
      Widget body = const SizedBox();
      final todayAccent = isToday ? appStyle.colors.textPrimaryLight : null;

      if (meta.lessonCount > 0) {
        body = Center(
          child: Text(
            meta.lessonCount.toString(),
            style: appStyle.fonts.H_16px.apply(
              color: (todayAccent ??
                      (meta.omission != null
                          ? appStyle.colors.errorText
                          : appStyle.colors.secondary))
                  .withAlpha(outOfRange ? 77 : 255),
            ),
          ),
        );
        if (meta.omission != null) {
          bodyBgColor = appStyle.colors.error15p;
        }
      }

      if (isToday) {
        bodyBgColor = appStyle.colors.accent;
      }
      if (outOfRange) {
        bodyBgColor = appStyle.colors.cardTranslucent;
      }

      final isWeekend = d.weekday > 5 && meta.lessonCount == 0;
      var textColor = isWeekend
          ? appStyle.colors.errorText
          : isToday
          ? appStyle.colors.textPrimary
          : appStyle.colors.textTertiary;
      if (outOfRange) {
        textColor = textColor.withAlpha(77);
      } else if (isWeekend) {
        textColor = textColor.withAlpha(128);
      }

      ttDays.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: bodyBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: body,
            ),
            const SizedBox(height: 4),
            Text(
              d.format(data.l10n, FormatMode.d),
              style: (isToday ? appStyle.fonts.B_14SB : appStyle.fonts.B_14R)
                  .apply(color: textColor),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 74 + 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      headingText(data.l10n.timetable),
                      style: appStyle.fonts.H_H2.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.tableSolid,
                          size: 20,
                          color: appStyle.colors.accent,
                        ),
                        FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.settingsCogSolid,
                          size: 20,
                          color: appStyle.colors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FirkaIconWidget(
                      FirkaIconType.icons,
                      "dropdownLeft",
                      size: 24,
                      color: appStyle.colors.accent,
                    ),
                    Text(
                      now
                          .format(data.l10n, FormatMode.yyyymmmm)
                          .toLowerCase(),
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    FirkaIconWidget(
                      FirkaIconType.icons,
                      "dropdownRight",
                      size: 24,
                      color: appStyle.colors.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 74 + 16 + 12, left: 20, right: 20),
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 16,
            mainAxisExtent: 62,
            children: ttDays,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                _PreviewStatusToast(
                  FirkaIconWidget(
                    FirkaIconType.majesticons,
                    Majesticon.clockSolid,
                    color: appStyle.colors.accent,
                    size: 16,
                  ),
                  lessonCountMonth,
                  true,
                ),
                _PreviewStatusToast(
                  FirkaIconWidget(
                    FirkaIconType.majesticons,
                    Majesticon.editPen4Solid,
                    color: appStyle.colors.accent,
                    size: 16,
                  ),
                  testCountMonth,
                  false,
                ),
                _PreviewStatusToast(
                  FirkaIconWidget(
                    FirkaIconType.majesticons,
                    Majesticon.timerLine,
                    color: appStyle.colors.accent,
                    size: 16,
                  ),
                  omissionCountMonth,
                  false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewStatusToast extends StatelessWidget {
  final FirkaIconWidget icon;
  final int count;
  final bool active;

  const _PreviewStatusToast(this.icon, this.count, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: active
            ? appStyle.colors.buttonSecondaryFill
            : appStyle.colors.cardTranslucent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        spacing: 6,
        children: [
          icon,
          Text(
            count.toString(),
            style: appStyle.fonts.H_16px.apply(
              color: active
                  ? appStyle.colors.textPrimary
                  : appStyle.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class ThemePreviewHomeOmissions extends StatelessWidget {
  final AppInitialization data;
  final ThemePreviewData preview;

  const ThemePreviewHomeOmissions({
    super.key,
    required this.data,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final omissionItems = preview.omissions;
    final overallExcused = preview.omissionExcusedCount;
    final overallUnexcused = preview.omissionUnexcusedCount;
    final overallPending = preview.omissionPendingCount;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headingText(data.l10n.omissions),
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: FirkaCard.single(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          FirkaIconWidget(
                            FirkaIconType.majesticonsLocal,
                            "checkSolid",
                            size: 12,
                            color: appStyle.colors.accent,
                          ),
                          Text(
                            overallExcused.toString(),
                            style: appStyle.fonts.H_18px.copyWith(
                              color: appStyle.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        data.l10n.omission_state_excused,
                        style: appStyle.fonts.B_16R.copyWith(
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FirkaCard.single(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.timerSolid,
                            size: 12,
                            color: appStyle.colors.warningAccent,
                          ),
                          Text(
                            overallPending.toString(),
                            style: appStyle.fonts.H_18px.copyWith(
                              color: appStyle.colors.warningAccent,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        data.l10n.omission_state_pending,
                        style: appStyle.fonts.B_16R.copyWith(
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FirkaCard.single(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.restrictedSolid,
                            size: 12,
                            color: appStyle.colors.errorAccent,
                          ),
                          Text(
                            overallUnexcused.toString(),
                            style: appStyle.fonts.H_18px.copyWith(
                              color: appStyle.colors.errorAccent,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        data.l10n.omission_state_unexcused,
                        style: appStyle.fonts.B_16R.copyWith(
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OmissionBar(previewSegments: preview.omissionBarSegments),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Text(
                  data.l10n.subjects,
                  style: appStyle.fonts.B_16SB.copyWith(
                    color: appStyle.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...omissionItems
                    .fold(
                      LinkedHashMap<
                        SubjectCacheModel,
                        List<OmissionCacheModel>
                      >(
                        equals: (a, b) => a.cacheKey == b.cacheKey,
                        hashCode: (a) => a.cacheKey,
                      ),
                      (map, o) => map
                        ..putIfAbsent(
                          o.lesson.value!.subject.value!,
                          () => [],
                        ).add(o),
                    )
                    .entries
                    .map((entry) {
                      final excused = entry.value
                          .where((o) => o.state == OmissionState.excused)
                          .length;
                      final unexcused = entry.value
                          .where((o) => o.state == OmissionState.unexcused)
                          .length;
                      final pending = entry.value
                          .where((o) => o.state == OmissionState.pending)
                          .length;

                      return FirkaCard.single(
                        height: 64,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InfoCard.buildSubject(
                              appStyle.colors.accent,
                              entry.key,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 2,
                                children: [
                                  Text(
                                    entry.key.name,
                                    style: appStyle.fonts.B_16SB.copyWith(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    spacing: 4,
                                    children: [
                                      FirkaIconWidget(
                                        FirkaIconType.majesticonsLocal,
                                        "checkSolid",
                                        size: 12,
                                        color: appStyle.colors.accent,
                                      ),
                                      Text(
                                        excused.toString(),
                                        style: appStyle.fonts.B_14R.copyWith(
                                          color: appStyle.colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      FirkaIconWidget(
                                        FirkaIconType.majesticons,
                                        Majesticon.timerSolid,
                                        size: 12,
                                        color: appStyle.colors.warningAccent,
                                      ),
                                      Text(
                                        pending.toString(),
                                        style: appStyle.fonts.B_14R.copyWith(
                                          color: appStyle.colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      FirkaIconWidget(
                                        FirkaIconType.majesticons,
                                        Majesticon.restrictedLine,
                                        size: 12,
                                        color: appStyle.colors.errorAccent,
                                      ),
                                      Text(
                                        unexcused.toString(),
                                        style: appStyle.fonts.B_14R.copyWith(
                                          color: appStyle.colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThemePreviewHomeGradesSubject extends StatelessWidget {
  final AppInitialization data;
  final ThemePreviewData preview;

  const ThemePreviewHomeGradesSubject({
    super.key,
    required this.data,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final grades = preview.subjectDetailGrades;
    final subject = preview.subjectDetailSubject;

    return Container(
      color: appStyle.colors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-4, 0),
                    child: FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.chevronLeftLine,
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-4, 0),
                    child: Text(
                      data.l10n.subjects,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              FirkaIconWidget(
                FirkaIconType.majesticons,
                Majesticon.menuSolid,
                size: 20,
                color: appStyle.colors.accent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledCircle(
                      diameter: 36,
                      color: appStyle.colors.a15p,
                      child: ClassIconWidget(
                        subject: subject,
                        color: appStyle.colors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subject.name,
                      style: appStyle.fonts.H_H2.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.subjectDetailTeacher,
                      textAlign: TextAlign.center,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GradeChart(grades: grades),
                const SizedBox(height: 10),
                GradeSummaryBar(grades: grades, l10n: data.l10n),
                const SizedBox(height: 20),
                ...grades
                    .groupList((e) => e.writtenAt)
                    .entries
                    .map(
                      (e) => Column(
                        spacing: 10,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key.format(data.l10n, FormatMode.main),
                            style: appStyle.fonts.B_16R.apply(
                              color: appStyle.colors.textSecondary,
                            ),
                          ),
                          ...e.value.map(
                            (v) => InfoCard.gradeDesc(v, onTap: (_) {}),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
