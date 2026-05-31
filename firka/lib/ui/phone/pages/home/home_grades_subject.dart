import 'package:firka/ui/phone/widgets/grade_summary_bar.dart';
import 'package:firka/ui/phone/widgets/info_card.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/ui/components/common_bottom_sheets.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/ui/components/grade.dart';
import 'package:firka/ui/phone/pages/home/home_grades.dart';
import 'package:firka/ui/phone/widgets/grade_chart.dart';
import 'package:firka/ui/shared/class_icon.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/ui/theme/style.dart';

class HomeGradesSubjectScreen extends StatefulWidget {
  final AppInitialization data;
  final Subject subject;

  const HomeGradesSubjectScreen(this.subject, this.data, {super.key});

  @override
  State<StatefulWidget> createState() => _HomeGradesSubjectScreen();
}

class _HomeGradesSubjectScreen extends FirkaState<HomeGradesSubjectScreen> {
  Iterable<Grade>? grades;
  final List<(int grade, int weight)> _ghostEntries = [];

  void _onRefreshRequested(BuildContext context) async {
    final cubit = context.read<HomeRefreshCubit>();
    grades = (await widget.data.client.getGrades(
      forceCache: false,
    )).response!.where((grade) => grade.subject.uid == widget.subject.uid);

    if (mounted) {
      setState(() {});
      cubit.onRefreshComplete();
    }
  }

  @override
  void initState() {
    super.initState();

    (() async {
      grades = (await widget.data.client.getGrades()).response!.where(
        (grade) => grade.subject.uid == widget.subject.uid,
      );

      if (mounted) setState(() {});
    })();
  }

  List<Grade> _gradesWithGhosts(Subject subject) {
    final real = grades?.toList() ?? [];
    if (_ghostEntries.isEmpty) return real;
    final baseDate = real.isEmpty
        ? DateTime.now()
        : real
              .map((g) => g.creationDate)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    final osztalyzat = NameUidDesc(
      uid: '1,Osztalyzat',
      name: 'Osztalyzat',
      description: '',
    );
    final ghostGrades = <Grade>[];
    for (var i = 0; i < _ghostEntries.length; i++) {
      final e = _ghostEntries[i];
      ghostGrades.add(
        Grade(
          uid: 'ghost-$i-${e.$1}-${e.$2}',
          recordDate: baseDate.add(Duration(seconds: i)),
          creationDate: baseDate.add(Duration(seconds: i)),
          subject: subject,
          type: osztalyzat,
          valueType: osztalyzat,
          teacher: '',
          strValue: '${e.$1}',
          sortIndex: 0,
          numericValue: e.$1,
          weightPercentage: e.$2,
        ),
      );
    }
    return [...real, ...ghostGrades];
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
    if (grades == null || grades!.isEmpty) {
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
                    widget.data.l10n.subjects,
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
                      child: ClassIconWidget.subject(
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
                    widget.data.l10n.unknown_teacher,
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
                            widget.data.l10n.no_grades,
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
    var aGrade = grades!.first;

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
                      widget.data.l10n.subjects,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                child: Card(
                  color: appStyle.colors.buttonSecondaryFill,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.menuSolid,
                      size: 26.0,
                      color: appStyle.colors.accent,
                    ),
                  ),
                ),
                onTap: () {
                  showSubjectBottomSheetSettings(
                    context,
                    widget.data,
                    aGrade.subject,
                    onAddFromCalculator: (g, w) {
                      setState(() => _ghostEntries.add((g, w)));
                    },
                  );
                },
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
                      child: ClassIconWidget.subject(
                        subject: aGrade.subject,
                        color: appStyle.colors.accent,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      aGrade.subject.name,
                      style: appStyle.fonts.H_H2.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      aGrade.teacher,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                GradeChartWithInteraction(
                  grades: _gradesWithGhosts(aGrade.subject),
                ),
                SizedBox(height: 10),
                GradeSummaryBar(
                  grades: _gradesWithGhosts(aGrade.subject),
                  l10n: widget.data.l10n,
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
                    ...grades!
                        .groupList((e) => e.recordDate)
                        .entries
                        .map(
                          (e) => Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key.format(widget.data.l10n, FormatMode.main),
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
