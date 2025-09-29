import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/model/style.dart';
import 'package:flutter/material.dart';

import '../../../helpers/api/model/timetable.dart';
import '../../widget/class_icon.dart';

class LessonSmallWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final Lesson lesson;
  final bool lessonActive;

  const LessonSmallWidget(this.l10n, this.lesson, this.lessonActive,
      {super.key});

  @override
  Widget build(BuildContext context) {
    var subjectName = lesson.subject?.name ?? 'N/A';
    if (subjectName.length >= 25) {
      subjectName = "${subjectName.substring(0, 25 - 3)}...";
    }
    subjectName = subjectName.firstUpper();

    var roomName = lesson.roomName ?? '?';
    if (roomName.length >= 8) {
      roomName = "${roomName.substring(0, 8 - 3)}...";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FirkaCard(
          attached: lessonActive ? Attach.none : Attach.top,
          left: [
            ClassIconWidget(
              color: wearStyle.colors.accent,
              size: 20,
              uid: lesson.uid,
              className: lesson.name,
              category: lesson.subject?.name != null
                  ? lesson.subject!.name.firstUpper()
                  : '',
            ),
            SizedBox(width: 8),
            Text(subjectName,
                style: appStyle.fonts.B_16SB
                    .apply(color: appStyle.colors.textPrimary)),
          ],
          right: [
            Card(
              shadowColor: Colors.transparent,
              color: appStyle.colors.a15p,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(roomName,
                    style: appStyle.fonts.B_12R
                        .apply(color: appStyle.colors.secondary)),
              ),
            ),
            Text(
                "${lesson.start.toLocal().format(l10n, FormatMode.hmm)} - ${lesson.end.toLocal().format(l10n, FormatMode.hmm)}",
                style: appStyle.fonts.B_16R
                    .apply(color: appStyle.colors.textPrimary)),
          ],
        )
      ],
    );
  }
}
