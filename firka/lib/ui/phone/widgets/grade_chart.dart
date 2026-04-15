import 'dart:math' as math;
import 'package:firka/app/app_state.dart';
import 'package:firka/core/settings.dart';
import 'package:firka_common/firka_common.dart';
import 'package:intl/intl.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/routing/chart_interaction_scope.dart';
import 'package:firka/ui/components/grade_helpers.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GradeChart extends StatefulWidget {
  final List<Grade> grades;
  const GradeChart({super.key, required this.grades});

  @override
  State<GradeChart> createState() => _GradeChartState();
}

class DateSpot extends FlSpot {
  final DateTime date;

  const DateSpot(super.x, super.y, this.date);
}

class _GradeChartState extends State<GradeChart> {
  double? _tooltipY;
  int? _touchedIndex;
  DateFormat tooltipFormat = DateFormat("MM.dd.");

  late List<DateSpot> spots;

  double? _subjectAverageInList(List<Grade> grades, String subjectUid) {
    double weightedSum = 0;
    double totalWeight = 0;
    for (final g in grades) {
      if (g.subject.uid != subjectUid) continue;
      final name = g.valueType.name?.toLowerCase() ?? '';
      final isPercentage =
          name.contains('szazalek') || name.contains('percent');
      if (isPercentage) continue;
      final v = g.numericValue;
      final w = g.weightPercentage;
      if (v != null && w != null) {
        final effectiveValue = g.valueType.name == "Szazalekos"
            ? percentageToGrade(v).toDouble()
            : v.toDouble();
        weightedSum += effectiveValue * w;
        totalWeight += w;
      }
    }
    return totalWeight > 0 ? weightedSum / totalWeight : null;
  }

