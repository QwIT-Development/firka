import 'package:flutter/material.dart';

class FirkaFonts {
  TextStyle H_H1;
  TextStyle H_18px;
  TextStyle H_H2;
  TextStyle H_16px;
  TextStyle H_14px;
  TextStyle H_12px;

  TextStyle H_16px_trimmed; // TODO: somehow implement this
  // the design has this trimmed to 130% line height

  TextStyle B_16R;
  TextStyle B_16SB;

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

  Color card;
  Color cardTranslucent;

  Color buttonSecondaryFill;

  Color accent;
  Color secondary;
  Color shadowColor;
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
    required this.card,
    required this.cardTranslucent,
    required this.buttonSecondaryFill,
    required this.accent,
    required this.secondary,
    required this.shadowColor,
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

  FirkaStyle({required this.colors, required this.fonts});
}

final _defaultFonts = FirkaFonts(
  H_H1: TextStyle(
    fontSize: 30,
    fontFamily: 'Montserrat',
    fontVariations: [FontVariation("wght", 700)],
  ),
  H_18px: TextStyle(
    fontSize: 18,
    fontFamily: 'Montserrat',
    fontVariations: [FontVariation("wght", 700)],
  ),
  H_H2: TextStyle(
    fontSize: 20,
    fontFamily: 'Montserrat',
    fontVariations: [FontVariation("wght", 700)],
  ),
  H_16px: TextStyle(
    fontSize: 16,
    fontFamily: 'Montserrat',
    fontVariations: [FontVariation("wght", 600)],
  ),
  H_14px: TextStyle(
    fontSize: 14,
    fontFamily: 'Montserrat',
    fontVariations: [FontVariation("wght", 600)],
  ),
  H_12px: TextStyle(
    fontSize: 12,
    fontFamily: 'Montserrat',
    fontVariations: [FontVariation("wght", 600)],
  ),
  H_16px_trimmed: TextStyle(
    fontSize: 16,
    fontFamily: 'Montserrat',
    fontVariations: [FontVariation("wght", 600)],
  ),
  B_16R: TextStyle(
      fontSize: 16,
      fontFamily: 'Figtree',
      fontVariations: [FontVariation("wght", 600)]),
  B_16SB: TextStyle(
    fontSize: 16,
    fontFamily: 'Figtree',
    fontVariations: [FontVariation("wght", 700)],
  ),
  B_14R: TextStyle(
      fontSize: 14,
      fontFamily: 'Figtree',
      fontVariations: [FontVariation("wght", 600)]),
  B_14SB: TextStyle(
    fontSize: 14,
    fontFamily: 'Figtree',
    fontVariations: [FontVariation("wght", 700)],
  ),
  B_12R: TextStyle(
      fontSize: 12,
      fontFamily: 'Figtree',
      fontVariations: [FontVariation("wght", 600)]),
  B_12SB: TextStyle(
    fontSize: 12,
    fontFamily: 'Figtree',
    fontVariations: [FontVariation("wght", 700)],
  ),
  P_14: TextStyle(
    fontSize: 14,
    fontFamily: 'RobotoMono',
    fontVariations: [FontVariation("wght", 700)],
  ),
  P_12: TextStyle(
    fontSize: 12,
    fontFamily: 'RobotoMono',
    fontVariations: [FontVariation("wght", 700)],
  ),
);

final FirkaStyle lightStyle = FirkaStyle(
    colors: FirkaColors(
      background: Color(0xFFFAFFF0),
      backgroundAmoled: Colors.black,
      background0p: Color(0x00fafff0),
      success: Color(0xFF92EA3B),
      shadowBlur: 2,
      textPrimary: Color(0xFF394C0A),
      textSecondary: Color(0xCC394C0A),
      textTertiary: Color(0x80394C0A),
      card: Color(0xFFF3FBDE),
      cardTranslucent: Color(0x80F3FBDE),
      buttonSecondaryFill: Color(0xFFFEFFFD),
      accent: Color(0xFFA7DC22),
      secondary: Color(0xFF6E8F1B),
      shadowColor: Color(0x33647e22),
      a15p: Color(0x26a7dc22),
      warningAccent: Color(0xFFFFA046),
      warningText: Color(0xFF8F531B),
      warning15p: Color(0x26FFA046),
      warningCard: Color(0xFFFAEBDC),
      errorAccent: Color(0xFFFF54A1),
      errorText: Color(0xFF8F1B4F),
      error15p: Color(0x26FF54A1),
      errorCard: Color(0xFFFADCE9),
      grade5: Color(0xFF22CCAD),
      grade4: Color(0xFF92EA3B),
      grade3: Color(0xFFF9CF00),
      grade2: Color(0xFFFFA046),
      grade1: Color(0xFFFF54A1),
    ),
    fonts: _defaultFonts);

final FirkaStyle darkStyle = FirkaStyle(
    colors: FirkaColors(
      background: Color(0xFF0D1202),
      backgroundAmoled: Colors.black,
      background0p: Color(0x00fafff0),
      success: Color(0xFF92EA3B),
      shadowBlur: 0,
      textPrimary: Color(0xFFEAF7CC),
      textSecondary: Color(0xB3EAF7CC),
      textTertiary: Color(0x80EAF7CC),
      card: Color(0xFF141905),
      cardTranslucent: Color(0x80141905),
      buttonSecondaryFill: Color(0xFF20290B),
      accent: Color(0xFFA7DC22),
      secondary: Color(0xFFCBEE71),
      shadowColor: Color(0x26CBEE71),
      a15p: Color(0x26A7DC22),
      warningAccent: Color(0xFFFFA046),
      warningText: Color(0xFFF0B37A),
      warning15p: Color(0x26FFA046),
      warningCard: Color(0xFF201203),
      errorAccent: Color(0xFFFF54A1),
      errorText: Color(0xFFF59EC5),
      error15p: Color(0x26FF54A1),
      errorCard: Color(0xFF1E030F),
      grade5: Color(0xFF22CCAD),
      grade4: Color(0xFF92EA3B),
      grade3: Color(0xFFF9CF00),
      grade2: Color(0xFFFFA046),
      grade1: Color(0xFFFF54A1),
    ),
    fonts: _defaultFonts);

FirkaStyle appStyle = lightStyle;
FirkaStyle wearStyle = darkStyle;
