// ignore_for_file: deprecated_member_use
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:material_color_utilities/material_color_utilities.dart";

part "core/butcher_vanity.dart";
part "core/firka.dart";
part "core/m3e.dart";
part "core/refilc.dart";

final Map<String, CoreTheme> coreThemes = {
  "firka": firkaCore,
  "m3e": m3eCore,
  "refilc": refilcCore,
  "butcher_vanity": butcherVanityCore,
};

/// App chrome colors (everything except grade colors)
class CoreThemeColors {
  final Color background;
  final List<Color>? backgroundGradient;
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
    this.backgroundGradient,
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
