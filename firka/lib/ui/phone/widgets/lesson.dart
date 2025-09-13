import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/settings/setting.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../helpers/api/model/test.dart';
import '../../../helpers/api/model/timetable.dart';
import '../../../helpers/debug_helper.dart';
import '../../../helpers/ui/common_bottom_sheets.dart';
import '../../widget/class_icon.dart';
import '../../widget/firka_icon.dart';
import 'bubble_test.dart';

class LessonWidget extends StatelessWidget {
  final AppInitialization data;
  final List<Lesson> week;
  final int? lessonNo;
  final Lesson lesson;
  final Test? test;
  final Lesson? nextLesson;
  final bool? placeholderMode;

  const LessonWidget(this.data, this.week, this.lessonNo, this.lesson,
      this.test, this.nextLesson,
      {super.key, this.placeholderMode});

  @override
  Widget build(BuildContext context) {
    final showTests = data.settings
        .group("settings")
        .subGroup("timetable_toast")
        .boolean("tests_and_homework");

    final isSubstituted = lesson.substituteTeacher != null;
    final isDismissed = lesson.type.name == "UresOra";

    final showBreak =
        timeNow().isAfter(lesson.start) && timeNow().isBefore(lesson.end) ||
            timeNow().isAfter(week.last.end) ||
            lesson.start.getMidnight() != timeNow().getMidnight();

    var accent = appStyle.colors.accent;
    var secondary = appStyle.colors.secondary;
    var bgColor = appStyle.colors.a15p;

    if (isSubstituted) {
      accent = appStyle.colors.warningAccent;
      secondary = appStyle.colors.warningText;
      bgColor = appStyle.colors.warning15p;
    }
    if (isDismissed) {
      accent = appStyle.colors.errorAccent;
      secondary = appStyle.colors.errorText;
      bgColor = appStyle.colors.error15p;
    }

    List<Widget> elements = [];

    var subjectName = lesson.subject?.name ?? 'N/A';
    if (subjectName.length >= 25) {
      subjectName = "${subjectName.substring(0, 25 - 3)}...";
    }

    var roomName = lesson.roomName ?? '?';
    if (roomName.length >= 8) {
      roomName = "${roomName.substring(0, 8 - 3)}...";
    }

    elements.add(GestureDetector(
      onTap: () {
        showLessonBottomSheet(
            context, data, lesson, lessonNo, accent, secondary, bgColor);
      },
      child: FirkaCard(
        color: isDismissed
            ? appStyle.colors.cardTranslucent
            : appStyle.colors.card,
        shadow: !isDismissed,
        left: [
          placeholderMode == true
              ? SizedBox()
              : SizedBox(
                  width: 18,
                  height: 18,
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        "assets/icons/subtract.svg",
                        color: bgColor,
                        width: 18,
                        height: 18,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(lessonNo.toString(),
                            style:
                                appStyle.fonts.B_12R.apply(color: secondary)),
                      )
                    ],
                  ),
                ),
          Transform.translate(
            offset: Offset(-4, 0),
            child: Card(
              shadowColor: Colors.transparent,
              color: bgColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Stack(children: [
                Padding(
                  padding: EdgeInsetsGeometry.all(4),
                  child: ClassIconWidget(
                    color: accent,
                    size: 20,
                    uid: lesson.uid,
                    className: lesson.name,
                    category: lesson.subject?.name ?? '',
                  ),
                ),
                !showTests && test != null
                    ? Transform.translate(
                        offset: Offset(26, -18),
                        child: BubbleTest(),
                      )
                    : SizedBox(),
              ]),
            ),
          ),
          SizedBox(width: !showTests && test != null ? 16 : 8),
          Text(subjectName,
              style: appStyle.fonts.B_16SB
                  .apply(color: appStyle.colors.textPrimary)),
        ],
        right: [
          placeholderMode == true
              ? SizedBox()
              : Text(
                  isDismissed
                      ? data.l10n.class_dismissed
                      : lesson.start
                          .toLocal()
                          .format(data.l10n, FormatMode.hmm),
                  style: appStyle.fonts.B_14R
                      .apply(color: appStyle.colors.textPrimary)),
          placeholderMode == true
              ? SizedBox()
              : isDismissed
                  ? SizedBox()
                  : Card(
                      shadowColor: Colors.transparent,
                      color: appStyle.colors.a15p,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Text(roomName,
                            style: appStyle.fonts.B_12R
                                .apply(color: appStyle.colors.secondary)),
                      ),
                    ),
        ],
      ),
    ));

    if (isSubstituted) {
      elements.add(FirkaCard(
        left: [
          Text(data.l10n.class_substitution,
              style: appStyle.fonts.H_14px
                  .apply(color: appStyle.colors.textPrimary))
        ],
        right: [
          Text(lesson.substituteTeacher!,
              style: appStyle.fonts.B_16R
                  .apply(color: appStyle.colors.textSecondary))
        ],
      ));
    }

    if (test != null && showTests) {
      elements.add(FirkaCard(
        left: [
          FirkaIconWidget(
            FirkaIconType.majesticons,
            Majesticon.editPen4Solid,
            color: appStyle.colors.accent,
          ),
          SizedBox(width: 6),
          Text(test!.theme,
              style: appStyle.fonts.B_14SB
                  .apply(color: appStyle.colors.textSecondary))
        ],
        right: [
          Text(test!.method.description ?? "N/A",
              style: appStyle.fonts.B_14R
                  .apply(color: appStyle.colors.textTertiary))
        ],
      ));
    }

    if (nextLesson != null) {
      var breakMins = nextLesson!.start.difference(lesson.end).inMinutes;
      var seqSchedule = week.getAllSeqs(lesson);

      if (breakMins > 45) {
        final breakEnd = lesson.end.add(Duration(minutes: breakMins));
        final emptyClass = seqSchedule.firstWhereOrNull((lesson2) =>
            lesson2.start.isAfter(lesson.end) &&
            lesson2.end.isBefore(breakEnd));

        if (emptyClass != null) {
          final preBreak = emptyClass.start.difference(lesson.end).inMinutes;
          final postBreak = breakEnd.difference(emptyClass.end).inMinutes;

          if (data.settings
                  .group("settings")
                  .subGroup("timetable_toast")
                  .boolean("breaks") &&
              showBreak) {
            elements.add(FirkaCard(
              color: appStyle.colors.cardTranslucent,
              shadow: false,
              left: [
                Text(data.l10n.breakTxt,
                    style: appStyle.fonts.B_14SB
                        .apply(color: appStyle.colors.textSecondary))
              ],
              right: [
                Text(
                    "$preBreak ${preBreak == 1 ? data.l10n.starting_min : data.l10n.starting_min_plural}",
                    style: appStyle.fonts.B_14R
                        .apply(color: appStyle.colors.textTertiary))
              ],
            ));
          }

          elements.add(FirkaCard(
            left: [
              SizedBox(
                width: 18,
                height: 18,
                child: Stack(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/subtract.svg",
                      color: bgColor,
                      width: 18,
                      height: 18,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text(emptyClass.lessonNumber.toString(),
                          style: appStyle.fonts.B_12R.apply(color: secondary)),
                    )
                  ],
                ),
              ),
              Transform.translate(
                offset: Offset(-4, 0),
                child: Card(
                  shadowColor: Colors.transparent,
                  color: bgColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsetsGeometry.all(4),
                    child: FirkaIconWidget(
                        FirkaIconType.majesticonsLocal, 'cupFilled',
                        color: appStyle.colors.accent, size: 24),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(data.l10n.empty_class,
                  style: appStyle.fonts.B_16SB
                      .apply(color: appStyle.colors.textPrimary)),
            ],
            right: [
              Text(
                  isDismissed
                      ? data.l10n.class_dismissed
                      : "${emptyClass.start.toLocal().format(data.l10n, FormatMode.hmm)} - ${emptyClass.end.toLocal().format(data.l10n, FormatMode.hmm)}",
                  style: appStyle.fonts.B_14R
                      .apply(color: appStyle.colors.textPrimary))
            ],
          ));

          if (data.settings
                  .group("settings")
                  .subGroup("timetable_toast")
                  .boolean("breaks") &&
              showBreak) {
            elements.add(FirkaCard(
              color: appStyle.colors.cardTranslucent,
              shadow: false,
              left: [
                Text(data.l10n.breakTxt,
                    style: appStyle.fonts.B_14SB
                        .apply(color: appStyle.colors.textSecondary))
              ],
              right: [
                Text(
                    "$postBreak ${postBreak == 1 ? data.l10n.starting_min : data.l10n.starting_min_plural}",
                    style: appStyle.fonts.B_14R
                        .apply(color: appStyle.colors.textTertiary))
              ],
            ));
          }
        } else if (data.settings
                .group("settings")
                .subGroup("timetable_toast")
                .boolean("breaks") &&
            showBreak) {
          elements.add(FirkaCard(
            color: appStyle.colors.cardTranslucent,
            shadow: false,
            left: [
              Text(data.l10n.breakTxt,
                  style: appStyle.fonts.B_14SB
                      .apply(color: appStyle.colors.textSecondary))
            ],
            right: [
              Text(
                  "$breakMins ${breakMins == 1 ? data.l10n.starting_min : data.l10n.starting_min_plural}",
                  style: appStyle.fonts.B_14R
                      .apply(color: appStyle.colors.textTertiary))
            ],
          ));
        }
      } else if (data.settings
              .group("settings")
              .subGroup("timetable_toast")
              .boolean("breaks") &&
          showBreak) {
        elements.add(FirkaCard(
          color: appStyle.colors.cardTranslucent,
          shadow: false,
          left: [
            Text(data.l10n.breakTxt,
                style: appStyle.fonts.B_14SB
                    .apply(color: appStyle.colors.textSecondary))
          ],
          right: [
            Text(
                "$breakMins ${breakMins == 1 ? data.l10n.starting_min : data.l10n.starting_min_plural}",
                style: appStyle.fonts.B_14R
                    .apply(color: appStyle.colors.textTertiary))
          ],
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: elements,
    );
  }
}
