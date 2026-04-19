import 'package:flutter/material.dart';
import 'package:kreta_api/kreta_api.dart';

import 'package:firka_common/ui/components/grade_helpers.dart';
import 'package:firka_common/ui/theme/style.dart';

import 'filled_circle.dart';

class GradeWidget extends StatelessWidget {
  const GradeWidget(this.grade, {this.size = 36, super.key})
    : gradeValue = null,
      gradeWeight = null;

  const GradeWidget.gradeValue(
    this.gradeValue, {
    this.gradeWeight = 100,
    this.size = 36,
    super.key,
  }) : grade = null;

  final Grade? grade;
  final double size;
  final int? gradeValue;
  final int? gradeWeight;

  @override
  Widget build(BuildContext context) {
    if (gradeValue != null && gradeValue != null) {
      return _buildNumericCircle(gradeValue!, gradeWeight!);
    }

    final g = grade!;

    if (g.numericValue == null) {
      final gradeColor = appStyle.colors.accent;
      return FilledCircle(
        diameter: size,
        color: gradeColor.withAlpha(38),
        child: Text(
          '❝❠',
          style: appStyle.fonts.B_16SB.copyWith(color: gradeColor),
        ),
      );
    }

    if (g.valueType.name == 'Szazalekos') {
      final gradeColor = getGradeColor(percentageToGrade(g.numericValue!));
      return FilledCircle(
        diameter: size,
        color: gradeColor.withAlpha(38),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              g.numericValue!.toString(),
              style: appStyle.fonts.P_14.copyWith(color: gradeColor),
            ),
            Text('%', style: appStyle.fonts.P_12.copyWith(color: gradeColor)),
          ],
        ),
      );
    }

    return _buildNumericCircle(g.numericValue!, g.weightPercentage ?? 100);
  }

  Widget _buildNumericCircle(int value, int weight) {
    final gradeColor = getGradeColor(value);
    final textStyle = appStyle.fonts.H_H1.copyWith(
      color: gradeColor,
      fontSize: size * 0.75,
    );
    final text = Text(
      value.toString(),
      style: weight < 100
          ? textStyle.copyWith(
              foreground: Paint()
                ..color = gradeColor
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..strokeWidth = 1.13,
            )
          : textStyle,
    );

    if (weight > 100) {
      final circle_size = size * 0.8;
      final circle = FilledCircle(
        diameter: circle_size,
        color: gradeColor.withAlpha(38),
        child: SizedBox(),
      );
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(size - circle_size, 0),
              child: circle,
            ),
            Transform.translate(
              offset: Offset(0, size - circle_size),
              child: circle,
            ),
            Center(child: text),
          ],
        ),
      );
    }

    return FilledCircle(
      diameter: size,
      color: gradeColor.withAlpha(38),
      child: text,
    );
  }
}
