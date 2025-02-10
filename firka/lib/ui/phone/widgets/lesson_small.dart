import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/ui/model/style.dart';
import 'package:flutter/material.dart';

import '../../../helpers/api/model/timetable.dart';
import '../../widget/class_icon.dart';

class LessonSmallWidget extends StatelessWidget {
  final Lesson lesson;

  const LessonSmallWidget(this.lesson, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FirkaCard(
          left: [
            ClassIconWidget(
              color: wearStyle.colors.accent,
              size: 20,
              uid: lesson.uid,
              className: lesson.name,
              category: lesson.subject?.name ?? '',
            ),
            SizedBox(width: 8),
            Text(lesson.subject?.name ?? "N/A",
                style: appStyle.fonts.B_16SB
                    .apply(color: appStyle.colors.textPrimary)),
          ],
          right: [
            Card(
              shadowColor: Colors.transparent,
              color: appStyle.colors.a15p,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(lesson.roomName ?? '?',
                    style: appStyle.fonts.B_12R
                        .apply(color: appStyle.colors.secondary)),
              ),
            ),
            Text(
                "${lesson.start.toLocal().format(context, FormatMode.hmm)} - ${lesson.end.toLocal().format(context, FormatMode.hmm)}",
                style: appStyle.fonts.B_14R
                    .apply(color: appStyle.colors.textPrimary)),
          ],
        )
      ],
    );
  }
}
