import 'package:kreta_api/kreta_api.dart';

import 'dart:ui';

import 'package:firka_common/ui/theme/style.dart';

int roundGrade(
  num grade, {
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

Color getGradeColor(
  num grade, {
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

extension GradeListExtension on Iterable<Grade> {
  (int total, List<int> countsByGrade) getGradeDistribution() {
    final filtered = where((g) => g.shouldIncludeInAverage());
    final counts = [0, 0, 0, 0, 0];
    for (final g in filtered) {
      counts[g.numericValue! - 1]++;
    }
    return (filtered.length, counts);
  }

  double? getAverageBySubject(Subject subject) {
    return where(
      (g) => g.subject.uid == subject.uid && g.shouldIncludeInAverage(),
    ).getAverage();
  }

  double? getRoundedSubjectAverage({
    double t1 = 1,
    double t2 = 0.5,
    double t3 = 0.5,
    double t4 = 0.5,
  }) {
    final averages = map((g) => g.subject).toSet().map((subject) {
      final average = getAverageBySubject(subject);
      if (average == null) {
        return null;
      }
      return roundGrade(average, t1: t1, t2: t2, t3: t3, t4: t4);
    }).nonNulls;

    if (averages.isEmpty) {
      return null;
    }

    return averages.reduce((sum, avg) => sum + avg) / averages.length;
  }

  double? getSubjectAverage() {
    final averages = map(
      (g) => g.subject,
    ).toSet().map((subject) => getAverageBySubject(subject)).nonNulls;

    if (averages.isEmpty) {
      return null;
    }

    return averages.reduce((sum, avg) => sum + avg) / averages.length;
  }

  double? getAverage() {
    if (isEmpty) {
      return null;
    }

    double weightTotal = 0;
    double sum = 0;
    for (Grade grade in this) {
      if (!grade.shouldIncludeInAverage()) {
        continue;
      }

      double weight = (grade.weightPercentage ?? 100) / 100.0;
      weightTotal += weight;
      sum += grade.numericValue! * weight;
    }

    if (sum == 0) {
      return null;
    }

    return sum / weightTotal;
  }
}

extension GradeExtension on Grade {
  bool isInPercentage() {
    final name = valueType.name.toLowerCase();
    return name.contains('szazalek') || name.contains('percent');
  }

  bool shouldIncludeInAverage() {
    if (isInPercentage()) {
      return false;
    }

    final typeName = type.name.toLowerCase();
    if (typeName == 'felevi_jegy_ertekeles' ||
        typeName == 'evvegi_jegy_ertekeles') {
      return false;
    }

    if (numericValue == null) {
      return false;
    }

    return true;
  }
}
