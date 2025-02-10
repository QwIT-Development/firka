import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/model/style.dart';
import 'package:flutter/material.dart';

import '../../../helpers/api/model/timetable.dart';
import '../../widget/class_icon.dart';

class LessonWidget extends StatelessWidget {
  final int? lessonNo;
  final Lesson lesson;
  final Lesson? nextLesson;

  const LessonWidget(this.lessonNo, this.lesson, this.nextLesson, {super.key});

  @override
  Widget build(BuildContext context) {
    var isSubstituted = lesson.substituteTeacher != null;
    var isDismissed = lesson.type.name == "UresOra";

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

    elements.add(GestureDetector(
      onTap: () {
        showLessonBottomSheet(
            context, lesson, lessonNo, accent, secondary, bgColor);
      },
      child: FirkaCard(
        left: [
          Card(
            // TODO: improve this to match design
            shadowColor: Colors.transparent,
            color: bgColor,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Text(lessonNo.toString(),
                  style: appStyle.fonts.B_12R.apply(color: secondary)),
            ),
          ),
          Card(
            shadowColor: Colors.transparent,
            color: bgColor,
            child: Padding(
              padding: EdgeInsetsGeometry.all(4),
              child: ClassIconWidget(
                color: accent,
                size: 20,
                uid: lesson.uid,
                className: lesson.name,
                category: lesson.subject?.name ?? '',
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(lesson.subject?.name ?? "N/A",
              style: appStyle.fonts.B_16SB
                  .apply(color: appStyle.colors.textPrimary)),
        ],
        right: [
          Text(
              isDismissed
                  ? AppLocalizations.of(context)!.class_dismissed
                  : lesson.start.toLocal().format(context, FormatMode.hmm),
              style: appStyle.fonts.B_14R
                  .apply(color: appStyle.colors.textPrimary)),
          isDismissed
              ? SizedBox()
              : Card(
                  shadowColor: Colors.transparent,
                  color: appStyle.colors.a15p,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(lesson.roomName ?? '?',
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
          Text(AppLocalizations.of(context)!.class_substitution,
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

    if (nextLesson != null) {
      elements.add(SizedBox(height: 4));
      var breakMins = nextLesson!.start.difference(lesson.end).inMinutes;

      elements.add(FirkaCard(
        left: [
          Text(AppLocalizations.of(context)!.breakTxt,
              style: appStyle.fonts.B_14SB
                  .apply(color: appStyle.colors.textSecondary))
        ],
        right: [
          Text(
              "$breakMins ${breakMins == 1 ? AppLocalizations.of(context)!.starting_min : AppLocalizations.of(context)!.starting_min_plural}",
              style: appStyle.fonts.B_14R
                  .apply(color: appStyle.colors.textTertiary))
        ],
      ));
      elements.add(SizedBox(height: 4));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: elements,
    );
  }
}

void showLessonBottomSheet(BuildContext context, Lesson lesson, int? lessonNo,
    Color accent, Color secondary, Color bgColor) {
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.3,
    ),
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Card(
                          // TODO: improve this to match design
                          shadowColor: Colors.transparent,
                          color: bgColor,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(lessonNo.toString(),
                                style: appStyle.fonts.B_12R
                                    .apply(color: secondary)),
                          ),
                        ),
                        Card(
                          shadowColor: Colors.transparent,
                          color: bgColor,
                          child: Padding(
                            padding: EdgeInsetsGeometry.all(6),
                            child: ClassIconWidget(
                              color: accent,
                              size: 20,
                              uid: lesson.uid,
                              className: lesson.name,
                              category: lesson.subject?.name ?? '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.name,
                            style: appStyle.fonts.H_18px
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                          Text(
                            lesson.teacher ?? 'N/A',
                            style: appStyle.fonts.B_14R
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                          Text(
                            '${lesson.start.format(context, FormatMode.hmm)} - ${lesson.end.format(context, FormatMode.hmm)}',
                            style: appStyle.fonts.B_14R
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    FirkaCard(left: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.lesson_subject,
                            style: appStyle.fonts.H_14px,
                          ),
                          SizedBox(height: 4),
                          Text(
                            lesson.theme ?? 'N/A',
                            style: appStyle.fonts.B_16R,
                          )
                        ],
                      )
                    ])
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
