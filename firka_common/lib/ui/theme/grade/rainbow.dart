part of "../grade_theme.dart";

GradeThemeColors _materialShades(MaterialColor color) {
  return GradeThemeColors(
    grade5: color.shade500,
    grade4: color.shade400,
    grade3: color.shade300,
    grade2: color.shade200,
    grade1: color.shade100,
  );
}

GradeTheme _materialRainbowGrade(String id, MaterialColor color) {
  final colors = _materialShades(color);
  return GradeTheme(id: id, light: colors, dark: colors);
}

final redGrade = _materialRainbowGrade("red", Colors.red);
final orangeGrade = _materialRainbowGrade("orange", Colors.orange);
final yellowGrade = _materialRainbowGrade("yellow", Colors.yellow);
final greenGrade = _materialRainbowGrade("green", Colors.green);
final blueGrade = _materialRainbowGrade("blue", Colors.blue);
final indigoGrade = _materialRainbowGrade("indigo", Colors.indigo);
final pinkGrade = _materialRainbowGrade("pink", Colors.pink);
final purpleGrade = _materialRainbowGrade("purple", Colors.purple);
