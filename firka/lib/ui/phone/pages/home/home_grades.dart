import 'dart:collection';

import 'package:firka/core/extensions.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/ui/components/grade_helpers.dart';
import 'package:firka/ui/phone/widgets/grade_chart.dart';
import 'package:firka/ui/phone/widgets/grade_summary_bar.dart';
import 'package:firka/ui/shared/grade_small_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:firka/api/consts.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/delayed_spinner.dart';

class HomeGradesScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeGradesScreen(this.data, {super.key});

  @override
  State<StatefulWidget> createState() => _HomeGradesScreen();
}

class _HomeGradesScreen extends FirkaState<HomeGradesScreen> {
  ApiResponse<List<Grade>>? grades;
  ApiResponse<List<Lesson>>? week;
  ApiResponse<List<ClassGroup>>? classGroups;
  ApiResponse<List<SubjectAverage>>? lessons;
  ApiResponse<List<ClassGroupSubjectAverage>>? classAvgs;

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
      classAvgs = await widget.data.client.getClassGroupAverages(
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
        classAvgs = await widget.data.client.getClassGroupAverages(group);
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
    if (grades == null ||
        lessons == null ||
        classAvgs == null ||
        week == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height / 1.35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [SizedBox(), DelayedSpinnerWidget(), SizedBox()],
        ),
      );
    } else {
      final allGrades = grades!.response!;
      final allLessons = lessons!.response!;

      final subjectAverage = allGrades.getSubjectAverage();
      final classAverages = classAvgs!.response!
          .map((c) => c.classGroupAverage)
          .nonNulls;

      double? classAverage = classAverages.isNotEmpty
          ? classAverages.reduce((f, s) => f + s) / classAverages.length
          : null;

      final Set<Subject> subjects = HashSet(
        hashCode: (s) => s.uid.hashCode,
        equals: (s, s2) => s.uid == s2.uid,
      );
      final List<Widget> gradeCards = [];

      allGrades.map((g) => g.subject).forEach(subjects.add);
      allLessons.map((l) => l.subject).forEach(subjects.add);

      for (var subject
          in subjects.toList()..sort((s1, s2) => s1.name.compareTo(s2.name))) {
        gradeCards.add(
          GestureDetector(
            child: GradeSmallCard(
              allGrades,
              classAvgs!.response!
                  .firstWhereOrNull((s) => s.subject.uid == subject.uid)
                  ?.classGroupAverage,
              subject,
            ),
            onTap: () {
              context.go('/grades/subject', extra: subject);
            },
          ),
        );
      }

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
            SizedBox(height: 20),
            GradeChartWithInteraction(grades: allGrades),
            SizedBox(height: 10),
            GradeSummaryBar(grades: allGrades, l10n: widget.data.l10n),
            SizedBox(height: 20),
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
                  Column(
                    spacing: 16,
                    mainAxisSize: MainAxisSize.min,
                    children: gradeCards,
                  ),
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
                      if (subjectAverage != null)
                        Container(
                          width: 48,
                          height: 26,
                          decoration: ShapeDecoration(
                            color: getGradeColor(subjectAverage).withAlpha(38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              subjectAverage.toStringAsFixed(2),
                              style: appStyle.fonts.B_16R.apply(
                                color: getGradeColor(subjectAverage),
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
                    right: [
                      if (classAverage != null)
                        Container(
                          width: 48,
                          height: 26,
                          decoration: ShapeDecoration(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: getGradeColor(classAverage),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              classAverage.toStringAsFixed(2),
                              style: appStyle.fonts.B_16R.apply(
                                color: getGradeColor(classAverage),
                              ),
                            ),
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
