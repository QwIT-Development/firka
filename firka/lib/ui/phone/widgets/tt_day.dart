import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'lesson.dart';

class TimeTableDayWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final DateTime date;
  final List<Lesson> lessons;
  final bool active;

  const TimeTableDayWidget(this.l10n, this.date, this.lessons, this.active,
      {super.key});

  @override
  Widget build(BuildContext context) {
    Widget noLessonsWidget = SizedBox();
    List<Widget> ttBody = List.empty(growable: true);

    if (lessons.isEmpty) {
      noLessonsWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/logos/dave.svg",
                width: 48, height: 48),
            SizedBox(height: 12),
            Text(l10n.tt_no_classes_l1),
            Text(l10n.tt_no_classes_l2)
          ]);
    } else {
      for (var i = 0; i < lessons.length; i++) {
        var lesson = lessons[i];
        Lesson? nextLesson = lessons.length > i + 1 ? lessons[i + 1] : null;
        ttBody.add(LessonWidget(
            l10n, lessons.getLessonNo(lesson), lesson, nextLesson));
      }
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width / (active ? 1 : 1.6),
      child: lessons.isEmpty
          ? noLessonsWidget
          : Padding(
              padding: const EdgeInsets.only(top: 50 + 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ttBody,
              ),
            ),
    );
  }
}
