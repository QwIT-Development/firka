import 'dart:ui';

import 'package:firka_common/ui/theme/style.dart';
import 'package:kreta_api/kreta_api.dart';

int roundGrade(
  double grade, {
  double t1 = 1,
  double t2 = 0.5,
  double t3 = 0.5,
  double t4 = 0.5,
}) {
  if (grade < 1 + t1) {
    return 1;
  }
  if (grade < 2 + t2) {
    return 2;
  }
  if (grade < 3 + t3) {
    return 3;
  }
  if (grade < 4 + t4) {
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

Color getGradeColor(
  double grade, {
  double t1 = 1,
  double t2 = 0.5,
  double t3 = 0.5,
  double t4 = 0.5,
}) {
  switch (roundGrade(grade, t1: t1, t2: t2, t3: t3, t4: t4)) {
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

(int total, List<int> countsByGrade) getGradeDistribution(List<Grade> grades) {
  final filtered = grades.where((g) {
    final typeName = g.type.name?.toLowerCase() ?? '';
    if (typeName == 'felevi_jegy_ertekeles' ||
        typeName == 'evvegi_jegy_ertekeles') {
      return false;
    }

    final valueTypeName = g.valueType.name?.toLowerCase() ?? '';
    final isPercentage =
        valueTypeName.contains('szazalek') || valueTypeName.contains('percent');
    if (isPercentage) {
      return false;
    }

    return true;
  }).toList();
  final counts = [0, 0, 0, 0, 0];
  for (final g in filtered) {
    if (g.numericValue == null) continue;
    final value = g.valueType.name == "Szazalekos"
        ? percentageToGrade(g.numericValue!.round())
        : g.numericValue!.round().clamp(1, 5);
    counts[value - 1]++;
  }
  return (filtered.length, counts);
}

extension GradeListExtension on List<Grade> {
  double getAverageBySubject(Subject subject) {
    var weightTotal = 0.00;
    var sum = 0.00;

    for (var grade in this) {
      if (grade.subject.uid == subject.uid) {
        final valueTypeName = grade.valueType.name?.toLowerCase() ?? '';
        final isPercentage =
            valueTypeName.contains('szazalek') ||
            valueTypeName.contains('percent');

        final typeName = grade.type.name?.toLowerCase() ?? '';
        final isHalfYear = typeName == 'felevi_jegy_ertekeles';
        final isEndYear = typeName == 'evvegi_jegy_ertekeles';

        if (isPercentage || isHalfYear || isEndYear) {
          continue;
        }

        if (grade.numericValue != null) {
          var weight = (grade.weightPercentage ?? 100) / 100.0;
          weightTotal += weight;

          sum += grade.numericValue! * weight;
        }
      }
    }

    if (weightTotal == 0) {
      return double.nan;
    }

    return sum / weightTotal;
  }
}
