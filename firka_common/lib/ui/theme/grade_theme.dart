import "package:flutter/material.dart";

const Map<String, GradeTheme> gradeThemes = {
  "firka": firkaGrade,
};

const _firkaGradeColors = GradeThemeColors(
  grade5: Color(0xFF22CCAD),
  grade4: Color(0xFF92EA3B),
  grade3: Color(0xFFF9CF00),
  grade2: Color(0xFFFFA046),
  grade1: Color(0xFFFF54A1),
);

const firkaGrade = GradeTheme(
  id: "firka",
  light: _firkaGradeColors,
  dark: _firkaGradeColors,
);

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

GradeTheme resolveGrade(String id) => gradeThemes[id] ?? firkaGrade;
