import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/api/model/generic.dart';
import 'package:firka/core/average_helper.dart';
import 'package:firka/routing/chart_interaction_scope.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/ui/components/grade_helpers.dart';
import 'package:firka/ui/phone/widgets/grade_chart.dart';
import 'package:firka/ui/phone/widgets/grade_summary_bar.dart';
import 'package:firka/ui/shared/grade_small_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:firka/api/consts.dart';
import 'package:firka/api/model/class_group.dart';
import 'package:firka/api/model/grade.dart';
import 'package:firka/api/model/subject.dart';
import 'package:firka/api/model/timetable.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/delayed_spinner.dart';

class HomeGradesScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeGradesScreen(this.data, {super.key});

  @override
  State<StatefulWidget> createState() => _HomeGradesScreen();
}

String activeSubjectUid = "";
String subjectName = "";
String subjectId = "";
String subjectCategory = "";
List<Subject> subjectInfo = [];

class _HomeGradesScreen extends FirkaState<HomeGradesScreen> {
  ApiResponse<List<Grade>>? grades;
  ApiResponse<List<Lesson>>? week;
  ApiResponse<List<ClassGroup>>? classGroups;
  ApiResponse<List<SubjectAverage>>? lessons;

  void _onRefreshRequested(BuildContext context) async {
    final cubit = context.read<HomeRefreshCubit>();
    var now = timeNow();
    var start = now.subtract(Duration(days: now.weekday - 1));
    var end = start.add(Duration(days: 6));

    grades = await widget.data.client.getGrades(forceCache: false);
    week = await widget.data.client.getTimeTable(start, end, forceCache: false);
    classGroups = await widget.data.client.getClassGroups(forceCache: false);
    if (classGroups?.response?.isNotEmpty ?? false) {
      var group = classGroups!.response!.first;
      lessons = await widget.data.client.getSubjectAverage(
        group,
        forceCache: false,
      );
      await Future.delayed(Duration(milliseconds: 100));
    }
    if (mounted) {
      setState(() {});
      cubit.onRefreshComplete();
    }
  }

