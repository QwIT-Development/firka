import 'package:flutter/material.dart';
import 'package:firka_common/ui/theme/core_theme.dart';
import 'package:firka_common/ui/theme/grade_theme.dart';

// Design system token names; ignore non_constant_identifier_names for consistency with design specs
// ignore_for_file: non_constant_identifier_names

class FirkaFonts {
  TextStyle H_H1;
  TextStyle H_18px;
  TextStyle H_H2;
  TextStyle H_16px;
  TextStyle H_14px;
  TextStyle H_12px;

  TextStyle H_16px_trimmed;

  TextStyle B_16R;
  TextStyle B_16SB;
  TextStyle B_15SB;

  TextStyle B_14R;
  TextStyle B_14SB;

  TextStyle B_12R;
  TextStyle B_12SB;

  TextStyle P_14;
  TextStyle P_12;

  FirkaFonts({
    required this.H_H1,
    required this.H_18px,
    required this.H_H2,
    required this.H_16px,
    required this.H_14px,
    required this.H_12px,
    required this.H_16px_trimmed,
    required this.B_16R,
    required this.B_16SB,
    required this.B_15SB,
    required this.B_14R,
    required this.B_14SB,
    required this.B_12R,
    required this.B_12SB,
    required this.P_14,
    required this.P_12,
  });
}

class FirkaColors {
  Color background;
  Color backgroundAmoled;
  Color background0p;
  Color success;
  int shadowBlur;

  Color textPrimary;
  Color textSecondary;
  Color textTertiary;
  Color? textTeritary;

  Color textPrimaryLight;
  Color textSecondaryLight;
  Color textTertiaryLight;

  Color card;
  Color cardTranslucent;

  Color buttonSecondaryFill;
  Color buttonDisabledIcon;

  Color accent;
  Color secondary;
  Color shadowColor;
  Color a10p; // 10%
  Color a15p; // 15%

  Color warningAccent;
  Color warningText;
  Color warning15p;
  Color warningCard;

  Color errorAccent;
  Color errorText;
  Color error15p;
  Color errorCard;

  Color grade5;
  Color grade4;
  Color grade3;
  Color grade2;
  Color grade1;

  FirkaColors({
    required this.background,
    required this.backgroundAmoled,
    required this.background0p,
    required this.success,
    required this.shadowBlur,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    this.textTeritary,
    required this.textPrimaryLight,
    required this.textSecondaryLight,
    required this.textTertiaryLight,
    required this.card,
    required this.cardTranslucent,
    required this.buttonSecondaryFill,
    required this.buttonDisabledIcon,
    required this.accent,
    required this.secondary,
    required this.shadowColor,
    required this.a10p,
    required this.a15p,
    required this.warningAccent,
    required this.warningText,
    required this.warning15p,
    required this.warningCard,
    required this.errorAccent,
    required this.errorText,
    required this.error15p,
    required this.errorCard,
    required this.grade5,
    required this.grade4,
    required this.grade3,
    required this.grade2,
    required this.grade1,
  });
}

class FirkaStyle {
  FirkaColors colors;
  FirkaFonts fonts;
  bool isLight;

  FirkaStyle({
    required this.isLight,
    required this.colors,
    required this.fonts,
  });
}

enum HeadingTextCase { lower, normal, upper }

HeadingTextCase appHeadingTextCase = HeadingTextCase.normal;

String headingText(String text) {
  switch (appHeadingTextCase) {
    case HeadingTextCase.lower:
      return text.toLowerCase();
    case HeadingTextCase.upper:
      return text.toUpperCase();
    case HeadingTextCase.normal:
      return text;
  }
}

