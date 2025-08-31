import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/helpers/ui/grade_helpers.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:firka/ui/widget/grade_small_card.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/api/consts.dart';
import '../../../../helpers/api/model/grade.dart';
import '../../../../helpers/api/model/subject.dart';
import '../../../../helpers/api/model/timetable.dart';
import '../../../../helpers/debug_helper.dart';
import '../../../../helpers/update_notifier.dart';
import '../../../../main.dart';
import '../../../model/style.dart';
import '../../../widget/delayed_spinner.dart';

class HomeGradesScreen extends StatefulWidget {
  final AppInitialization data;
  final UpdateNotifier updateNotifier;
  final UpdateNotifier finishNotifier;
  final void Function(int) pageController;

  const HomeGradesScreen(
      this.data, this.updateNotifier, this.finishNotifier, this.pageController,
      {super.key});

  @override
  State<StatefulWidget> createState() => _HomeGradesScreen();
}

String activeSubjectUid = "";

class _HomeGradesScreen extends State<HomeGradesScreen> {
  ApiResponse<List<Grade>>? grades;
  ApiResponse<List<Lesson>>? week;

  @override
  void didUpdateWidget(HomeGradesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.updateNotifier.removeListener(updateListener);
    widget.updateNotifier.addListener(updateListener);
  }

  void updateListener() async {
    var now = timeNow();
    var start = now.subtract(Duration(days: now.weekday - 1));
    var end = start.add(Duration(days: 6));

    grades = await widget.data.client.getGrades(forceCache: false);
    week = await widget.data.client.getTimeTable(start, end, forceCache: false);

    if (mounted) setState(() {});

    widget.finishNotifier.update();
  }

  @override
  void initState() {
    super.initState();

    widget.updateNotifier.addListener(updateListener);

    (() async {
      var now = timeNow();
      var start = now.subtract(Duration(days: now.weekday - 1));
      var end = start.add(Duration(days: 6));

      grades = await widget.data.client.getGrades();
      week = await widget.data.client.getTimeTable(start, end);

      if (mounted) setState(() {});
    })();
  }

  @override
  void dispose() {
    super.dispose();
    widget.updateNotifier.removeListener(updateListener);
  }

  @override
  Widget build(BuildContext context) {
    if (grades == null || week == null) {
     return SizedBox(
        height: MediaQuery.of(context).size.height / 1.35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            DelayedSpinnerWidget(),
            SizedBox(),
          ],
        ),
      );
    } else {
      var subjectAvg = 0.00;
      var subjectCount = 0;
      var subjectAvgRounded = 0.00;
      final List<Subject> subjects = List<Subject>.empty(growable: true);
      final List<Widget> gradeCards = [];

      for (var grade in grades!.response!) {
        if (subjects.where((s) => s.uid == grade.subject.uid).isEmpty) {
          subjects.add(grade.subject);
        }
      }

      subjects.sort((s1, s2) => s1.name.compareTo(s2.name));

      for (var subject in subjects) {
        for (var grade in grades!.response!) {
          if (grade.subject.uid != subject.uid) continue;

          if (grade.valueType.name == "Szazalekos") {
            grade.valueType = NameUidDesc(
                uid: "1,Osztalyzat", name: "Osztalyzat", description: "");
            if (grade.numericValue != null) {
              grade.numericValue = percentageToGrade(grade.numericValue!);
            }
          }
        }
        var avg = grades!.response!.getAverageBySubject(subject);

        if (avg.isNaN) {
          gradeCards.add(GradeSmallCard(grades!.response!, subject));
        } else {
          gradeCards.add(GestureDetector(
            child: GradeSmallCard(grades!.response!, subject),
            onTap: () {
              activeSubjectUid = subject.uid;

              widget.pageController(1);
            },
          ));
        }

        if (!avg.isNaN) {
          subjectCount++;
          subjectAvg += avg;
          subjectAvgRounded += roundGrade(avg);
        }
      }

      subjectAvg /= subjectCount;
      subjectAvgRounded /= subjectCount;

      if (subjectCount == 0) {
        subjectAvg = 0.00;
        subjectAvgRounded = 0.00;
      }

      var subjectAvgColor = getGradeColor(subjectAvg);

      return Scaffold(
            backgroundColor: appStyle.colors.background, body: Padding(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 12.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.data.l10n.subjects,
                  style: appStyle.fonts.H_H2
                      .apply(color: appStyle.colors.textPrimary),
                )
              ],
            ),
            SizedBox(height: 16), // TODO: Add graphs here
            // ...gradeCards,
            SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  240,
              child: ListView(
                children: [
                  Text(
                    widget.data.l10n.your_subjects,
                    style: appStyle.fonts.H_14px
                        .apply(color: appStyle.colors.textSecondary),
                  ),
                  SizedBox(height: 16),
                  ...gradeCards,
                  SizedBox(height: 16),
                  Text(
                    widget.data.l10n.data,
                    style: appStyle.fonts.B_16SB
                        .apply(color: appStyle.colors.textSecondary),
                  ),
                  SizedBox(height: 16),
                  FirkaCard(
                    left: [
                      Text(
                        widget.data.l10n.subject_avg,
                        style: appStyle.fonts.B_16SB
                            .apply(color: appStyle.colors.textPrimary),
                      ),
                    ],
                    right: [
                      Card(
                        shadowColor: Colors.transparent,
                        color: subjectAvgColor.withAlpha(38),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 8, right: 8, top: 4, bottom: 4),
                          child: Text(
                            subjectAvg.toStringAsFixed(2),
                            style: appStyle.fonts.B_16SB
                                .apply(color: subjectAvgColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  FirkaCard(
                    left: [
                      Text(
                        widget.data.l10n.subject_avg_rounded,
                        style: appStyle.fonts.B_16SB
                            .apply(color: appStyle.colors.textPrimary),
                      ),
                    ],
                    right: [
                      Card(
                        shadowColor: Colors.transparent,
                        color: subjectAvgColor.withAlpha(38),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 8, right: 8, top: 4, bottom: 4),
                          child: Text(
                            subjectAvgRounded.toStringAsFixed(2),
                            style: appStyle.fonts.B_16SB
                                .apply(color: subjectAvgColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  FirkaCard(left: [
                    Text(
                      widget.data.l10n.class_avg,
                      style: appStyle.fonts.B_16SB
                          .apply(color: appStyle.colors.textPrimary),
                    ),
                  ]),
                  FirkaCard(
                    left: [
                      Text(
                        widget.data.l10n.class_n,
                        style: appStyle.fonts.B_16SB
                            .apply(color: appStyle.colors.textPrimary),
                      ),
                    ],
                    right: [
                      Text(
                        week!.response!
                            .where((lesson) =>
                                lesson.type.name != TimetableConsts.event)
                            .length
                            .toString(),
                        style: appStyle.fonts.B_14SB
                            .apply(color: appStyle.colors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }
  }
}
