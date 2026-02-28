import 'package:firka/api/model/grade.dart';
import 'package:flutter/material.dart';

import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/components/grade_helpers.dart';

class GradeWidget extends StatelessWidget {
  const GradeWidget(this.grade, {super.key})
    : gradeValue = null,
      _fromValue = false;

  const GradeWidget.gradeValue(int value, {super.key})
    : grade = null,
      gradeValue = value,
      _fromValue = true;

  final Grade? grade;
  final int? gradeValue;
  final bool _fromValue;

  @override
  Widget build(BuildContext context) {
    if (_fromValue && gradeValue != null) {
      return _buildNumericCircle(
        gradeValue!,
        getGradeColor(gradeValue!.toDouble()),
      );
    }

    final g = grade!;
    Color gradeColor = appStyle.colors.grade1;
    final gradeStr = g.numericValue?.toString() ?? '0';

    if (g.valueType.name == 'Szazalekos') {
      if (g.numericValue != null) {
        gradeColor = getGradeColor(
          percentageToGrade(g.numericValue!).toDouble(),
        );
      }

      final str = g.strValue.replaceAll('%', '');
      return Card(
        shape: const CircleBorder(),
        shadowColor: Colors.transparent,
        color: gradeColor.withAlpha(38),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(str, style: appStyle.fonts.P_14.copyWith(color: gradeColor)),
              Text('%', style: appStyle.fonts.P_12.copyWith(color: gradeColor)),
            ],
          ),
        ),
      );
    }

    if (g.numericValue != null) {
      gradeColor = getGradeColor(g.numericValue!.toDouble());
    }

    if (gradeStr == '0') {
      return Card(
        shadowColor: Colors.transparent,
        color: gradeColor.withAlpha(38),
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
          child: Text(
            g.strValue,
            style: appStyle.fonts.H_H1.copyWith(
              fontSize: 16,
              color: gradeColor,
            ),
          ),
        ),
      );
    }

    return _buildNumericCircle(g.numericValue!, gradeColor);
  }

  Widget _buildNumericCircle(int value, Color gradeColor) {
    return Card(
      shape: const CircleBorder(),
      shadowColor: Colors.transparent,
      color: gradeColor.withAlpha(38),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Text(
          value.toString(),
          style: appStyle.fonts.H_H1.copyWith(fontSize: 24, color: gradeColor),
        ),
      ),
    );
  }
}
