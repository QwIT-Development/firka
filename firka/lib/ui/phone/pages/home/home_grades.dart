import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/helpers/ui/grade_helpers.dart';
import 'package:firka/helpers/ui/stateless_async_widget.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:firka/ui/widget/grade_small_card.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/api/model/subject.dart';
import '../../../../helpers/debug_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../main.dart';
import '../../../model/style.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeGradesScreen extends StatelessAsyncWidget {
  final AppInitialization data;
  final void Function(ActiveHomePage) cb;

  const HomeGradesScreen(this.data, this.cb, {super.key});

  @override
  Future<Widget> buildAsync(BuildContext context) async {
    List<Color> gradientColors = [Colors.red, Colors.blue];
    var now = timeNow();
    var start = now.subtract(Duration(days: now.weekday - 1));
    var end = start.add(Duration(days: 6));

    var grades = await data.client.getGrades();
    var subjectAvg = 0.00;
    var week = await data.client.getTimeTable(start, end);
    final List<Subject> subjects = List<Subject>.empty(growable: true);
    final List<Widget> gradeCards = [];

    for (var grade in grades.response!) {
      if (subjects.where((s) => s.uid == grade.subject.uid).isEmpty) {
        subjects.add(grade.subject);
      }
    }

    subjects.sort((s1, s2) => s1.name.compareTo(s2.name));

    for (var subject in subjects) {
      for (var grade in grades.response!) {
        if (grade.subject.uid != subject.uid) continue;

        if (grade.valueType.name == "Szazalekos") {
          grade.valueType = NameUidDesc(
              uid: "1,Osztalyzat", name: "Osztalyzat", description: "");
          if (grade.numericValue != null) {
            grade.numericValue = percentageToGrade(grade.numericValue!);
          }
        }
      }
      var avg = grades.response!.getAverageBySubject(subject);

      if (avg.isNaN) {
        gradeCards.add(GradeSmallCard(grades.response!, subject));
      } else {
        gradeCards.add(GestureDetector(
          child: GradeSmallCard(grades.response!, subject),
          onTap: () {
            cb(ActiveHomePage(HomePages.grades, subPageUid: subject.uid));
          },
        ));
      }

      subjectAvg += roundGrade(avg);
    }

    subjectAvg /= subjects.length;

    var subjectAvgColor = getGradeColor(subjectAvg);

    var shader = await compileLineChartShader();

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.subjects,
                  style: appStyle.fonts.H_H2
                      .apply(color: appStyle.colors.textSecondary),
                )
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  230,
              child: ListView(
                children: [
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1,
                          verticalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return const FlLine(
                              color: Colors.green,
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return const FlLine(
                              color: Colors.green,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: bottomTitleWidgets,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: leftTitleWidgets,
                              reservedSize: 42,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: const Color(0xff37434d)),
                        ),
                        minX: 0,
                        maxX: 11,
                        minY: 0,
                        maxY: 6,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(2.6, 2),
                              FlSpot(4.9, 5),
                              FlSpot(6.8, 3.1),
                              FlSpot(8, 4),
                              FlSpot(9.5, 3),
                              FlSpot(11, 4),
                            ],
                            isCurved: false,
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: gradientColors,
                            ),
                            barWidth: 5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(
                              show: false,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: gradientColors
                                    .map(
                                        (color) => color.withValues(alpha: 0.3))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      shader!
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.your_subjects,
                    style: appStyle.fonts.H_14px
                        .apply(color: appStyle.colors.textSecondary),
                  ),
                  SizedBox(height: 16),
                  ...gradeCards,
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.data,
                    style: appStyle.fonts.B_16SB
                        .apply(color: appStyle.colors.textSecondary),
                  ),
                  SizedBox(height: 16),
                  FirkaCard(
                    left: [
                      Text(
                        AppLocalizations.of(context)!.subject_avg,
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
                  FirkaCard(left: [
                    Text(
                      AppLocalizations.of(context)!.class_avg,
                      style: appStyle.fonts.B_16SB
                          .apply(color: appStyle.colors.textPrimary),
                    ),
                  ]),
                  FirkaCard(
                    left: [
                      Text(
                        AppLocalizations.of(context)!.class_n,
                        style: appStyle.fonts.B_16SB
                            .apply(color: appStyle.colors.textPrimary),
                      ),
                    ],
                    right: [
                      Text(
                        week.response!.length.toString(),
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
      ),
    );
  }
}

Widget bottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  Widget text;
  switch (value.toInt()) {
    case 2:
      text = const Text('MAR', style: style);
      break;
    case 5:
      text = const Text('JUN', style: style);
      break;
    case 8:
      text = const Text('SEP', style: style);
      break;
    default:
      text = const Text('', style: style);
      break;
  }

  return SideTitleWidget(
    meta: meta,
    child: text,
  );
}

Widget leftTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );
  String text;
  switch (value.toInt()) {
    case 1:
      text = '10K';
      break;
    case 3:
      text = '30k';
      break;
    case 5:
      text = '50k';
      break;
    default:
      return Container();
  }

  return Text(text, style: style, textAlign: TextAlign.left);
}
