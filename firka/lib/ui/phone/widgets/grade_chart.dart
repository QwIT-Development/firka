import 'package:firka/helpers/api/model/grade.dart';
import 'package:firka/ui/model/style.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GradeChart extends StatefulWidget {
  final List<Grade> grades;
  const GradeChart({super.key, required this.grades});

  @override
  State<GradeChart> createState() => _GradeChartState();
}

class _GradeChartState extends State<GradeChart> {
  List<Color> gradientColors = [
    appStyle.colors.grade5,
    appStyle.colors.grade4,
    appStyle.colors.grade3,
    appStyle.colors.grade2,
    appStyle.colors.grade1,
  ];
  
  late final List<FlSpot> spots;

  @override
  void initState() {
    super.initState();

    final sortedGrades = List<Grade>.from(widget.grades)
      ..sort((a, b) => a.creationDate.compareTo(b.creationDate));

    if (sortedGrades.isEmpty) {
      spots = [const FlSpot(0, 0)];
      return;
    }

    double sum = 0;
    double count = 0;
    spots = [];
    for (int i = 0; i < sortedGrades.length; i++) {
      final grade = sortedGrades[i];
      if (grade.numericValue != null) {
        sum += grade.numericValue!.toDouble();
        count += 1;
        spots.add(FlSpot(i.toDouble(), double.parse((sum / count).toStringAsFixed(2))));
      }
    }
    if (spots.isEmpty) {
      spots = [const FlSpot(0, 0)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appStyle.colors.card,
        ),
        child: AspectRatio(
          aspectRatio: 1.90,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 28,
              left: 12,
              top: 0,
              bottom: 12,
            ),
            child: LineChart(avgData()),
          ),
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      fontFamily: appStyle.fonts.B_16R.fontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: appStyle.colors.textSecondary,
    );

    final firstX = spots.first.x.toInt();
    final lastX = spots.last.x.toInt();
    String text = '';
    const epsilon = 0.01;

    if ((value - firstX).abs() < epsilon) {
      text = 'Szeptember';
    } else if ((value - lastX).abs() < epsilon) {
      text = 'Most';
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
      color: appStyle.colors.textSecondary,
    );
    String text = switch (value.toInt()) {
      1 => '1',
      2 => '2',
      3 => '3',
      4 => '4',
      5 => '5',
      _ => '',
    };
    return Text(text, style: style, textAlign: TextAlign.left);
  }

  LineChartData avgData() {
    final firstX = spots.first.x;
    final lastX = spots.last.x;

    Color colorForY(double y) {
      switch (y.round()) {
        case 1:
          return appStyle.colors.grade1;
        case 2:
          return appStyle.colors.grade2;
        case 3:
          return appStyle.colors.grade3;
        case 4:
          return appStyle.colors.grade4;
        case 5:
          return appStyle.colors.grade5;
        default:
          return appStyle.colors.grade1;
      }
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipMargin: 0,
          getTooltipColor: (touchedSpot) => appStyle.colors.buttonSecondaryFill,
          tooltipBorderRadius: BorderRadius.circular(90),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final textStyle = TextStyle(
                color: colorForY(touchedSpot.y),
                fontWeight: FontWeight.bold,
                fontSize: 18
              );
              return LineTooltipItem(touchedSpot.y.toString(), textStyle);
            }).toList();
          },
        ),
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            final touchedSpot = barData.spots[index]; 
            return TouchedSpotIndicatorData(
              FlLine(
                color: colorForY(touchedSpot.y),
                strokeWidth: 3,
              ),
              FlDotData(
                show: false,
              ),
            );
          }).toList();
        },
      ),
      backgroundColor: appStyle.colors.card,
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          if (value != 5) {
            return FlLine(
              color: Color(0xFFC8C8C8),
              strokeWidth: 1.0,
              dashArray: [8, 12],
            );
          } else {
            return FlLine(
              color: Color(0xFFC8C8C8),
              strokeWidth: 1.0,
            );
          }
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: bottomTitleWidgets,
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
            interval: 1,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),

      minX: firstX,
      maxX: lastX,
      minY: 0,
      maxY: 6,

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          gradient: LinearGradient(
            colors: [for (final s in spots) colorForY(s.y)],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                for (final s in spots)
                  colorForY(s.y).withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
