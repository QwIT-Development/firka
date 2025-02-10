import 'dart:ui';

import '../../ui/model/style.dart';
import '../api/model/grade.dart';
import '../api/model/subject.dart';

int roundGrade(double grade) {
  if (grade < 2) {
    return 1;
  }
  if (grade < 2.5) {
    return 2;
  }
  if (grade < 3.5) {
    return 3;
  }
  if (grade < 4.5) {
    return 4;
  }

  return 5;
}

int percentageToGrade(int grade) {
  if (grade < 50) {
    return 1;
  }
  if (grade < 60) {
    return 2;
  }
  if (grade < 70) {
    return 3;
  }
  if (grade < 80) {
    return 4;
  }

  return 5;
}

Color getGradeColor(double grade) {
  switch (roundGrade(grade)) {
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

extension GradeListExtension on List<Grade> {
  double getAverageBySubject(Subject subject) {
    var weightTotal = 0.00;
    var sum = 0.00;

    for (var grade in this) {
      if (grade.subject.uid == subject.uid) {
        if (grade.numericValue != null) {
          var weight = (grade.weightPercentage ?? 100) / 100.0;
          weightTotal += weight;

          sum += grade.numericValue! * weight;
        }
      }
    }

    return sum / weightTotal;
  }
}
