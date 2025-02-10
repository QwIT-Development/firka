import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';

import '../../../helpers/api/model/timetable.dart';
import '../../widget/class_icon.dart';

class LessonBigWidget extends StatelessWidget {
  final DateTime now;
  final int? lessonNo;
  final Lesson? lesson;
  final Lesson? prevLesson;
  final Lesson? nextLesson;

  const LessonBigWidget(
      this.now, this.lessonNo, this.lesson, this.prevLesson, this.nextLesson,
      {super.key});

  @override
  Widget build(BuildContext context) {
    var hasLesson = lesson != null;
    var hasPrevLesson = prevLesson != null;
    var hasNextLesson = nextLesson != null;

    if (!hasLesson && (!hasPrevLesson || !hasNextLesson)) {
      throw Exception(
          '!hasLesson($hasLesson) && (!hasPrevLesson($hasPrevLesson) || '
          '!hasNextLesson($hasNextLesson))');
    }

    if (hasLesson) {
      var timeLeft = lesson!.end.difference(now);
      var duration = lesson!.end.difference(lesson!.start).inMilliseconds;
      var progress = now.difference(lesson!.start).inMilliseconds;

      var minsLeft = timeLeft.inMinutes;
      var secsLeft = timeLeft.inSeconds;

      var timeLeftStr =
          "$minsLeft ${minsLeft == 1 ? AppLocalizations.of(context)!.starting_min : AppLocalizations.of(context)!.starting_min_plural}";
      if (minsLeft < 1) {
        timeLeftStr =
            "$secsLeft ${secsLeft == 1 ? AppLocalizations.of(context)!.starting_sec : AppLocalizations.of(context)!.starting_sec_plural}";
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FirkaCard(
            left: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Card(
                        // TODO: improve this to match design
                        shadowColor: Colors.transparent,
                        color: appStyle.colors.a15p,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(lessonNo.toString(),
                              style: appStyle.fonts.B_12R
                                  .apply(color: appStyle.colors.secondary)),
                        ),
                      ),
                      Card(
                        shadowColor: Colors.transparent,
                        color: appStyle.colors.a15p,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: ClassIconWidget(
                            color: wearStyle.colors.accent,
                            size: 24,
                            uid: lesson!.uid,
                            className: lesson!.name,
                            category: lesson!.subject?.name ?? '',
                          ),
                        ),
                      ),
                      Text(lesson!.subject?.name ?? 'N/A',
                          style: appStyle.fonts.B_16SB
                              .apply(color: appStyle.colors.textPrimary)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(timeLeftStr,
                          style: appStyle.fonts.B_12R
                              .apply(color: appStyle.colors.textSecondary)),
                    ],
                  ),
                ],
              )
            ],
            right: [
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                          lesson!.start
                              .toLocal()
                              .format(context, FormatMode.hmm),
                          style: appStyle.fonts.B_14R
                              .apply(color: appStyle.colors.textPrimary)),
                      Card(
                        shadowColor: Colors.transparent,
                        color: appStyle.colors.a15p,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(lesson!.roomName ?? '?',
                              style: appStyle.fonts.B_12R
                                  .apply(color: appStyle.colors.secondary)),
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 18),
                      Text(
                          lesson!.end.toLocal().format(context, FormatMode.hmm),
                          style: appStyle.fonts.B_12R
                              .apply(color: appStyle.colors.textSecondary)),
                    ],
                  )
                ],
              )
            ],
            extra: LinearProgressIndicator(
              // TODO: Make this rounded
              value: progress / duration,
              backgroundColor: appStyle.colors.a15p,
              color: appStyle.colors.accent,
            ),
          )
        ],
      );
    } else {
      var duration =
          nextLesson!.start.difference(prevLesson!.end).inMilliseconds;
      var progress =
          duration - nextLesson!.start.difference(now).inMilliseconds;
      var timeLeft = nextLesson!.start.difference(now);

      var timeLeftStr =
          AppLocalizations.of(context)!.timeLeft(timeLeft.inMinutes + 1);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FirkaCard(
            left: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Card(
                        shadowColor: Colors.transparent,
                        color: appStyle.colors.a15p,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: FirkaIconWidget(
                              FirkaIconType.MajesticonsLocal, 'cupFilled',
                              color: wearStyle.colors.accent, size: 24),
                        ),
                      ),
                      Text(AppLocalizations.of(context)!.breakTxt,
                          style: appStyle.fonts.B_16SB
                              .apply(color: appStyle.colors.textPrimary)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(timeLeftStr,
                          style: appStyle.fonts.B_12R
                              .apply(color: appStyle.colors.textSecondary)),
                    ],
                  ),
                ],
              )
            ],
            right: [
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                          prevLesson!.end
                              .toLocal()
                              .format(context, FormatMode.hmm),
                          style: appStyle.fonts.B_14R
                              .apply(color: appStyle.colors.textPrimary)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                          nextLesson!.start
                              .toLocal()
                              .format(context, FormatMode.hmm),
                          style: appStyle.fonts.B_14R
                              .apply(color: appStyle.colors.textPrimary)),
                    ],
                  )
                ],
              )
            ],
            extra: LinearProgressIndicator(
              // TODO: Make this rounded
              value: progress / duration,
              backgroundColor: appStyle.colors.a15p,
              color: appStyle.colors.accent,
            ),
          )
        ],
      );
    }
  }
}
