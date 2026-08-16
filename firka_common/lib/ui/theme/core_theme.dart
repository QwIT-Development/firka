import "package:flutter/material.dart";

const Map<String, CoreTheme> coreThemes = {
  "firka": firkaCore,
};

const firkaCore = CoreTheme(
  id: "firka",
  light: CoreThemeColors(
    background: Color(0xFFFAFFF0),
    backgroundAmoled: Colors.black,
    background0p: Color(0x00fafff0),
    success: Color(0xFF92EA3B),
    shadowBlur: 2,
    textPrimary: Color(0xFF394C0A),
    textSecondary: Color(0xCC394C0A),
    textTertiary: Color(0x80394C0A),
    textTeritary: Color(0xFF97A474),
    textPrimaryLight: Color(0xFF394C0A),
    textSecondaryLight: Color(0xCC394C0A),
    textTertiaryLight: Color(0x80394C0A),
    card: Color(0xFFF3FBDE),
    cardTranslucent: Color(0x80F3FBDE),
    buttonSecondaryFill: Color(0xFFFEFFFD),
    buttonDisabledIcon: Color(0xFFCDD9B3),
    accent: Color(0xFFA7DC22),
    secondary: Color(0xFF6E8F1B),
    shadowColor: Color(0x33647e22),
    a10p: Color(0x1aa7dc22),
    a15p: Color(0x26a7dc22),
    warningAccent: Color(0xFFFFA046),
    warningText: Color(0xFF8F531B),
    warning15p: Color(0x26FFA046),
    warningCard: Color(0xFFFAEBDC),
    errorAccent: Color(0xFFFF54A1),
    errorText: Color(0xFF8F1B4F),
    error15p: Color(0x26FF54A1),
    errorCard: Color(0xFFFADCE9),
  ),
  dark: CoreThemeColors(
    background: Color(0xFF0D1202),
    backgroundAmoled: Colors.black,
    background0p: Color(0x00fafff0),
    success: Color(0xFF92EA3B),
    shadowBlur: 0,
    textPrimary: Color(0xFFEAF7CC),
    textSecondary: Color(0xB3EAF7CC),
    textTertiary: Color(0x80EAF7CC),
    textTeritary: Color(0xFF97A474),
    textPrimaryLight: Color(0xFF394C0A),
    textSecondaryLight: Color(0xCC394C0A),
    textTertiaryLight: Color(0x80394C0A),
    card: Color(0xFF141905),
    cardTranslucent: Color(0x80141905),
    buttonSecondaryFill: Color(0xFF20290B),
    buttonDisabledIcon: Color(0xFF465422),
    accent: Color(0xFFA7DC22),
    secondary: Color(0xFFCBEE71),
    shadowColor: Color(0x26CBEE71),
    a10p: Color(0x1AA7DC22),
    a15p: Color(0x26A7DC22),
    warningAccent: Color(0xFFFFA046),
    warningText: Color(0xFFF0B37A),
    warning15p: Color(0x26FFA046),
    warningCard: Color(0xFF201203),
    errorAccent: Color(0xFFFF54A1),
    errorText: Color(0xFFF59EC5),
    error15p: Color(0x26FF54A1),
    errorCard: Color(0xFF1E030F),
  ),
);

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
