part of "../core_theme.dart";

const _defaultM3eSeed = Color(0xFF6750A4);

CoreThemeColors coreColorsFromColorScheme(ColorScheme scheme) {
  final isLight = scheme.brightness == Brightness.light;
  final bg = scheme.surface;
  final card = isLight ? scheme.surfaceContainerLow : scheme.surfaceContainer;
  final buttonFill =
      isLight ? scheme.surfaceContainerLowest : scheme.surfaceContainerHigh;
  final accent = scheme.primary;
  final secondary = scheme.secondary;

  return CoreThemeColors(
    background: bg,
    backgroundGradient: null,
    backgroundAmoled: Colors.black,
    background0p: bg.withAlpha(0),
    success: isLight ? const Color(0xFF34C759) : const Color(0xFF32D74B),
    shadowBlur: isLight ? 2 : 0,
    textPrimary: scheme.onSurface,
    textSecondary: scheme.onSurfaceVariant,
    textTertiary: scheme.onSurface.withAlpha(0x80),
    textTeritary: scheme.outline,
    textPrimaryLight: scheme.onSurface,
    textSecondaryLight: scheme.onSurfaceVariant,
    textTertiaryLight: scheme.onSurface.withAlpha(0x80),
    card: card,
    cardTranslucent: card.withAlpha(0x80),
    buttonSecondaryFill: buttonFill,
    buttonDisabledIcon: scheme.outline.withAlpha(0x80),
    accent: accent,
    secondary: secondary,
    shadowColor: scheme.shadow.withAlpha(isLight ? 0x26 : 0x40),
    a10p: accent.withAlpha(0x1a),
    a15p: accent.withAlpha(0x26),
    warningAccent: const Color(0xFFFFA046),
    warningText: isLight ? const Color(0xFF8F531B) : const Color(0xFFF0B37A),
    warning15p: const Color(0x26FFA046),
    warningCard: isLight ? const Color(0xFFFAEBDC) : const Color(0xFF201203),
    errorAccent: scheme.error,
    errorText: isLight ? const Color(0xFF8F1B4F) : const Color(0xFFF59EC5),
    error15p: scheme.error.withAlpha(0x26),
    errorCard: isLight ? scheme.errorContainer : const Color(0xFF1E030F),
  );
}

ColorScheme corePaletteToFlutterColorScheme(
  // ignore: deprecated_member_use
  CorePalette palette, {
  required bool isLight,
}) {
  // ignore: deprecated_member_use
  final scheme = isLight
      // ignore: deprecated_member_use
      ? Scheme.lightFromCorePalette(palette)
      // ignore: deprecated_member_use
      : Scheme.darkFromCorePalette(palette);

  final base = ColorScheme.fromSeed(
    seedColor: Color(scheme.primary),
    brightness: isLight ? Brightness.light : Brightness.dark,
  );

  return base.copyWith(
    primary: Color(scheme.primary),
    onPrimary: Color(scheme.onPrimary),
    primaryContainer: Color(scheme.primaryContainer),
    onPrimaryContainer: Color(scheme.onPrimaryContainer),
    secondary: Color(scheme.secondary),
    onSecondary: Color(scheme.onSecondary),
    secondaryContainer: Color(scheme.secondaryContainer),
    onSecondaryContainer: Color(scheme.onSecondaryContainer),
    tertiary: Color(scheme.tertiary),
    onTertiary: Color(scheme.onTertiary),
    tertiaryContainer: Color(scheme.tertiaryContainer),
    onTertiaryContainer: Color(scheme.onTertiaryContainer),
    error: Color(scheme.error),
    onError: Color(scheme.onError),
    errorContainer: Color(scheme.errorContainer),
    onErrorContainer: Color(scheme.onErrorContainer),
    outline: Color(scheme.outline),
    outlineVariant: Color(scheme.outlineVariant),
    surface: Color(scheme.surface),
    onSurface: Color(scheme.onSurface),
    onSurfaceVariant: Color(scheme.onSurfaceVariant),
    inverseSurface: Color(scheme.inverseSurface),
    onInverseSurface: Color(scheme.inverseOnSurface),
    inversePrimary: Color(scheme.inversePrimary),
    shadow: Color(scheme.shadow),
    surfaceTint: Color(scheme.primary),
    scrim: Color(scheme.scrim),
  );
}

final _defaultM3eLight = coreColorsFromColorScheme(
  ColorScheme.fromSeed(
    seedColor: _defaultM3eSeed,
    brightness: Brightness.light,
  ),
);

final _defaultM3eDark = coreColorsFromColorScheme(
  ColorScheme.fromSeed(
    seedColor: _defaultM3eSeed,
    brightness: Brightness.dark,
  ),
);

CoreTheme m3eCore = CoreTheme(
  id: "m3e",
  light: _defaultM3eLight,
  dark: _defaultM3eDark,
);

void updateM3eFromColorSchemes({
  ColorScheme? light,
  ColorScheme? dark,
}) {
  final lightColors =
      light != null ? coreColorsFromColorScheme(light) : _defaultM3eLight;
  final darkColors =
      dark != null ? coreColorsFromColorScheme(dark) : _defaultM3eDark;
  m3eCore = CoreTheme(
    id: "m3e",
    light: lightColors,
    dark: darkColors,
  );
  coreThemes["m3e"] = m3eCore;
}

Future<void> regenerateM3eTheme() async {
  try {
    final corePalette = await DynamicColorPlugin.getCorePalette();
    if (corePalette != null) {
      final lightScheme =
          corePaletteToFlutterColorScheme(corePalette, isLight: true);
      final darkScheme =
          corePaletteToFlutterColorScheme(corePalette, isLight: false);
      updateM3eFromColorSchemes(light: lightScheme, dark: darkScheme);
      return;
    }
  } catch (_) {}

  try {
    final accentColor = await DynamicColorPlugin.getAccentColor();
    if (accentColor != null) {
      final lightScheme = ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
      );
      final darkScheme = ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
      );
      updateM3eFromColorSchemes(light: lightScheme, dark: darkScheme);
      return;
    }
  } catch (_) {}

  updateM3eFromColorSchemes();
}
