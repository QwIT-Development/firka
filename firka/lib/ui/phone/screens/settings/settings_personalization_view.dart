import "dart:io";

import "package:firka/app/app_state.dart";
import "package:firka/core/bloc/theme_cubit.dart";
import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";
import "package:firka/core/settings/settings_ui.dart";
import "package:firka/core/settings/title_font.dart";
import "package:firka/l10n/app_localizations.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

class SettingsPersonalizationView extends StatefulWidget {
  final AppInitialization data;
  final SettingsUiPersonalization item;

  const SettingsPersonalizationView({
    required this.data,
    required this.item,
    super.key,
  });

  @override
  State<SettingsPersonalizationView> createState() =>
      _SettingsPersonalizationViewState();
}

class _SettingsPersonalizationViewState
    extends State<SettingsPersonalizationView> {
  bool _fontPickerExpanded = false;

  SettingsRepository get _settings => widget.data.settings;
  AppLocalizations get _l10n => widget.data.l10n;

  Color get _mutedCardColor => appStyle.isLight
      ? const Color(0xFFE4EBC8)
      : appStyle.colors.buttonSecondaryFill;

  Color get _selectedSurface => appStyle.colors.buttonSecondaryFill;

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        text,
        style: appStyle.fonts.B_16R.apply(
          color: appStyle.colors.textPrimary,
        ),
      ),
    );
  }

  Widget _externalArrow() {
    return RotationTransition(
      turns: const AlwaysStoppedAnimation(-45 / 360),
      child: FirkaIconWidget(
        FirkaIconType.majesticons,
        Majesticon.arrowRightLine,
        size: 20,
        color: appStyle.colors.textSecondary,
      ),
    );
  }

  Widget _shortcutRow({
    required String title,
    FirkaIconType? iconType,
    Object? iconData,
    VoidCallback? onTap,
  }) {
    final left = <Widget>[];
    if (iconType != null && iconData != null) {
      left.add(
        FirkaIconWidget(
          iconType,
          iconData,
          color: appStyle.colors.accent,
        ),
      );
      left.add(const SizedBox(width: 8));
    }
    left.add(
      Text(
        title,
        style: appStyle.fonts.B_16SB.apply(
          color: appStyle.colors.textPrimary,
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: FirkaCard(
        left: left,
        right: [_externalArrow()],
      ),
    );
  }

  Widget _chip(String label, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _selectedSurface : appStyle.colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appStyle.colors.shadowColor,
            offset: const Offset(0, 1),
            blurRadius: appStyle.isLight ? 2 : 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: (selected ? appStyle.fonts.B_16SB : appStyle.fonts.B_16R).apply(
          color: appStyle.colors.textPrimary,
        ),
      ),
    );
  }

  Widget _swatchPreview(List<Color> colors) {
    return FirkaCard.single(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 88,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final color in colors)
                Expanded(child: ColoredBox(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stubCustomizeButton() {
    return FirkaCard(
      left: [
        Text(
          _l10n.s_c_customize,
          style: appStyle.fonts.B_16SB.apply(
            color: appStyle.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _checkMark() {
    return SizedBox(
      width: 16,
      height: 16,
      child: Checkbox(
        value: true,
        fillColor: WidgetStateProperty.resolveWith<Color>((_) {
          return appStyle.colors.secondary;
        }),
        onChanged: (_) {},
      ),
    );
  }

  Widget _themeOption(String label, ThemeBrightness value) {
    final selected = _settings.get(SettingsRegistry.themeBrightness) == value;

    final card = FirkaCard(
      height: 52 + 12,
      left: [
        Text(
          label,
          style: appStyle.fonts.B_16R.apply(
            color: appStyle.colors.textPrimary,
          ),
        ),
      ],
      right: selected
          ? [_checkMark(), const SizedBox(width: 8)]
          : [const SizedBox(height: 16 + 8)],
    );

    if (selected) return card;

    return GestureDetector(
      onTap: () async {
        await _settings.set(SettingsRegistry.themeBrightness, value);
        setState(() {});
      },
      child: card,
    );
  }

  Widget _fontCard(TitleFont font, {required bool selected}) {
    final style = TextStyle(
      fontFamily: font.fontFamily,
      fontSize: 16,
      fontVariations: font.supportsWeight
          ? [FontVariation("wght", _settings.get(SettingsRegistry.titleWeight))]
          : null,
      color: appStyle.colors.textPrimary,
    );

    return GestureDetector(
      onTap: selected
          ? null
          : () async {
              await _settings.set(SettingsRegistry.titleFont, font);
              setState(() {});
            },
      child: FirkaCard(
        color: selected ? _selectedSurface : _mutedCardColor,
        left: [
          Text(font.displayName, style: style),
        ],
        right: selected
            ? [_checkMark(), const SizedBox(width: 8)]
            : const [],
      ),
    );
  }

  Widget _changeRow() {
    return GestureDetector(
      onTap: () {
        setState(() => _fontPickerExpanded = !_fontPickerExpanded);
      },
      child: FirkaCard(
        left: [
          Text(
            _l10n.s_c_change,
            style: appStyle.fonts.B_16SB.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        ],
        right: [
          FirkaIconWidget(
            FirkaIconType.majesticons,
            _fontPickerExpanded
                ? Majesticon.chevronUpLine
                : Majesticon.chevronDownLine,
            size: 24,
            color: appStyle.colors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _fontPicker(TitleFont selected) {
    if (!_fontPickerExpanded) {
      return Column(
        children: [
          _fontCard(selected, selected: true),
          _changeRow(),
        ],
      );
    }

    return Column(
      children: [
        for (final font in TitleFont.values)
          _fontCard(font, selected: font == selected),
        _changeRow(),
      ],
    );
  }

  double _textWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  Widget _weightEndDot() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appStyle.colors.textTertiary.withValues(alpha: 0.22),
      ),
    );
  }

  Widget _weightThumb({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appStyle.colors.accent,
        border: Border.all(
          color: appStyle.colors.buttonSecondaryFill,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: appStyle.colors.shadowColor,
            offset: const Offset(0, 1),
            blurRadius: appStyle.isLight ? 3 : 0,
          ),
        ],
      ),
    );
  }

  Widget _weightSlider() {
    final setting = SettingsRegistry.titleWeight;
    final value = _settings.get(setting);
    const trackHeight = 52.0;
    const thumbSize = 28.0;
    const thumbRadius = thumbSize / 2;
    const edgePad = 16.0;
    const gap = 8.0;
    const endDotSize = 12.0;

    final labelStyle = appStyle.fonts.B_14R.apply(
      color: appStyle.colors.textSecondary,
    );
    final thinLabel = _l10n.s_c_title_weight_thin;
    final thickLabel = _l10n.s_c_title_weight_thick;
    final thinWidth = _textWidth(thinLabel, labelStyle);
    final thickWidth = _textWidth(thickLabel, labelStyle);

    Future<void> setFromLocalX(double localX, double width) async {
      final start = edgePad + thumbRadius;
      final end = width - edgePad - thumbRadius;
      if (end <= start) return;

      final t = ((localX - start) / (end - start)).clamp(0.0, 1.0);
      final raw = setting.min + t * (setting.max - setting.min);
      final stepped = (raw / setting.step!).round() * setting.step!;
      final clamped = stepped.clamp(setting.min, setting.max).toDouble();
      if (clamped == value) return;

      await _settings.set(setting, clamped);
      setState(() {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(_l10n.s_c_title_weight_header),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _l10n.s_c_title_weight_subtitle,
            style: appStyle.fonts.B_14R.apply(
              color: appStyle.colors.textSecondary,
            ),
          ),
        ),
        FirkaCard.single(
          width: double.infinity,
          height: trackHeight,
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final start = edgePad + thumbRadius;
              final end = width - edgePad - thumbRadius;
              final t = ((value - setting.min) / (setting.max - setting.min))
                  .clamp(0.0, 1.0);
              final thumbCenterX = start + t * (end - start);
              final thumbLeft = thumbCenterX - thumbRadius;
              final thumbRight = thumbCenterX + thumbRadius;

              final thinLeft = edgePad + endDotSize + gap;
              final thinRight = thinLeft + thinWidth;
              final thickRight = width - edgePad - endDotSize - gap;
              final thickLeft = thickRight - thickWidth;

              final showThin = thumbRight < thinLeft || thumbLeft > thinRight;
              final showThick = thumbRight < thickLeft || thumbLeft > thickRight;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  setFromLocalX(details.localPosition.dx, width);
                },
                onHorizontalDragUpdate: (details) {
                  setFromLocalX(details.localPosition.dx, width);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: edgePad),
                      child: Row(
                        children: [
                          _weightEndDot(),
                          const SizedBox(width: gap),
                          Opacity(
                            opacity: showThin ? 1 : 0,
                            child: Text(thinLabel, style: labelStyle),
                          ),
                          const Spacer(),
                          Opacity(
                            opacity: showThick ? 1 : 0,
                            child: Text(thickLabel, style: labelStyle),
                          ),
                          const SizedBox(width: gap),
                          _weightEndDot(),
                        ],
                      ),
                    ),
                    Positioned(
                      left: thumbLeft,
                      child: _weightThumb(size: thumbSize),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _capitalizationControl() {
    final selected = _settings.get(SettingsRegistry.titleCapitalization);
    final options = [
      (TitleCapitalization.lower, _l10n.s_c_capitalization_lower),
      (TitleCapitalization.normal, _l10n.s_c_capitalization_normal),
      (TitleCapitalization.upper, _l10n.s_c_capitalization_upper),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(_l10n.s_c_capitalization_header),
        FirkaCard.single(
          width: double.infinity,
          color: appStyle.colors.card,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final (value, label) in options)
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await _settings.set(
                        SettingsRegistry.titleCapitalization,
                        value,
                      );
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected == value
                            ? _selectedSurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: selected == value
                            ? [
                                BoxShadow(
                                  color: appStyle.colors.shadowColor,
                                  offset: const Offset(0, 1),
                                  blurRadius: appStyle.isLight ? 2 : 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: appStyle.fonts.B_14R.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>.value(
      value: widget.data.themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, _) {
          final selectedFont = _settings.get(SettingsRegistry.titleFont);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-4, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: FirkaIconWidget(
                        FirkaIconType.majesticons,
                        Majesticon.chevronLeftLine,
                        color: appStyle.colors.textSecondary,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-4, 1),
                    child: Text(
                      headingText(_l10n.s_customization),
                      style: appStyle.fonts.H_H2.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(_l10n.s_c_tab_appearance, selected: true),
                    const SizedBox(width: 8),
                    _chip(_l10n.s_c_tab_subjects, selected: false),
                    const SizedBox(width: 8),
                    _chip(_l10n.s_c_tab_fonts, selected: false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _shortcutRow(
                title: _l10n.s_c_my_themes,
                iconType: FirkaIconType.majesticons,
                iconData: Majesticon.editPen4Solid,
              ),
              _shortcutRow(
                title: _l10n.s_c_manage_subjects,
                iconType: FirkaIconType.majesticons,
                iconData: Majesticon.bookmarkSolid,
              ),
              if (Platform.isAndroid)
                _shortcutRow(
                  title: _l10n.s_c_change_app_icon,
                  onTap: () {
                    context.push("/settings", extra: [
                      SettingsUiBackHeader(_l10n.s_customization, () => true),
                      ...widget.item.appIconPickerChildren,
                    ]);
                  },
                ),
              _sectionLabel(_l10n.s_c_colors_header),
              _swatchPreview([
                appStyle.colors.secondary,
                appStyle.colors.accent,
                appStyle.colors.background,
                appStyle.colors.card,
              ]),
              _stubCustomizeButton(),
              _sectionLabel(_l10n.s_c_theme_header),
              _themeOption(_l10n.s_c_theme_auto, ThemeBrightness.auto),
              _themeOption(_l10n.s_c_theme_light, ThemeBrightness.light),
              _themeOption(_l10n.s_c_theme_dark, ThemeBrightness.dark),
              _sectionLabel(_l10n.s_c_grade_colors_header),
              _swatchPreview([
                  appStyle.colors.grade5,
                  appStyle.colors.grade4,
                  appStyle.colors.grade3,
                  appStyle.colors.grade2,
                  appStyle.colors.grade1,
                ]),
              _stubCustomizeButton(),
              _sectionLabel(_l10n.s_c_title_style_header),
              _fontPicker(selectedFont),
              _weightSlider(),
              _capitalizationControl(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
