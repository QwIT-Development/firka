import 'package:firka/helpers/api/model/grade.dart';

double calculateAverage(List<Grade> sortedGrades) {
  double totalWeight = 0.0;
  double weightedSum = 0.0;

  for (final grade in sortedGrades) {
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