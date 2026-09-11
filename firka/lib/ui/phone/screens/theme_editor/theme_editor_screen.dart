import "dart:math" as math;

import "package:carousel_slider/carousel_slider.dart";
import "package:firka/app/app_state.dart";
import "package:firka/app/initialization.dart";
import "package:firka/core/bloc/theme_cubit.dart";
import "package:firka/core/extensions.dart";
import "package:firka/core/settings/setting.dart";
import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";
import "package:firka/core/snowflake.dart";
import "package:firka/ui/components/color_slider.dart";
import "package:firka/ui/phone/screens/themes/builtin_theme_id.dart";
import "package:firka/ui/phone/screens/themes/preview/theme_preview_data.dart";
import "package:firka/ui/phone/screens/themes/preview/theme_preview_pages.dart";
import "package:firka/ui/phone/screens/themes/user_theme.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/data/database.dart";
import "package:firka_common/data/models/user_theme_model.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:firka_common/ui/theme/style.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

enum _ThemeSlot {
  accent,
  background,
  card,
  button,
  secondary,
  text,
  textSecondary,
  textTertiary,
  shadow,
  success,
  warningAccent,
  warningText,
  warningCard,
  errorAccent,
  errorText,
  errorCard,
}

enum _BrightnessMode { both, light, dark }

class ThemeEditorScreen extends StatefulWidget {
  final AppInitialization data;

