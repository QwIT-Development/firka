import "package:flutter/material.dart";

part "core/firka.dart";

const Map<String, CoreTheme> coreThemes = {
  "firka": firkaCore,
};

/// App chrome colors (everything except grade colors)
class CoreThemeColors {
  final Color background;
  final Color backgroundAmoled;
  final Color background0p;
  final Color success;
  final int shadowBlur;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color? textTeritary;

  final Color textPrimaryLight;
  final Color textSecondaryLight;
  final Color textTertiaryLight;

  final Color card;
  final Color cardTranslucent;

  final Color buttonSecondaryFill;
  final Color buttonDisabledIcon;

  final Color accent;
  final Color secondary;
  final Color shadowColor;
  final Color a10p;
  final Color a15p;

  final Color warningAccent;
  final Color warningText;
  final Color warning15p;
  final Color warningCard;

  final Color errorAccent;
  final Color errorText;
  final Color error15p;
  final Color errorCard;

  const CoreThemeColors({
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
  });
}

class CoreTheme {
  final String id;
  final CoreThemeColors light;
  final CoreThemeColors dark;

  const CoreTheme({
    required this.id,
    required this.light,
    required this.dark,
  });

  CoreThemeColors forBrightness(bool isLight) => isLight ? light : dark;
}

CoreTheme resolveCore(String id) => coreThemes[id] ?? firkaCore;
