import 'dart:collection';

import 'package:firka/core/extensions.dart';
import 'package:firka_common/core/grade_helper.dart';
import 'package:firka_common/data/models/class_average_cache_model.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/core/grade_helper.dart';
import 'package:firka/ui/phone/widgets/grade_chart.dart';
import 'package:firka/ui/phone/widgets/grade_summary_bar.dart';
import 'package:firka/ui/shared/grade_small_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeRefreshCubit, HomeRefreshState>(
      listenWhen: (previous, current) =>
          current.refreshTrigger != previous.refreshTrigger,
      listener: (context, state) {
        setState(() {});
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final allGrades = widget.data.client!.cache.getGrades().findAllSync();

    final subjectAverage = allGrades.getSubjectAverage();
    final roundedSubjectAverage = allGrades.getRoundedSubjectAverage();
    final classAverages = widget.data.client!.cache
        .getClassAverages()
        .findAllSync();

    double? classAverage = classAverages.isNotEmpty
        ? classAverages.map((c) => c.classAverage).reduce((f, s) => f + s) /
              classAverages.length
        : null;

    final List<SubjectCacheModel> subjects = widget.data.client!.cache
        .getSubjects()
        .findAllSync();
    final List<Widget> gradeCards = [];

    for (var subject
        in subjects.toList()..sort((s1, s2) => s1.name.compareTo(s2.name))) {
      gradeCards.add(
        GestureDetector(
          child: GradeSmallCard(
            allGrades.getAverageBySubject(subject),
            subject.classAverage.loadAndGet()?.classAverage,
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
                      widget.data.l10n.subject_avg_rounded,
                      style: appStyle.fonts.B_16SB.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                  right: [
                    if (roundedSubjectAverage != null)
                      Container(
                        width: 48,
                        height: 26,
                        decoration: ShapeDecoration(
                          color: getGradeColor(
                            roundedSubjectAverage,
                          ).withAlpha(38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            roundedSubjectAverage.toStringAsFixed(2),
                            style: appStyle.fonts.B_16R.apply(
                              color: getGradeColor(roundedSubjectAverage),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (classAverage != null)
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
                /*
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
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }
}