  double _runningSubjectAverage(List<Grade> sortedGrades, int upToInclusive) {
    final sublist = sortedGrades.sublist(
      0,
      (upToInclusive + 1).clamp(0, sortedGrades.length),
    );
    final subjectUids = sublist.map((g) => g.subject.uid).toSet();
    double sum = 0;
    int count = 0;
    for (final uid in subjectUids) {
      final avg = _subjectAverageInList(sublist, uid);
      if (avg != null) {
        sum += avg;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  @override
  void initState() {
    super.initState();
    _computeSpots();
  }

  void _computeSpots() {
    final sortedGrades =
        widget.grades
            .where(
              (grade) =>
                  grade.numericValue != null && grade.weightPercentage != null,
            )
            .toList()
          ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    if (sortedGrades.isEmpty) {
      spots = [DateSpot(0, 0, DateTime.now()), DateSpot(1, 0, DateTime.now())];
      return;
    }

    if (sortedGrades.length == 1) {
      sortedGrades.insert(0, sortedGrades[0]);
    }

    spots = [];
    for (var i = 0; i < sortedGrades.length; i++) {
      final partialAvg = _runningSubjectAverage(sortedGrades, i);
      spots.add(DateSpot(i.toDouble(), partialAvg, sortedGrades[i].recordDate));
    }
  }

  List<FlSpot> _smoothSpots(List<FlSpot> input) {
    if (input.length < 3) return input;

    final smoothed = <FlSpot>[];
    for (var i = 0; i < input.length; i++) {
      if (i == 0 || i == input.length - 1) {
        smoothed.add(input[i]);
        continue;
      }

      final prev = input[i - 1].y;
      final curr = input[i].y;
      final next = input[i + 1].y;
      final blended = (0.25 * prev) + (0.5 * curr) + (0.25 * next);

      smoothed.add(FlSpot(input[i].x, blended));
    }

    return smoothed;
  }

  @override
  void didUpdateWidget(covariant GradeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grades.length != widget.grades.length) {
      _computeSpots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FirkaCard.single(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(aspectRatio: 1.82, child: LineChart(avgData())),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final firstX = spots.first.x.toInt();
    final lastX = spots.last.x.toInt();
    String content = '';

    final shouldHideNow =
        _touchedIndex != null &&
        meta.parentAxisSize / lastX * _touchedIndex! > meta.parentAxisSize - 62;

    if (value == _touchedIndex) {
      final date = spots[_touchedIndex!].date;
      content = tooltipFormat.format(date);
    } else if (value == firstX) {
      content = 'Szeptember';
    } else if (value == lastX && !shouldHideNow) {
      content = 'Most';
    }

    final text = Text(
      content,
      style: appStyle.fonts.B_12R.apply(color: appStyle.colors.textSecondary),
    );

    return SideTitleWidget(
      meta: meta,
      space: 0,
      fitInside: SideTitleFitInsideData.fromTitleMeta(
        meta,
        distanceFromEdge: value == lastX ? 12 : 0,
      ),
      child: value == _touchedIndex
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: ShapeDecoration(
                color: appStyle.colors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
              child: text,
            )
          : text,
    );
  }

  Widget buildCircle({
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Material(
        shape: const CircleBorder(),
        color: bgColor,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: appStyle.fonts.B_14SB.fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  Color colorForY(double y) {
    final rounding = initData.settings
        .group("settings")
        .subGroup("application")
        .subGroup("rounding");
    return y == 0
        ? appStyle.colors.card
        : getGradeColor(
            y,
            t1: rounding.dbl("1"),
            t2: rounding.dbl("2"),
            t3: rounding.dbl("3"),
            t4: rounding.dbl("4"),
          );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    if (value == 0) {
      return SizedBox();
    }

    final rounding = initData.settings
        .group("settings")
        .subGroup("application")
        .subGroup("rounding");
    final currentValue = spots.first.y == 0
        ? 0
        : roundGrade(
            _tooltipY ?? spots.first.y,
            t1: rounding.dbl("1"),
            t2: rounding.dbl("2"),
            t3: rounding.dbl("3"),
            t4: rounding.dbl("4"),
          );
    final isActive = value == currentValue;

    if (isActive) {
      final gradeColor = getGradeColor(value);
      return buildCircle(
        text: value.toStringAsFixed(0),
        bgColor: gradeColor.withAlpha(38),
        textColor: gradeColor,
      );
    }

    return buildCircle(
      text: value.toStringAsFixed(0),
      bgColor: appStyle.colors.card,
      textColor: appStyle.colors.textTertiary,
    );

    // return Text(text, style: style, textAlign: TextAlign.left);
  }

  LineChartData avgData() {
    final smoothedSpots = _smoothSpots(spots);

    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchSpotThreshold: 1000,
        enabled: true,
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          setState(() {
            if (event.isInterestedForInteractions) {
              _touchedIndex = response!.lineBarSpots!.first.spotIndex;
              _tooltipY = spots[_touchedIndex!].y;
              if (_tooltipY! > 0) {
                return;
              }
            }
            _tooltipY = null;
            _touchedIndex = null;
          });
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipMargin: 4,
          getTooltipColor: (touchedSpot) => appStyle.colors.buttonSecondaryFill,
          tooltipBorderRadius: BorderRadius.circular(27),
          tooltipPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          fitInsideHorizontally: true,

          showOnTopOfTheChartBoxArea: false,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              if (touchedSpot.y == 0) {
                return null;
              }
              final spot = spots[touchedSpot.spotIndex];
              final textStyle = appStyle.fonts.B_14SB.apply(
                color: colorForY(spot.y),
              );
              return LineTooltipItem(spot.y.toStringAsFixed(2), textStyle);
            }).toList();
          },
        ),
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            final touchedSpot = spots[index];
            return TouchedSpotIndicatorData(
              FlLine(color: colorForY(touchedSpot.y), strokeWidth: 3),
              FlDotData(show: false),
            );
          }).toList();
        },
      ),
      backgroundColor: Colors.transparent,
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 5,
            color: const Color(0xFFC8C8C8),
            strokeWidth: 1.0,
            dashArray: [8, 12],
          ),
        ],
        extraLinesOnTop: false,
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xFFC8C8C8),
            strokeWidth: 1.0,
            dashArray: [8, 12],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: bottomTitleWidgets,
            interval: 1,
          ),
          drawBelowEverything: false,
          sideTitleAlignment: SideTitleAlignment.inside,
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 26,
            interval: 1,
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            getTitlesWidget: (v, meta) => SizedBox(),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),

      minY: 0,
      maxY: 5,

      lineBarsData: [
        LineChartBarData(
          spots: smoothedSpots,
          isCurved: true,
          curveSmoothness: 0.5,
          showingIndicators: _touchedIndex != null ? [_touchedIndex!] : [],
          gradient: LinearGradient(
            colors: [for (final s in smoothedSpots) colorForY(s.y)],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                for (final s in smoothedSpots)
                  colorForY(s.y).withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Wraps [GradeChart] with a [Listener] that updates [ChartInteractionScope]
/// so the navigator does not intercept touch/drag (e.g. for swipe back).
class GradeChartWithInteraction extends StatelessWidget {
  final List<Grade> grades;

  const GradeChartWithInteraction({super.key, required this.grades});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => ChartInteractionScope.of(context).value = true,
      onPointerUp: (_) => ChartInteractionScope.of(context).value = false,
      onPointerCancel: (_) => ChartInteractionScope.of(context).value = false,
      child: GradeChart(grades: grades),
    );
  }
}
