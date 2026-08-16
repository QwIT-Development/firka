import "package:flutter/material.dart";

part "grade/firka.dart";

class GradeThemeColors {
  final Color grade5;
  final Color grade4;
  final Color grade3;
  final Color grade2;
  final Color grade1;

  const GradeThemeColors({
    required this.grade5,
    required this.grade4,
    required this.grade3,
    required this.grade2,
    required this.grade1,
  });
}

class GradeTheme {
  final String id;
  final GradeThemeColors light;
  final GradeThemeColors dark;

  const GradeTheme({
    required this.id,
    required this.light,
    required this.dark,
  });

  GradeThemeColors forBrightness(bool isLight) => isLight ? light : dark;
}

const Map<String, GradeTheme> gradeThemes = {
  "firka": firkaGrade,
};

GradeTheme resolveGrade(String id) => gradeThemes[id] ?? firkaGrade;
