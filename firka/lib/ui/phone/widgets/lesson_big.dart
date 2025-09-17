import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../helpers/api/model/timetable.dart';
import '../../widget/class_icon.dart';

class LessonBigWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final DateTime now;
  final int? lessonNo;
  final Lesson? lesson;
  final Lesson? prevLesson;
  final Lesson? nextLesson;

  const LessonBigWidget(this.l10n, this.now, this.lessonNo, this.lesson,
      this.prevLesson, this.nextLesson,
      {super.key});

  @override
  Widget build(BuildContext context) {
    var hasLesson = lesson != null;
    var hasPrevLesson = prevLesson != null;
    var hasNextLesson = nextLesson != null;

    if (!hasLesson && (!hasPrevLesson || !hasNextLesson)) {
      if (!hasPrevLesson && !hasNextLesson) {
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
                                FirkaIconType.majesticons, 'cupFilled',
                                color: appStyle.colors.accent, size: 24),
                          ),
                        ),
                        Text(l10n.breakTxt,
                            style: appStyle.fonts.B_16SB
                                .apply(color: appStyle.colors.textPrimary)),
                      ],
                    ),
                  ],
                )
              ],
              right: [
                Column(
                  children: [
                    Row(children: [
                      Text('-',
                          style: appStyle.fonts.B_16R
                              .apply(color: appStyle.colors.textPrimary))
                    ]),
                    Row(children: [
                      Text('-',
                          style: appStyle.fonts.B_16R
                              .apply(color: appStyle.colors.textPrimary))
                    ])
                  ],
                )
              ],
              extra: SizedBox.shrink(),
            )
          ],
        );
      }

      // Before the first lesson: prev missing but next present. Show countdown
      // to the next lesson using nextLesson data.
      if (!hasPrevLesson && hasNextLesson) {
        var timeLeft = nextLesson!.start.difference(now);
        var timeLeftStr = l10n.timeLeft(timeLeft.inMinutes + 1);

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
                                FirkaIconType.majesticonsLocal, 'cupFilled',
                                color: appStyle.colors.accent, size: 24),
                          ),
                        ),
                        Text(l10n.breakTxt,
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
                    Row(children: [
                      Text('-',
                          style: appStyle.fonts.B_16R
                              .apply(color: appStyle.colors.textPrimary))
                    ]),
                    Row(children: [
                      Text(
                          nextLesson!.start
                              .toLocal()
                              .format(l10n, FormatMode.hmm),
                          style: appStyle.fonts.B_16R
                              .apply(color: appStyle.colors.textPrimary))
                    ])
                  ],
                )
              ],
              extra: SizedBox.shrink(),
            )
          ],
        );
      }

      // After the last lesson: next missing but prev present. Show a simple
      // "no more lessons" style card with the previous lesson end time.
      if (hasPrevLesson && !hasNextLesson) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TODO: implement home/today afternoon
          ],
        );
      }
    }

    if (hasLesson) {
      var timeLeft = lesson!.end.difference(now);
      var duration = lesson!.end.difference(lesson!.start).inMilliseconds;
      var progress = now.difference(lesson!.start).inMilliseconds;

      var minsLeft = timeLeft.inMinutes;
      var secsLeft = timeLeft.inSeconds;

      var timeLeftStr =
          "$minsLeft ${minsLeft == 1 ? l10n.starting_min : l10n.starting_min_plural}";
      if (minsLeft < 1) {
        timeLeftStr =
            "$secsLeft ${secsLeft == 1 ? l10n.starting_sec : l10n.starting_sec_plural}";
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
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Stack(
                          children: [
                            SvgPicture.asset(
                              "assets/icons/subtract.svg",
                              color: appStyle.colors.a15p,
                              width: 18,
                              height: 18,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Text(lessonNo.toString(),
                                  style: appStyle.fonts.B_12R
                                      .apply(color: appStyle.colors.secondary)),
                            )
                          ],
                        ),
                      ),
                      Transform.translate(
                          offset: Offset(-4, 0),
                          child: Card(
                            shadowColor: Colors.transparent,
                            color: appStyle.colors.a15p,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: ClassIconWidget(
                                color: appStyle.colors.accent,
                                size: 24,
                                uid: lesson!.uid,
                                className: lesson!.name,
                                category: lesson!.subject?.name ?? '',
                              ),
                            ),
                          )),
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
                      Text(lesson!.start.toLocal().format(l10n, FormatMode.hmm),
                          style: appStyle.fonts.B_16R
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
                      Text(lesson!.end.toLocal().format(l10n, FormatMode.hmm),
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

      var timeLeftStr = l10n.timeLeft(timeLeft.inMinutes + 1);

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
                              FirkaIconType.majesticonsLocal, 'cupFilled',
                              color: appStyle.colors.accent, size: 24),
                        ),
                      ),
                      Text(l10n.breakTxt,
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
                              .format(l10n, FormatMode.hmm),
                          style: appStyle.fonts.B_16R
                              .apply(color: appStyle.colors.textPrimary)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                          nextLesson!.start
                              .toLocal()
                              .format(l10n, FormatMode.hmm),
                          style: appStyle.fonts.B_16R
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