FirkaFonts buildAppFonts({
  String headingFamily = "Montserrat",
  double headingWeight = 700,
  bool supportsWeight = true,
}) {
  List<FontVariation>? headingVariations(double weight) {
    if (!supportsWeight) return null;
    return [FontVariation("wght", weight)];
  }

  final boldWeight = supportsWeight ? headingWeight : 700.0;
  final semiWeight = supportsWeight
      ? (headingWeight * 600 / 700).clamp(100.0, 900.0).toDouble()
      : 600.0;

  return FirkaFonts(
    H_H1: TextStyle(
      fontSize: 30,
      fontFamily: headingFamily,
      fontVariations: headingVariations(boldWeight),
    ),
    H_18px: TextStyle(
      fontSize: 18,
      fontFamily: headingFamily,
      fontVariations: headingVariations(boldWeight),
    ),
    H_H2: TextStyle(
      fontSize: 20,
      fontFamily: headingFamily,
      fontVariations: headingVariations(boldWeight),
    ),
    H_16px: TextStyle(
      fontSize: 16,
      fontFamily: headingFamily,
      fontVariations: headingVariations(semiWeight),
    ),
    H_14px: TextStyle(
      fontSize: 14,
      fontFamily: headingFamily,
      fontVariations: headingVariations(semiWeight),
    ),
    H_12px: TextStyle(
      fontSize: 12,
      fontFamily: headingFamily,
      fontVariations: headingVariations(semiWeight),
    ),
    H_16px_trimmed: TextStyle(
      fontSize: 16,
      fontFamily: headingFamily,
      fontVariations: headingVariations(semiWeight),
      height: 1.3,
    ),
    B_16R: TextStyle(
      fontSize: 16,
      fontFamily: "Figtree",
      fontVariations: [FontVariation("wght", 500)],
      height: 1.3,
    ),
    B_16SB: TextStyle(
      fontSize: 16,
      fontFamily: "Figtree",
      fontVariations: [FontVariation("wght", 600)],
      height: 1.3,
    ),
    B_14R: TextStyle(
      fontSize: 14,
      fontFamily: "Figtree",
      fontVariations: [FontVariation("wght", 500)],
      height: 1.3,
    ),
    B_14SB: TextStyle(
      fontSize: 14,
      fontFamily: "Figtree",
      fontVariations: [FontVariation("wght", 600)],
      height: 1.3,
    ),
    B_15SB: TextStyle(
      fontSize: 15,
      fontFamily: "Figtree",
      fontVariations: [FontVariation("wght", 700)],
      height: 1.3,
    ),
    B_12R: TextStyle(
      fontSize: 12,
      fontFamily: "Figtree",
      fontVariations: [FontVariation("wght", 600)],
      height: 1.3,
    ),
    B_12SB: TextStyle(
      fontSize: 12,
      fontFamily: "Figtree",
      fontVariations: [FontVariation("wght", 700)],
      height: 1.3,
    ),
    P_14: TextStyle(
      fontSize: 14,
      fontFamily: "RobotoMono",
      fontVariations: [FontVariation("wght", 700)],
    ),
    P_12: TextStyle(
      fontSize: 12,
      fontFamily: "RobotoMono",
      fontVariations: [FontVariation("wght", 700)],
    ),
  );
}

final _defaultFonts = buildAppFonts();

FirkaColors mergeColors(CoreThemeColors core, GradeThemeColors grades) {
  return FirkaColors(
    background: core.background,
    backgroundAmoled: core.backgroundAmoled,
    background0p: core.background0p,
    success: core.success,
    shadowBlur: core.shadowBlur,
    textPrimary: core.textPrimary,
    textSecondary: core.textSecondary,
    textTertiary: core.textTertiary,
    textTeritary: core.textTeritary,
    textPrimaryLight: core.textPrimaryLight,
    textSecondaryLight: core.textSecondaryLight,
    textTertiaryLight: core.textTertiaryLight,
    card: core.card,
    cardTranslucent: core.cardTranslucent,
    buttonSecondaryFill: core.buttonSecondaryFill,
    buttonDisabledIcon: core.buttonDisabledIcon,
    accent: core.accent,
    secondary: core.secondary,
    shadowColor: core.shadowColor,
    a10p: core.a10p,
    a15p: core.a15p,
    warningAccent: core.warningAccent,
    warningText: core.warningText,
    warning15p: core.warning15p,
    warningCard: core.warningCard,
    errorAccent: core.errorAccent,
    errorText: core.errorText,
    error15p: core.error15p,
    errorCard: core.errorCard,
    grade5: grades.grade5,
    grade4: grades.grade4,
    grade3: grades.grade3,
    grade2: grades.grade2,
    grade1: grades.grade1,
  );
}

FirkaStyle styleFor({
  required String coreId,
  required String gradeId,
  required bool isLight,
  required FirkaFonts fonts,
}) {
  final core = resolveCore(coreId).forBrightness(isLight);
  final grades = resolveGrade(gradeId).forBrightness(isLight);
  return FirkaStyle(
    isLight: isLight,
    colors: mergeColors(core, grades),
    fonts: fonts,
  );
}

FirkaStyle get lightStyle => styleFor(
  coreId: "firka",
  gradeId: "firka",
  isLight: true,
  fonts: _defaultFonts,
);

FirkaStyle get darkStyle => styleFor(
  coreId: "firka",
  gradeId: "firka",
  isLight: false,
  fonts: _defaultFonts,
);

FirkaStyle appStyle = lightStyle;
FirkaStyle wearStyle = darkStyle;
