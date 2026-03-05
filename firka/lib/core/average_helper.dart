import 'package:kreta_api/kreta_api.dart';

bool _isPercentageGrade(Grade grade) {
  final name = grade.valueType.name?.toLowerCase() ?? '';
  return name.contains('szazalek') || name.contains('percent');
}

bool shouldIgnoreInAverage(Grade grade) {
  if (_isPercentageGrade(grade)) {
    return true;
  }

  final typeName = grade.type.name?.toLowerCase() ?? '';
  if (typeName == 'felevi_jegy_ertekeles' ||
      typeName == 'evvegi_jegy_ertekeles') {
    return true;
  }

  return false;
}

double calculateAverage(List<Grade> sortedGrades, {bool applyIgnoreFilter = true}) {
  double totalWeight = 0.0;
  double weightedSum = 0.0;

  if (applyIgnoreFilter &&
      sortedGrades.isNotEmpty &&
      sortedGrades.where((g) => !shouldIgnoreInAverage(g)).isEmpty) {
    final grades = sortedGrades.where(
      (g) => g.numericValue != null && g.numericValue! > 0,
    );

    if (grades.isNotEmpty) {
      return grades.last.numericValue!.toDouble();
    }
  }

  for (final grade in sortedGrades) {
    if (applyIgnoreFilter && shouldIgnoreInAverage(grade)) continue;

    final value = grade.numericValue;
    final weight = grade.weightPercentage;

    if (value != null && weight != null) {
      weightedSum += value * weight;
      totalWeight += weight;
    }
  }

  if (totalWeight == 0) {
    return double.parse(0.0.toStringAsFixed(2));
  }

  final avg = weightedSum / totalWeight;
  return double.parse(avg.toStringAsFixed(2));
}
