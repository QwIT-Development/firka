part of "../grade_theme.dart";

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