  const ThemeEditorScreen(this.data, {super.key});

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

const _defaults = <_ThemeSlot, (Color light, Color dark)>{
  _ThemeSlot.accent: (Color(0xFFA7DC22), Color(0xFFA7DC22)),
  _ThemeSlot.background: (Color(0xFFFAFFF0), Color(0xFF0D1202)),
  _ThemeSlot.card: (Color(0xFFF3FBDE), Color(0xFF141905)),
  _ThemeSlot.button: (Color(0xFFFEFFFD), Color(0xFF20290B)),
  _ThemeSlot.secondary: (Color(0xFF6E8F1B), Color(0xFFCBEE71)),
  _ThemeSlot.text: (Color(0xFF394C0A), Color(0xFFEAF7CC)),
  _ThemeSlot.textSecondary: (Color(0xCC394C0A), Color(0xB3EAF7CC)),
  _ThemeSlot.textTertiary: (Color(0x80394C0A), Color(0x80EAF7CC)),
  _ThemeSlot.shadow: (Color(0x33647E22), Color(0x26CBEE71)),
  _ThemeSlot.success: (Color(0xFF92EA3B), Color(0xFF92EA3B)),
  _ThemeSlot.warningAccent: (Color(0xFFFFA046), Color(0xFFFFA046)),
  _ThemeSlot.warningText: (Color(0xFF8F531B), Color(0xFFF0B37A)),
  _ThemeSlot.warningCard: (Color(0xFFFAEBDC), Color(0xFF201203)),
  _ThemeSlot.errorAccent: (Color(0xFFFF54A1), Color(0xFFFF54A1)),
  _ThemeSlot.errorText: (Color(0xFF8F1B4F), Color(0xFFF59EC5)),
  _ThemeSlot.errorCard: (Color(0xFFFADCE9), Color(0xFF1E030F)),
};

(StringSetting, StringSetting) _settingsFor(_ThemeSlot slot) {
  switch (slot) {
    case _ThemeSlot.accent:
      return (
        SettingsRegistry.customAccentColorLight,
        SettingsRegistry.customAccentColorDark,
      );
    case _ThemeSlot.background:
      return (
        SettingsRegistry.customBackgroundColorLight,
        SettingsRegistry.customBackgroundColorDark,
      );
    case _ThemeSlot.card:
      return (
        SettingsRegistry.customCardColorLight,
        SettingsRegistry.customCardColorDark,
      );
    case _ThemeSlot.button:
      return (
        SettingsRegistry.customButtonColorLight,
        SettingsRegistry.customButtonColorDark,
      );
    case _ThemeSlot.secondary:
      return (
        SettingsRegistry.customSecondaryColorLight,
        SettingsRegistry.customSecondaryColorDark,
      );
    case _ThemeSlot.text:
      return (
        SettingsRegistry.customTextColorLight,
        SettingsRegistry.customTextColorDark,
      );
    case _ThemeSlot.textSecondary:
      return (
        SettingsRegistry.customTextSecondaryColorLight,
        SettingsRegistry.customTextSecondaryColorDark,
      );
    case _ThemeSlot.textTertiary:
      return (
        SettingsRegistry.customTextTertiaryColorLight,
        SettingsRegistry.customTextTertiaryColorDark,
      );
    case _ThemeSlot.shadow:
      return (
        SettingsRegistry.customShadowColorLight,
        SettingsRegistry.customShadowColorDark,
      );
    case _ThemeSlot.success:
      return (
        SettingsRegistry.customSuccessColorLight,
        SettingsRegistry.customSuccessColorDark,
      );
    case _ThemeSlot.warningAccent:
      return (
        SettingsRegistry.customWarningAccentColorLight,
        SettingsRegistry.customWarningAccentColorDark,
      );
    case _ThemeSlot.warningText:
      return (
        SettingsRegistry.customWarningTextColorLight,
        SettingsRegistry.customWarningTextColorDark,
      );
    case _ThemeSlot.warningCard:
      return (
        SettingsRegistry.customWarningCardColorLight,
        SettingsRegistry.customWarningCardColorDark,
      );
    case _ThemeSlot.errorAccent:
      return (
        SettingsRegistry.customErrorAccentColorLight,
        SettingsRegistry.customErrorAccentColorDark,
      );
    case _ThemeSlot.errorText:
      return (
        SettingsRegistry.customErrorTextColorLight,
        SettingsRegistry.customErrorTextColorDark,
      );
    case _ThemeSlot.errorCard:
      return (
        SettingsRegistry.customErrorCardColorLight,
        SettingsRegistry.customErrorCardColorDark,
      );
  }
}

void _applySlotColor(FirkaColors colors, _ThemeSlot slot, Color color) {
  switch (slot) {
    case _ThemeSlot.accent:
      colors.accent = color;
      colors.a10p = color.withAlpha(0x1a);
      colors.a15p = color.withAlpha(0x26);
    case _ThemeSlot.background:
      colors.background = color;
      colors.background0p = color.withAlpha(0);
    case _ThemeSlot.card:
      colors.card = color;
      colors.cardTranslucent = color.withAlpha(0x80);
    case _ThemeSlot.button:
      colors.buttonSecondaryFill = color;
    case _ThemeSlot.secondary:
      colors.secondary = color;
      colors.buttonDisabledIcon = color.withAlpha(0x80);
    case _ThemeSlot.text:
      colors.textPrimary = color;
    case _ThemeSlot.textSecondary:
      colors.textSecondary = color;
    case _ThemeSlot.textTertiary:
      colors.textTertiary = color;
      colors.textTeritary = color;
    case _ThemeSlot.shadow:
      colors.shadowColor = color;
    case _ThemeSlot.success:
      colors.success = color;
    case _ThemeSlot.warningAccent:
      colors.warningAccent = color;
      colors.warning15p = color.withAlpha(0x26);
    case _ThemeSlot.warningText:
      colors.warningText = color;
    case _ThemeSlot.warningCard:
      colors.warningCard = color;
    case _ThemeSlot.errorAccent:
      colors.errorAccent = color;
      colors.error15p = color.withAlpha(0x26);
    case _ThemeSlot.errorText:
      colors.errorText = color;
    case _ThemeSlot.errorCard:
      colors.errorCard = color;
  }
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  _ThemeSlot? _slot = _ThemeSlot.accent;
  _BrightnessMode _mode = _BrightnessMode.both;
  late HSVColor _hsv;
  late final ThemePreviewData _preview;

  // The app's real brightness before this screen started overriding
  // `appStyle` for live preview — used as the reference for "both" mode,
  // and restored when leaving the screen.
  late final bool _originalIsLight;

  final _hexController = TextEditingController();
  bool _hexFocused = false;

  SettingsRepository get _settings => widget.data.settings;

  @override
  void initState() {
    super.initState();
    _originalIsLight = appStyle.isLight;
    _preview = ThemePreviewData.build();
    _hsv = HSVColor.fromColor(
      _colorForSlotAndMode(_slot!, _mode),
    );
    _syncHexField();
    _refreshPreviewStyle();
  }

  @override
  void dispose() {
    initTheme(widget.data);
    _hexController.dispose();
    super.dispose();
  }

  bool get _previewIsLight => switch (_mode) {
    _BrightnessMode.light => true,
    _BrightnessMode.dark => false,
    _BrightnessMode.both => _originalIsLight,
  };

  // Rebuilds the global `appStyle` for whichever brightness is currently
  // being previewed, patching in the *live* (possibly not-yet-persisted)
  // slot color so the preview always reflects what's on screen, not just
  // what's already saved.
  void _refreshPreviewStyle() {
    final isLight = _previewIsLight;
    final style = buildStyleForBrightness(isLight, isCustomTheme: true);
    final slot = _slot;
    if (slot != null) {
      final editingLight = _mode != _BrightnessMode.dark;
      if (_mode == _BrightnessMode.both || editingLight == isLight) {
        _applySlotColor(style.colors, slot, _hsv.toColor());
      }
    }
    appStyle = style;
  }

  void _popAndRestore() {
    initTheme(widget.data);
    context.pop();
  }

  Color _currentColor(_ThemeSlot slot, {required bool isLightSource}) {
    final (light, dark) = _settingsFor(slot);
    final raw = _settings.get(isLightSource ? light : dark);
    return raw.toColorFromHexSetting();
  }

  Color _colorForSlotAndMode(_ThemeSlot slot, _BrightnessMode mode) {
    final light = _currentColor(slot, isLightSource: true);
    final dark = _currentColor(slot, isLightSource: false);
    switch (mode) {
      case _BrightnessMode.light:
        return light;
      case _BrightnessMode.dark:
        return dark;
      case _BrightnessMode.both:
        return light == dark
            ? light
            : _currentColor(slot, isLightSource: _originalIsLight);
    }
  }

  void _syncHexField() {
    if (!_hexFocused) {
      final color = _hsv.toColor();
      final hex = color.toHexSetting();
      _hexController.text =
          (color.a >= 1.0 ? hex.substring(4) : hex.substring(2))
              .toUpperCase();
    }
  }

  Future<void> _applyHsv(HSVColor hsv) async {
    final slot = _slot;
    if (slot == null) return;

    setState(() {
      _hsv = hsv;
      // Instant feedback: patch the preview before the settings roundtrip.
      _refreshPreviewStyle();
    });
    _syncHexField();

    final color = hsv.toColor();
    final hex = color.toHexSetting();
    final (light, dark) = _settingsFor(slot);

    switch (_mode) {
      case _BrightnessMode.both:
        await _settings.set(light, hex);
        await _settings.set(dark, hex);
      case _BrightnessMode.light:
        await _settings.set(light, hex);
      case _BrightnessMode.dark:
        await _settings.set(dark, hex);
    }

    if (isBuiltinThemeId(Settings.selectedThemeId.value)) {
      final id = Snowflake.nextId();
      final theme = UserTheme(
        id: id,
        name: widget.data.l10n.s_c_themes_own_label,
        origin: ThemeOrigin.own,
        swatch: UserTheme.swatchFromAppStyle(),
      );
      await isarInit.writeTxn(() async {
        await isarInit.userThemeModels.putByThemeId(theme.toModel());
      });
      await Settings.selectedThemeId.set(id);
    }

    if (!mounted) return;
    // Persisting re-triggers initTheme via the settings effect, which
    // resets `appStyle` to the app's real brightness — reassert the
    // preview override on top of that.
    setState(_refreshPreviewStyle);
    context.read<ThemeCubit>().refresh();
  }

  void _selectSlot(_ThemeSlot slot) {
    setState(() {
      if (_slot == slot) {
        _slot = null;
        _refreshPreviewStyle();
        return;
      }
      _slot = slot;
      _hsv = HSVColor.fromColor(_colorForSlotAndMode(slot, _mode));
      _refreshPreviewStyle();
    });
    _syncHexField();
  }

  void _selectMode(_BrightnessMode mode) {
    setState(() {
      _mode = mode;
      final slot = _slot;
      if (slot != null) {
        _hsv = HSVColor.fromColor(_colorForSlotAndMode(slot, mode));
      }
      _refreshPreviewStyle();
    });
    _syncHexField();
  }

  Future<void> _reset() async {
    final slot = _slot;
    if (slot == null) return;

    final (lightSetting, darkSetting) = _settingsFor(slot);
    final (lightDefault, darkDefault) = _defaults[slot]!;

    // Each brightness variant is restored to its *own* proper default —
    // in "both" mode this must not collapse light and dark to the same
    // color, since e.g. background's light/dark defaults are intentionally
    // very different.
    switch (_mode) {
      case _BrightnessMode.both:
        await _settings.set(lightSetting, lightDefault.toHexSetting());
        await _settings.set(darkSetting, darkDefault.toHexSetting());
      case _BrightnessMode.light:
        await _settings.set(lightSetting, lightDefault.toHexSetting());
      case _BrightnessMode.dark:
        await _settings.set(darkSetting, darkDefault.toHexSetting());
    }

    if (!mounted) return;
    setState(() {
      _hsv = HSVColor.fromColor(
        switch (_mode) {
          _BrightnessMode.light => lightDefault,
          _BrightnessMode.dark => darkDefault,
          _BrightnessMode.both => lightDefault == darkDefault
              ? lightDefault
              : (_originalIsLight ? lightDefault : darkDefault),
        },
      );
      _refreshPreviewStyle();
    });
    _syncHexField();
    context.read<ThemeCubit>().refresh();
  }

  Future<void> _randomize() async {
    await _applyHsv(math.Random().nextVividHSVColor());
  }

  void _onHexSubmit(String value) {
    final cleaned = value.replaceAll("#", "").trim();
    if (cleaned.length == 6) {
      final parsed = int.tryParse("0xFF$cleaned");
      if (parsed == null) return;
      _applyHsv(HSVColor.fromColor(Color(parsed)));
    } else if (cleaned.length == 8) {
      final parsed = int.tryParse("0x$cleaned");
      if (parsed == null) return;
      _applyHsv(HSVColor.fromColor(Color(parsed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popAndRestore();
      },
      child: BlocProvider<ThemeCubit>.value(
        value: widget.data.themeCubit,
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, _) {
            return Scaffold(
              backgroundColor: appStyle.colors.background,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _header(context),
                    ),
                    Expanded(child: _previewCarousel()),
                    _bottomEditor(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = widget.data.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Transform.translate(
              offset: const Offset(-4, 0),
              child: GestureDetector(
                onTap: _popAndRestore,
                child: FirkaIconWidget(
                  FirkaIconType.majesticons,
                  Majesticon.chevronLeftLine,
                  color: appStyle.colors.textSecondary,
                ),
              ),
            ),
            Text(
              l10n.s_customization,
              style: appStyle.fonts.B_16R.apply(
                color: appStyle.colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          headingText(l10n.s_c_colors_theme_header),
          style: appStyle.fonts.H_H1.apply(color: appStyle.colors.textPrimary),
        ),
      ],
    );
  }

  Widget _previewCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: false,
        enlargeCenterPage: false,
        padEnds: false,
      ),
      items: buildThemePreviewCarouselItems(
        data: widget.data,
        preview: _preview,
      ),
    );
  }

  Widget _bottomEditor() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: appStyle.colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: appStyle.colors.shadowColor,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_slot != null) ...[
            _hueSlider(),
            const SizedBox(height: 8),
            _saturationSlider(),
            const SizedBox(height: 8),
            _valueSlider(),
            const SizedBox(height: 8),
            _opacitySlider(),
            const SizedBox(height: 12),
            _hexRow(),
            const SizedBox(height: 12),
          ],
          _slotBar(),
          const SizedBox(height: 12),
          _modeBar(),
        ],
      ),
    );
  }

  Widget _hueSlider() {
    return ColorSlider(
      value: _hsv.hue / 360,
      trackGradient: const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ),
      thumbColor: _hsv.toColor(),
      onChanged: (t) => _applyHsv(_hsv.withHue(t * 360)),
    );
  }

  Widget _saturationSlider() {
    final fullSat = _hsv.withSaturation(1).withValue(1).toColor();
    return ColorSlider(
      value: _hsv.saturation,
      trackGradient: LinearGradient(colors: [Colors.white, fullSat]),
      thumbColor: _hsv.withValue(1).toColor(),
      onChanged: (t) => _applyHsv(_hsv.withSaturation(t)),
    );
  }

  Widget _valueSlider() {
    final fullV = _hsv.withValue(1).toColor();
    return ColorSlider(
      value: _hsv.value,
      trackGradient: LinearGradient(colors: [Colors.black, fullV]),
      thumbColor: _hsv.toColor(),
      onChanged: (t) => _applyHsv(_hsv.withValue(t)),
    );
  }

  Widget _opacitySlider() {
    final solid = _hsv.toColor().withAlpha(255);
    return ColorSlider(
      value: _hsv.alpha,
      trackGradient: LinearGradient(
        colors: [
          solid.withAlpha(0),
          solid,
        ],
      ),
      thumbColor: _hsv.toColor(),
      onChanged: (t) => _applyHsv(_hsv.withAlpha(t.clamp(0.0, 1.0))),
    );
  }

  Widget _hexRow() {
    return FirkaCard(
      left: [
        _iconCircle(icon: Majesticon.reloadLine, onTap: _reset, faded: true),
        const SizedBox(width: 12),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hsv.toColor(),
            boxShadow: [
              BoxShadow(
                color: appStyle.colors.shadowColor,
                blurRadius: appStyle.isLight ? 3 : 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "HEX",
          style: appStyle.fonts.B_14R.apply(
            color: appStyle.colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 96,
          child: Focus(
            onFocusChange: (focused) => setState(() => _hexFocused = focused),
            child: TextField(
              controller: _hexController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              ],
              onSubmitted: _onHexSubmit,
              style: appStyle.fonts.B_16SB.apply(
                color: appStyle.colors.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: "",
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: "FFFFFF",
                hintStyle: appStyle.fonts.B_16SB.apply(
                  color: appStyle.colors.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ],
      right: [
        _iconCircle(
          icon: Majesticon.repeatCircleLine,
          onTap: _randomize,
          accent: true,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _iconCircle({
    required Object icon,
    required VoidCallback onTap,
    bool faded = false,
    bool accent = false,
  }) {
    final bgColor = accent
        ? appStyle.colors.accent
        : appStyle.colors.buttonSecondaryFill;
    final iconColor = accent
        ? appStyle.colors.textPrimary
        : appStyle.colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: appStyle.colors.shadowColor,
              blurRadius: appStyle.isLight ? 2 : 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: FirkaIconWidget(
            FirkaIconType.majesticons,
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Widget _slotBar() {
    final l10n = widget.data.l10n;
    final labels = <_ThemeSlot, String>{
      _ThemeSlot.accent: l10n.s_c_slot_accent,
      _ThemeSlot.background: l10n.s_c_slot_background,
      _ThemeSlot.card: l10n.s_c_slot_cards,
      _ThemeSlot.button: l10n.s_c_slot_buttons,
      _ThemeSlot.secondary: l10n.s_c_slot_secondary,
      _ThemeSlot.text: l10n.s_c_slot_text,
      _ThemeSlot.textSecondary: l10n.s_c_slot_text_secondary,
      _ThemeSlot.textTertiary: l10n.s_c_slot_text_tertiary,
      _ThemeSlot.shadow: l10n.s_c_slot_shadow,
      _ThemeSlot.success: l10n.s_c_slot_success,
      _ThemeSlot.warningAccent: l10n.s_c_slot_warning,
      _ThemeSlot.warningText: l10n.s_c_slot_warning_text,
      _ThemeSlot.warningCard: l10n.s_c_slot_warning_card,
      _ThemeSlot.errorAccent: l10n.s_c_slot_error,
      _ThemeSlot.errorText: l10n.s_c_slot_error_text,
      _ThemeSlot.errorCard: l10n.s_c_slot_error_card,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final slot in _ThemeSlot.values) ...[
            _pill(
              labels[slot]!,
              selected: slot == _slot,
              onTap: () => _selectSlot(slot),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _modeBar() {
    final l10n = widget.data.l10n;
    final labels = <_BrightnessMode, String>{
      _BrightnessMode.both: l10n.s_c_mode_both,
      _BrightnessMode.light: l10n.s_c_theme_light,
      _BrightnessMode.dark: l10n.s_c_theme_dark,
    };

    return FirkaCard.single(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final mode in _BrightnessMode.values)
            Expanded(
              child: _segment(
                labels[mode]!,
                selected: mode == _mode,
                onTap: () => _selectMode(mode),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? appStyle.colors.accent : appStyle.colors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: appStyle.fonts.B_14SB.apply(
            color: selected
                ? appStyle.colors.textPrimary
                : appStyle.colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _segment(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? appStyle.colors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: appStyle.fonts.B_14SB.apply(
            color: selected
                ? appStyle.colors.textPrimary
                : appStyle.colors.textTertiary,
          ),
        ),
      ),
    );
  }
}
