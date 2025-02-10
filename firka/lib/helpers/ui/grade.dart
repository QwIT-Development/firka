import 'package:firka/helpers/api/model/grade.dart';
import 'package:flutter/material.dart';

import '../../ui/model/style.dart';
import 'grade_helpers.dart';

class GradeWidget extends StatelessWidget {
  final Grade grade;

  const GradeWidget(this.grade, {super.key});

  @override
  Widget build(BuildContext context) {
    Color gradeColor = appStyle.colors.grade1;
    var gradeStr = grade.numericValue?.toString() ?? "0";
    double eccentricity = 0;

    if (grade.valueType.name == "Szazalekos") {
      gradeStr = grade.strValue.replaceAll("%", "");
      if (grade.numericValue != null) {
        gradeColor =
            getGradeColor(percentageToGrade(grade.numericValue!).toDouble());
      }

      if (grade.numericValue != null && grade.numericValue == 100) {
        return Card(
          shape: CircleBorder(eccentricity: eccentricity),
          shadowColor: Colors.transparent,
          color: gradeColor.withAlpha(38),
          child: Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Row(children: [
              Text("100", // TODO: Make this curved
                  style: appStyle.fonts.P_14.copyWith(color: gradeColor))
            ]),
          ),
        );
      } else {
        return Card(
          shape: CircleBorder(eccentricity: eccentricity),
          shadowColor: Colors.transparent,
          color: gradeColor.withAlpha(38),
          child: Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Row(children: [
              Text(gradeStr,
                  style: appStyle.fonts.P_14.copyWith(color: gradeColor)),
              Text("%", style: appStyle.fonts.P_12.copyWith(color: gradeColor))
            ]),
          ),
        );
      }
    } else {
      if (grade.numericValue != null) {
        gradeColor = getGradeColor(grade.numericValue!.toDouble());
      }

      return Card(
        shape: CircleBorder(eccentricity: eccentricity),
        shadowColor: Colors.transparent,
        color: gradeColor.withAlpha(38),
        child: Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Text(gradeStr,
                style: appStyle.fonts.H_H1
                    .copyWith(fontSize: 24, color: gradeColor))),
      );
    }
  }
}
