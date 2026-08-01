import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/util.dart';
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

extension GradeCacheModelListExtension on Iterable<GradeCacheModel> {
  (int total, List<int> countsByGrade) getGradeDistribution() {
    final filtered = where((g) => g.shouldIncludeInAverage());
    final counts = [0, 0, 0, 0, 0];
    for (final g in filtered) {
      counts[g.numericValue! - 1]++;
    }
    return (filtered.length, counts);
  }

  double? _getAverageBySubject(int key, {bool halfYearFallback = true}) {
    return where(
      (g) => g.subject.loadAndGet()!.cacheKey == key,
    ).getAverage(halfYearFallback: halfYearFallback);
  }

  double? getAverageBySubject(
    SubjectCacheModel subject, {
    bool halfYearFallback = true,
  }) {
    return _getAverageBySubject(
      subject.cacheKey,
      halfYearFallback: halfYearFallback,
    );
  }

  double? getRoundedSubjectAverage({
    bool halfYearFallback = true,
    double t1 = 1,
    double t2 = 0.5,
    double t3 = 0.5,
    double t4 = 0.5,
  }) {
    final averages = map((g) => g.subject.loadAndGet()!).toSet().map((subject) {
      final average = getAverageBySubject(
        subject,
        halfYearFallback: halfYearFallback,
      );
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

  double? getSubjectAverage({bool halfYearFallback = true}) {
    final averages = where((g) => g.hasClassicValue())
        .map((g) => g.subject.loadAndGet()!.cacheKey)
        .toSet()
        .map(
          (uid) =>
              _getAverageBySubject(uid, halfYearFallback: halfYearFallback),
        )
        .nonNulls;

    if (averages.isEmpty) {
      return null;
    }

    return averages.reduce((sum, avg) => sum + avg) / averages.length;
  }

  double? getAverage({bool halfYearFallback = true}) {
    if (isEmpty) {
      return null;
    }

    double weightTotal = 0;
    double sum = 0;
    int? fallback;
    for (final grade in this) {
      if (grade.hasClassicValue() && halfYearFallback) {
        fallback = grade.numericValue!;
      }

      if (!grade.shouldIncludeInAverage()) {
        continue;
      }

      double weight = grade.weightPercentage! / 100.0;
      weightTotal += weight;
      sum += grade.numericValue! * weight;
    }

    if (sum == 0) {
      // use classification exam results or half-year evaluations
      return fallback?.toDouble();
    }

    return sum / weightTotal;
  }
}

extension GradeExtension on Grade {
  bool isInPercentage() {
    return valueType.name == 'Szazalekos';
  }

  bool hasClassicValue() {
    return valueType.name == "Osztalyzat";
  }

  // https://tudasbazis.ekreta.hu/pages/viewpage.action?pageId=2426172
  bool shouldIncludeInAverage() {
    return weightPercentage != null && hasClassicValue();
  }
}

extension GradeCacheModelExtension on GradeCacheModel {
  bool isInPercentage() {
    return valueType == 'Szazalekos';
  }

  bool hasClassicValue() {
    return valueType == "Osztalyzat";
  }

  // https://tudasbazis.ekreta.hu/pages/viewpage.action?pageId=2426172
  bool shouldIncludeInAverage() {
    return weightPercentage != null && hasClassicValue();
  }
}