  @override
  void initState() {
    super.initState();

    (() async {
      var now = timeNow();
      var start = now.subtract(Duration(days: now.weekday - 1));
      var end = start.add(Duration(days: 6));

      grades = await widget.data.client.getGrades();
      week = await widget.data.client.getTimeTable(start, end);
      classGroups = await widget.data.client.getClassGroups();
      if (classGroups?.response?.isNotEmpty ?? false) {
        var group = classGroups!.response!.first;
        lessons = await widget.data.client.getSubjectAverage(group);
        await Future.delayed(Duration(milliseconds: 100));
      }
      if (mounted) setState(() {});
    })();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeRefreshCubit, HomeRefreshState>(
      listenWhen: (previous, current) =>
          current.refreshTrigger != previous.refreshTrigger,
      listener: (context, state) {
        _onRefreshRequested(context);
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (grades == null || week == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height / 1.35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [SizedBox(), DelayedSpinnerWidget(), SizedBox()],
        ),
      );
    } else {
      var subjectAvg = 0.00;
      var subjectCount = 0;
      var subjectAvgRounded = 0.00;
      final summaryAvg2 = calculateAverage(grades!.response!);
      final List<Subject> subjects = List<Subject>.empty(growable: true);
      final List<Widget> gradeCards = [];

      for (var grade in grades!.response!) {
        if (subjects.where((s) => s.uid == grade.subject.uid).isEmpty) {
          subjects.add(grade.subject);
        }
      }

      if (lessons != null && lessons!.response != null) {
        for (var lesson in lessons!.response!) {
          if (subjects.where((s) => s.uid == lesson.uid).isEmpty) {
            subjects.add(
              Subject(
                uid: lesson.uid,
                name: lesson.name,
                category: NameUidDesc(
                  uid: lesson.subjectCategoryId,
                  name: lesson.subjectCategoryName,
                  description: lesson.subjectCategoryDescription,
                ),
                sortIndex: lesson.sortIndex,
              ),
            );
          }
        }
      }

      subjects.sort((s1, s2) => s1.name.compareTo(s2.name));

      for (var subject in subjects) {
        final subjectGrades = grades!.response!
            .where((g) => g.subject.uid == subject.uid)
            .toList();

        double avg = double.nan;
        if (subjectGrades.isNotEmpty) {
          for (var grade in subjectGrades) {
            if (grade.valueType.name == "Szazalekos") {
              grade.valueType = NameUidDesc(
                uid: "1,Osztalyzat",
                name: "Osztalyzat",
                description: "",
              );
              if (grade.numericValue != null) {
                grade.numericValue = percentageToGrade(grade.numericValue!);
              }
            }
          }
          avg = grades!.response!.getAverageBySubject(subject);
        }

        if (avg.isNaN) {
          gradeCards.add(
            GestureDetector(
              child: GradeSmallCard(grades!.response!, subject),
              onTap: () {
                activeSubjectUid = subject.uid;
                subjectName = subject.name;
                subjectId = subject.uid;
                subjectCategory = subject.category.name!;
                subjectInfo = subjects
                    .where((s) => s.uid == subject.uid)
                    .toList();
                context.go('/grades/subject/${subject.uid}');
              },
            ),
          );
        } else {
          gradeCards.add(
            GestureDetector(
              child: GradeSmallCard(grades!.response!, subject),
              onTap: () {
                activeSubjectUid = subject.uid;
                subjectName = subject.name;
                subjectId = subject.uid;
                subjectCategory = subject.category.name!;
                subjectInfo = subjects
                    .where((s) => s.uid == subject.uid)
                    .toList();
                context.go('/grades/subject/${subject.uid}');
              },
            ),
          );
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

      return Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.data.l10n.subjects,
                  style: appStyle.fonts.H_H2.apply(
                    color: appStyle.colors.textPrimary,
                  ),
                ),
              ],
            ),
            // SizedBox(height: 16), // TODO: Add graphs here
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) =>
                  ChartInteractionScope.of(context).value = true,
              onPointerUp: (_) =>
                  ChartInteractionScope.of(context).value = false,
              onPointerCancel: (_) =>
                  ChartInteractionScope.of(context).value = false,
              child: GradeChart(grades: grades?.response ?? []),
            ),
            SizedBox(height: 2),
            GradeSummaryBar(
              grades: grades?.response ?? [],
              l10n: widget.data.l10n,
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    widget.data.l10n.your_subjects,
                    style: appStyle.fonts.H_14px.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16),
                  ...gradeCards,
                  SizedBox(height: 16),
                  Text(
                    widget.data.l10n.data,
                    style: appStyle.fonts.B_16SB.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16),
                  FirkaCard(
                    left: [
                      Text(
                        widget.data.l10n.subject_avg,
                        style: appStyle.fonts.B_16SB.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ],
                    right: [
                      Card(
                        shadowColor: Colors.transparent,
                        color: subjectAvgColor.withAlpha(38),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Text(
                            subjectAvg.toStringAsFixed(2),
                            style: appStyle.fonts.B_16SB.apply(
                              color: subjectAvgColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  FirkaCard(
                    left: [
                      Text(
                        widget.data.l10n.subject_avg_rounded,
                        style: appStyle.fonts.B_16SB.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ],
                    right: [
                      Card(
                        shadowColor: Colors.transparent,
                        color: subjectAvgColor.withAlpha(38),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Text(
                            subjectAvgRounded.toStringAsFixed(2),
                            style: appStyle.fonts.B_16SB.apply(
                              color: subjectAvgColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  FirkaCard(
                    left: [
                      Text(
                        "Összesített átlag",
                        style: appStyle.fonts.B_16SB.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ],
                    right: [
                      Card(
                        shadowColor: Colors.transparent,
                        color: subjectAvgColor.withAlpha(38),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Text(
                            summaryAvg2.toStringAsFixed(2),
                            style: appStyle.fonts.B_16SB.apply(
                              color: subjectAvgColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  FirkaCard(
                    left: [
                      Text(
                        widget.data.l10n.class_avg,
                        style: appStyle.fonts.B_16SB.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  FirkaCard(
                    left: [
                      Text(
                        widget.data.l10n.class_n,
                        style: appStyle.fonts.B_16SB.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ],
                    right: [
                      Text(
                        week!.response!
                            .where(
                              (lesson) =>
                                  lesson.type.name != TimetableConsts.event,
                            )
                            .length
                            .toString(),
                        style: appStyle.fonts.B_16SB.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
