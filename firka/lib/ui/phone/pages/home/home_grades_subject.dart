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

  const HomeGradesSubjectScreen(this.data, {super.key});

  @override
  State<StatefulWidget> createState() => _HomeGradesSubjectScreen();
}

class _HomeGradesSubjectScreen extends FirkaState<HomeGradesSubjectScreen> {
  Iterable<Grade>? grades;

  void _onRefreshRequested(BuildContext context) async {
    final cubit = context.read<HomeRefreshCubit>();
    grades = (await widget.data.client.getGrades(forceCache: false)).response!
        .where((grade) => grade.subject.uid == activeSubjectUid)
        .where((grade) => grade.type.name != "felevi_jegy_ertekeles");

    if (mounted) {
      setState(() {});
      cubit.onRefreshComplete();
    }
  }

  @override
  void initState() {
    super.initState();

    (() async {
      grades = (await widget.data.client.getGrades()).response!
          .where((grade) => grade.subject.uid == activeSubjectUid)
          .where((grade) => grade.type.name != "felevi_jegy_ertekeles");

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
    if (grades != null && grades!.isNotEmpty && activeSubjectUid != "") {
      var aGrade = grades!.first;
      var groups = grades!.groupList((grade) => grade.recordDate);

      var gradeWidgets = List<Widget>.empty(growable: true);

      for (var group in groups.entries) {
        gradeWidgets.add(SizedBox(height: 8));
        gradeWidgets.add(
          Text(
            group.key.format(widget.data.l10n, FormatMode.grades),
            style: appStyle.fonts.H_14px.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        );
        gradeWidgets.add(SizedBox(height: 8));
        for (var grade in group.value) {
          gradeWidgets.add(
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
                            child: Text(
                              (grade.topic ?? grade.type.description!)
                                  .firstUpper(),
                              style: appStyle.fonts.B_16SB.apply(
                                color: appStyle.colors.textPrimary,
                              ),
                            ),
                          ),
                          grade.mode?.description != null
                              ? SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 1.45,
                                  child: Text(
                                    grade.mode!.description!.firstUpper(),
                                    style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textSecondary,
                                    ),
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                showGradeBottomSheet(context, widget.data, grade);
              },
            ),
          );
        }
      }

      return Material(
        color: appStyle.colors.background,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              Column(
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
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    Column(
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
                              uid: aGrade.subject.uid,
                              className: aGrade.subject.name,
                              category: aGrade.subject.category.name!,
                              color: appStyle.colors.accent,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          aGrade.subject.name,
                          style: appStyle.fonts.H_H2.apply(
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          aGrade.teacher,
                          style: appStyle.fonts.B_16R.apply(
                            color: appStyle.colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 15),
                      ],
                    ),
                    GradeChartWithInteraction(grades: grades?.toList() ?? []),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: gradeWidgets,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Material(
        color: appStyle.colors.background,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    230,
                child: ListView(
                  children: [
                    Column(
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
                              uid: subjectId,
                              className: subjectName,
                              category: subjectCategory,
                              color: appStyle.colors.accent,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          subjectName,
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
                      ],
                    ),
                    SizedBox(
                      height:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          320,
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
        ),
      );
    }
  }
}
