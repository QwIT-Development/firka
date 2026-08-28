import 'package:firka/ui/phone/widgets/grade_summary_bar.dart';
import 'package:firka/ui/phone/widgets/info_card.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/ui/components/common_bottom_sheets.dart';
import 'package:firka/ui/components/firka_icon_button.dart';
import 'package:firka/ui/phone/widgets/grade_chart.dart';
import 'package:firka/ui/shared/class_icon.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar_community/isar.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/last_seen_helper.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/ui/theme/style.dart';

class HomeGradesSubjectScreen extends StatefulWidget {
  final SubjectCacheModel subject;
  final String teacherName;
  final Iterable<GradeCacheModel> grades;

  factory HomeGradesSubjectScreen.subject(SubjectCacheModel subject) {
    return HomeGradesSubjectScreen(
      subject,
      LastSeenHelper.openedGrades(
        initData.settings.selectedAccountKey,
        initData.client!.cache
            .getGrades()
            .subject((s) => s.cacheKeyEqualTo(subject.cacheKey))
            .sortByCreatedAtDesc()
            .findAllSync(),
      ),
    );
  }

  HomeGradesSubjectScreen(this.subject, this.grades, {super.key})
    : teacherName = subject.teachers
          .loadAndGet()
          .map((t) => "${t.name} (${t.classGroup.loadAndGet()!.type})")
          .join("\n");

  @override
  State<StatefulWidget> createState() => _HomeGradesSubjectScreen();
}

class _HomeGradesSubjectScreen extends FirkaState<HomeGradesSubjectScreen> {
  final List<(int grade, int weight)> _ghostEntries = [];

  List<GradeCacheModel> _gradesWithGhosts() {
    final real = widget.grades.toList();
    if (_ghostEntries.isEmpty) return real;
    final baseDate = real.isEmpty
        ? DateTime.now()
        : real.map((g) => g.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
    for (var i = 0; i < _ghostEntries.length; i++) {
      final e = _ghostEntries[i];
      real.add(
        GradeCacheModel()
          ..type = "Ertekeles"
          ..valueType = "Osztalyzat"
          ..writtenAt = baseDate.add(Duration(seconds: i))
          ..numericValue = e.$1
          ..weightPercentage = e.$2
          ..textValue = e.$1.toString()
          ..teacherName = widget
              .teacherName // TODO: teacher name
          ..subject.value = widget.subject,
      );
    }
    return real;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeRefreshCubit, HomeRefreshState>(
      listenWhen: (previous, current) =>
          current.refreshTrigger != previous.refreshTrigger,
      listener: (context, state) {
        setState(() => {});
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.grades.isEmpty) {
      return Container(
        color: appStyle.colors.background,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Transform.translate(
                  offset: const Offset(-4, 0),
                  child: GestureDetector(
                    child: FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.chevronLeftLine,
                      color: appStyle.colors.textSecondary,
                    ),
                    onTap: () {
                      context.pop();
                    },
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-4, 1),
                  child: Text(
                    initData.l10n.subjects,
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    shadowColor: const Color.fromRGBO(0, 0, 0, 0),
                    color: appStyle.colors.a15p,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(6),
                      child: ClassIconWidget(
                        subject: widget.subject,
                        color: appStyle.colors.accent,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.subject.name,
                    style: appStyle.fonts.H_H2.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    initData.l10n.unknown_teacher,
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            "assets/images/logos/dave.svg",
                            width: 48,
                            height: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            initData.l10n.no_grades,
                            style: appStyle.fonts.B_16R.apply(
                              color: appStyle.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final ghostGradeWidgets = _ghostEntries.indexed
        .map((e) {
          return InfoCard.gradeGhost(
            e.$2.$1,
            e.$2.$2,
            onTap: (ctx) {
              setState(() {
                _ghostEntries.removeAt(e.$1);
              });
            },
          );
        })
        .toList()
        .reversed;

    return Container(
      color: appStyle.colors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-4, 0),
                    child: GestureDetector(
                      child: FirkaIconWidget(
                        FirkaIconType.majesticons,
                        Majesticon.chevronLeftLine,
                        color: appStyle.colors.textSecondary,
                      ),
                      onTap: () {
                        context.pop();
                      },
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-4, 0),
                    child: Text(
                      initData.l10n.subjects,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              FirkaIconButton(
                onTap: () {
                  showSubjectBottomSheetSettings(
                    context,
                    initData,
                    widget.subject,
                    onAddFromCalculator: (g, w) {
                      setState(() => _ghostEntries.add((g, w)));
                    },
                  );
                },
                child: FirkaIconWidget(
                  FirkaIconType.majesticons,
                  Majesticon.menuSolid,
                  size: 20.0,
                  color: appStyle.colors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledCircle(
                      diameter: 36,
                      color: appStyle.colors.a15p,
                      child: ClassIconWidget(
                        subject: widget.subject,
                        color: appStyle.colors.accent,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.subject.name,
                      style: appStyle.fonts.H_H2.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.teacherName,
                      textAlign: TextAlign.center,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                GradeChartWithInteraction(grades: _gradesWithGhosts()),
                SizedBox(height: 10),
                GradeSummaryBar(
                  grades: _gradesWithGhosts(),
                  l10n: initData.l10n,
                  showAverage: ghostGradeWidgets.isNotEmpty,
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 20,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        if (ghostGradeWidgets.isNotEmpty)
                          Text(
                            initData.l10n.ghost_grades,
                            style: appStyle.fonts.B_16R.apply(
                              color: appStyle.colors.textSecondary,
                            ),
                          ),
                        ...ghostGradeWidgets,
                      ],
                    ),
                    ...widget.grades
                        .groupList((e) => e.writtenAt)
                        .entries
                        .map(
                          (e) => Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key.format(initData.l10n, FormatMode.main),
                                style: appStyle.fonts.B_16R.apply(
                                  color: appStyle.colors.textSecondary,
                                ),
                              ),
                              ...e.value.map((v) => InfoCard.gradeDesc(v)),
                            ],
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
