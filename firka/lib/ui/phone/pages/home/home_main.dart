import 'dart:async';

import 'package:firka/helpers/extensions.dart';
import 'package:firka/ui/phone/widgets/home_main_starting_soon.dart';
import 'package:firka/ui/phone/widgets/lesson_small.dart';
import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/api/model/student.dart';
import '../../../../helpers/api/model/timetable.dart';
import '../../../../helpers/debug_helper.dart';
import '../../../../main.dart';
import '../../widgets/home_main_welcome.dart';
import '../../widgets/lesson_big.dart';

class HomeMainScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeMainScreen(this.data, {super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreen(data);
}

class _HomeMainScreen extends State<HomeMainScreen> {
  final AppInitialization data;

  _HomeMainScreen(this.data);

  DateTime now = timeNow();
  List<Lesson>? lessons;
  Student? student;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    now = timeNow();
    var midnight = now.getMidnight();
    (() async {
      var resp = await data.client.getTimeTable(
          midnight, midnight.add(Duration(hours: 23, minutes: 59)));

      setState(() {
        lessons = resp.response!;
      });
    })();
    (() async {
      var resp = await data.client.getStudent();

      setState(() {
        student = resp.response!;
      });
    })();

    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      setState(() {
        now = timeNow();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Widget welcomeWidget = SizedBox();
    Widget nextClass = SizedBox();

    if (lessons != null && lessons!.isNotEmpty) {
      if (now.isBefore(lessons!.first.start)) {
        welcomeWidget = StartingSoonWidget(now, lessons!);
      } else {
        var currentLesson = lessons!.firstWhereOrNull(
            (lesson) => now.isAfter(lesson.start) && now.isBefore(lesson.end));
        // "fun" fact if your clock was exactly when the class ends then isBefore
        // and isAfter would fail, so to work around that we just add 1ms to the
        // current time
        var prevLesson = lessons!.getPrevLesson(now);
        var nextLesson = lessons!.getNextLesson(now);
        int? lessonIndex;

        if (currentLesson != null) {
          lessonIndex = lessons!.getLessonNo(currentLesson);
        }

        welcomeWidget = LessonBigWidget(
            now, lessonIndex, currentLesson, prevLesson, nextLesson);
      }
    }
    if (lessons != null && lessons!.isNotEmpty) {
      var nextLesson = lessons!.getNextLesson(now);
      if (nextLesson != null) nextClass = LessonSmallWidget(nextLesson);
    }

    if (student != null && lessons != null) {
      return Flexible(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20.0,
            top: 24.0,
            right: 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              WelcomeWidget(now, student!, lessons!),
              SizedBox(height: 48),
              welcomeWidget,
              nextClass
            ],
          ),
        ),
      );
    } else {
      return DelayedSpinnerWidget();
    }
  }
}
