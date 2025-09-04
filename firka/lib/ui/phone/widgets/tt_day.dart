import 'package:firka/helpers/api/model/test.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/main.dart';
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

  const TimeTableDayWidget(
      this.data, this.date, this.week, this.lessons, this.events, this.tests,
      {super.key});

  @override
  Widget build(BuildContext context) {
    Widget noLessonsWidget = SizedBox();
    List<Widget> ttBody = List.empty(growable: true);

    if (lessons.isEmpty && events.isEmpty) {
      noLessonsWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/logos/dave.svg",
                width: 48, height: 48),
            SizedBox(height: 12),
            Text(data.l10n.tt_no_classes_l1),
            Text(data.l10n.tt_no_classes_l2)
          ]);
    } else {
      for (var i = 0; i < events.length; i++) {
        var event = events[i];
        ttBody.add(FirkaCard(left: [Text(event.name)]));
      }
      for (var i = 0; i < lessons.length; i++) {
        var lesson = lessons[i];
        Lesson? nextLesson = lessons.length > i + 1 ? lessons[i + 1] : null;
        ttBody.add(LessonWidget(
            data,
            week,
            lessons.getLessonNo(lesson),
            lesson,
            tests.firstWhereOrNull(
                (test) => test.lessonNumber == lesson.lessonNumber),
            nextLesson));
      }
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width / 1.1,
      child: ttBody.isEmpty
          ? noLessonsWidget
          : Padding(
              padding:
                  const EdgeInsets.only(top: 70 + 16 + 20, left: 4, right: 4),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ttBody,
                ),
              ),
            ),
    );
  }
}
