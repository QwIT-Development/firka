import 'dart:async';

import 'package:firka/helpers/api/model/grade.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/common_bottom_sheets.dart';
import 'package:firka/ui/phone/widgets/home_main_starting_soon.dart';
import 'package:firka/ui/phone/widgets/info_board_item.dart';
import 'package:firka/ui/phone/widgets/lesson_small.dart';
import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../../helpers/api/model/notice_board.dart';
import '../../../../helpers/api/model/student.dart';
import '../../../../helpers/api/model/test.dart';
import '../../../../helpers/api/model/timetable.dart';
import '../../../../helpers/debug_helper.dart';
import '../../../../helpers/firka_state.dart';
import '../../../../helpers/ui/firka_card.dart';
import '../../../../helpers/ui/grade.dart';
import '../../../../helpers/update_notifier.dart';
import '../../../../main.dart';
import '../../../model/style.dart';
import '../../../widget/firka_icon.dart';
import '../../widgets/home_main_welcome.dart';
import '../../widgets/lesson_big.dart';

class HomeMainScreen extends StatefulWidget {
  final AppInitialization data;
  final UpdateNotifier updateNotifier;
  final UpdateNotifier finishNotifier;

  const HomeMainScreen(this.data, this.updateNotifier, this.finishNotifier,
      {super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreen();
}

class _HomeMainScreen extends FirkaState<HomeMainScreen> {
  _HomeMainScreen();

  DateTime now = timeNow();
  List<Lesson>? lessons;
  List<NoticeBoardItem>? noticeBoard;
  List<InfoBoardItem>? infoBoard;
  List<Test>? tests;
  List<Grade>? grades;
  Student? student;
  Timer? timer;

  @override
  void didUpdateWidget(HomeMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.updateNotifier.removeListener(updateListener);
    widget.updateNotifier.addListener(updateListener);
  }

  void updateListener() async {
    final newData = await loadData(now, forceCache: false);

    if (mounted) {
      setState(() {
        lessons = newData.$1;
        noticeBoard = newData.$2;
        infoBoard = newData.$3;
        student = newData.$4;
      });
    }
    widget.finishNotifier.update();
  }

  Future<(List<Lesson>, List<NoticeBoardItem>, List<InfoBoardItem>, Student)>
      loadData(DateTime now, {bool forceCache = true}) async {
    var midnight = now.getMidnight();

    var respTT = await widget.data.client.getTimeTable(
        midnight, midnight.add(Duration(hours: 23, minutes: 59)),
        forceCache: forceCache);

    var respNB =
        await widget.data.client.getNoticeBoard(forceCache: forceCache);

    var respIB = await widget.data.client.getInfoBoard(forceCache: forceCache);

    var respStudent =
        await widget.data.client.getStudent(forceCache: forceCache);

    var testsResp = await widget.data.client.getTests(forceCache: forceCache);
    tests = testsResp.response;

    var gradesResp = await widget.data.client.getGrades(forceCache: forceCache);
    grades = gradesResp.response;

    return Future.value((
      respTT.response!,
      respNB.response!,
      respIB.response!,
      respStudent.response!,
    ));
  }

  @override
  void initState() {
    super.initState();

    widget.updateNotifier.addListener(updateListener);

    now = timeNow();
    if (!mounted) return;

    (() async {
      final newData = await loadData(now);

      if (mounted) {
        setState(() {
          lessons = newData.$1;
          noticeBoard = newData.$2;
          infoBoard = newData.$3;
          student = newData.$4;
        });
      }
    })();

    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      setState(() {
        now = timeNow();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    widget.updateNotifier.removeListener(updateListener);

    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Widget welcomeWidget = SizedBox();
    Widget nextClass = SizedBox();
    Widget? nextTest;
    bool lessonActive = false;

    if (lessons != null && noticeBoard != null && lessons!.isNotEmpty) {
      if (now.isBefore(lessons!.first.start)) {
        welcomeWidget = StartingSoonWidget(widget.data.l10n, now, lessons!);
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
          lessonActive = true;
        }

        welcomeWidget = LessonBigWidget(widget.data.l10n, now, lessonIndex,
            currentLesson, prevLesson, nextLesson);
      }
    }
    if (lessons != null && lessons!.isNotEmpty) {
      var nextLesson = lessons!.getNextLesson(now);
      if (nextLesson != null) {
        nextClass =
            LessonSmallWidget(widget.data.l10n, nextLesson, lessonActive);

        if (tests != null) {
          final testsOnDate = tests!
              .where((test) =>
                  test.date.isAfter(nextLesson.start
                      .getMidnight()
                      .subtract(Duration(seconds: 1))) &&
                  test.date.isBefore(nextLesson.end
                      .getMidnight()
                      .add(Duration(hours: 23, minutes: 59))) &&
                  test.subject.uid == nextLesson.subject?.uid)
              .toList();

          if (testsOnDate.isNotEmpty) {
            final test = testsOnDate.first;

            nextTest = FirkaCard(
              left: [
                FirkaIconWidget(
                  FirkaIconType.majesticons,
                  Majesticon.editPen4Solid,
                  color: appStyle.colors.accent,
                ),
                SizedBox(width: 6),
                Text(test.theme,
                    style: appStyle.fonts.B_14SB
                        .apply(color: appStyle.colors.textSecondary))
              ],
              right: [
                Text(test.method.description ?? "N/A",
                    style: appStyle.fonts.B_14R
                        .apply(color: appStyle.colors.textTertiary))
              ],
            );
          }
        }
      }
    }

    if (student != null &&
        grades != null &&
        noticeBoard != null &&
        lessons != null) {
      List<(Widget, DateTime)> noticeBoardWidgets = List.empty(growable: true);
      // TODO: Add notice board items once we actually have those

      for (final item in infoBoard!) {
        noticeBoardWidgets.add((InfoBoardItemWidget(item), item.date));
      }

      for (final grade in grades!) {
        noticeBoardWidgets.add((
          GestureDetector(
            child: FirkaCard(
              left: [
                Row(
                  children: [
                    GradeWidget(grade),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.45,
                          child: Text(grade.topic ?? grade.type.description!,
                              style: appStyle.fonts.B_14SB
                                  .apply(color: appStyle.colors.textPrimary)),
                        ),
                        grade.mode?.description != null
                            ? SizedBox(
                                width: MediaQuery.of(context).size.width / 1.45,
                                child: Text(
                                  grade.mode!.description!,
                                  style: appStyle.fonts.B_14R.apply(
                                      color: appStyle.colors.textSecondary),
                                ),
                              )
                            : SizedBox(),
                      ],
                    )
                  ],
                )
              ],
            ),
            onTap: () {
              showGradeBottomSheet(context, widget.data, grade);
            },
          ),
          grade.recordDate
        ));
      }

      noticeBoardWidgets
          .sort((item1, item2) => item2.$2.difference(item1.$2).inMilliseconds);

      return Padding(
        padding: const EdgeInsets.only(
          left: 20.0,
          top: 24.0,
          right: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WelcomeWidget(widget.data.l10n, now, student!, lessons!),
            SizedBox(height: 48),
            welcomeWidget,
            lessonActive ? SizedBox(height: 5) : SizedBox(height: 0),
            nextClass,
            nextTest != null ? SizedBox(height: 12) : SizedBox(height: 0),
            nextTest ?? SizedBox(),
            nextTest != null ? SizedBox(height: 12) : SizedBox(height: 0),
            Expanded(
              child: ListView(
                children: noticeBoardWidgets.map((e) => e.$1).toList(),
              ),
            )
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: appStyle.colors.background,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [DelayedSpinnerWidget()],
            )
          ],
        ),
      );
    }
  }
}
