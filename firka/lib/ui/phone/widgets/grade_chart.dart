import 'package:firka/app/app_state.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka_common/core/grade_helper.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/ui/theme/style.dart';
import 'package:intl/intl.dart';
import 'package:firka/routing/chart_interaction_scope.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GradeChart extends StatefulWidget {
  final List<GradeCacheModel> grades;
  final bool halfYearFallback;
  final bool plotRawValues;
  GradeChart({
    super.key,
    required List<GradeCacheModel> grades,
    this.halfYearFallback = true,
    this.plotRawValues = false,
  }) : grades = grades.where((g) => g.hasClassicValue()).toList()
         ..sort((a, b) => a.writtenAt.compareTo(b.writtenAt));

  @override
  State<GradeChart> createState() => _GradeChartState();
}

class DateSpot extends FlSpot {
  final DateTime date;

  const DateSpot(super.x, super.y, this.date);

  DateSpot copyWithX(double x) {
    return DateSpot(x, y, date);
  }
}

class _GradeChartState extends State<GradeChart> {
  double? _tooltipY;
  int? _touchedIndex;
  DateFormat tooltipFormat = DateFormat("MM.dd.");

  late List<DateSpot> spots;

  @override
  void initState() {
    super.initState();
    _computeSpots();
  }

  void _computeSpots() {
    spots = [];
    if (!widget.plotRawValues) {
      for (var i = 0; i < widget.grades.length; i++) {
        final grade = widget.grades[i];
        if (!grade.shouldIncludeInAverage()) {
          continue;
        }

        final partialAvg = widget.grades
            .take(i + 1)
            .getSubjectAverage(halfYearFallback: widget.halfYearFallback);

        spots.add(
          DateSpot(spots.length.toDouble(), partialAvg!, grade.writtenAt),
        );
      }
    }

    if (spots.isEmpty) {
      for (final grade in widget.grades) {
        if (grade.hasClassicValue()) {
          spots.add(
            DateSpot(
              spots.length.toDouble(),
              grade.numericValue!.toDouble(),
              grade.writtenAt,
            ),
          );
        }
      }
    }

    if (spots.isEmpty) {
      spots.add(DateSpot(0, 0, DateTime.now()));
    }

    if (spots.length == 1) {
      spots = [spots[0], spots[0].copyWithX(1)];
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
      margin: EdgeInsets.all(0),
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
      content = DateFormat(
        "MMMM",
        initData.l10n.localeName,
      ).format(DateTime.now().copyWith(month: DateTime.september)).firstUpper();
    } else if (value == lastX && !shouldHideNow) {
      content = initData.l10n.now;
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
    return FilledCircle(
      diameter: 18,
      color: bgColor,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: appStyle.fonts.H_14px.copyWith(color: textColor),
      ),
    );
  }

  Color colorForY(double y) {
    return y == 0 ? appStyle.colors.card : initData.settings.getGradeColor(y);
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    if (value == 0 || value > 5) {
      return SizedBox();
    }

    final currentValue = spots.last.y == 0
        ? 0
        : initData.settings.roundGrade(_tooltipY ?? spots.last.y);
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
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          if (_tooltipY != null &&
              initData.settings.roundGrade(_tooltipY!) == value) {
            return FlLine(color: const Color(0xFFC8C8C8), strokeWidth: 1.0);
          }
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
      maxY: 5.0000000000001,

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
  final List<GradeCacheModel> grades;
  final bool halfYearFallback;

  const GradeChartWithInteraction({
    super.key,
    required this.grades,
    this.halfYearFallback = true,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => ChartInteractionScope.of(context).value = true,
      onPointerUp: (_) => ChartInteractionScope.of(context).value = false,
      onPointerCancel: (_) => ChartInteractionScope.of(context).value = false,
      child: GradeChart(grades: grades, halfYearFallback: halfYearFallback),
    );
  }
}
