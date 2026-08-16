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
import "package:firka_common/ui/theme/core_theme.dart";
import "package:firka_common/ui/theme/grade_theme.dart";
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

  List<Color> _coreSwatch(CoreThemeColors colors) {
    return [
      colors.secondary,
      colors.accent,
      colors.background,
      colors.card,
    ];
  }

  List<Color> _gradeSwatch(GradeThemeColors colors) {
    return [
      colors.grade5,
      colors.grade4,
      colors.grade3,
      colors.grade2,
      colors.grade1,
    ];
  }

  Widget _coreThemePager() {
    final cores = coreThemes.values.toList(growable: false);
    final selectedId = _settings.get(SettingsRegistry.selectedCoreThemeId);
    var selectedIndex = cores.indexWhere((theme) => theme.id == selectedId);
    if (selectedIndex < 0) selectedIndex = 0;

    return _PresetSwatchPager(
      key: const ValueKey("core-themes"),
      swatches: [
        for (final core in cores)
          _coreSwatch(core.forBrightness(appStyle.isLight)),
      ],
      selectedIndex: selectedIndex,
      onSelected: (index) async {
        await _settings.set(
          SettingsRegistry.selectedCoreThemeId,
          cores[index].id,
        );
      },
    );
  }

  Widget _gradeThemePager() {
    final grades = gradeThemes.values.toList(growable: false);
    final selectedId = _settings.get(SettingsRegistry.selectedGradeThemeId);
    var selectedIndex = grades.indexWhere((theme) => theme.id == selectedId);
    if (selectedIndex < 0) selectedIndex = 0;

    return _PresetSwatchPager(
      key: const ValueKey("grade-themes"),
      swatches: [
        for (final grade in grades)
          _gradeSwatch(grade.forBrightness(appStyle.isLight)),
      ],
      selectedIndex: selectedIndex,
      onSelected: (index) async {
        await _settings.set(
          SettingsRegistry.selectedGradeThemeId,
          grades[index].id,
        );
      },
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
                onTap: () => context.push("/themes"),
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
              _coreThemePager(),
              _stubCustomizeButton(),
              _sectionLabel(_l10n.s_c_theme_header),
              _themeOption(_l10n.s_c_theme_auto, ThemeBrightness.auto),
              _themeOption(_l10n.s_c_theme_light, ThemeBrightness.light),
              _themeOption(_l10n.s_c_theme_dark, ThemeBrightness.dark),
              _sectionLabel(_l10n.s_c_grade_colors_header),
              _gradeThemePager(),
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

class _PresetSwatchPager extends StatefulWidget {
  final List<List<Color>> swatches;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PresetSwatchPager({
    super.key,
    required this.swatches,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<_PresetSwatchPager> createState() => _PresetSwatchPagerState();
}

class _PresetSwatchPagerState extends State<_PresetSwatchPager> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(_PresetSwatchPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_controller.hasClients) return;
    if (widget.selectedIndex == oldWidget.selectedIndex) return;
    if (_controller.page?.round() == widget.selectedIndex) return;
    _controller.animateToPage(
      widget.selectedIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _accentFor(double page) {
    final index = page.round().clamp(0, widget.swatches.length - 1);
    final swatch = widget.swatches[index];
    if (swatch.length > 1) return swatch[1];
    return appStyle.colors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return FirkaCard.single(
      width: double.infinity,
      height: 88,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.swatches.length,
              physics: widget.swatches.length <= 1
                  ? const NeverScrollableScrollPhysics()
                  : null,
              onPageChanged: (index) {
                if (index == widget.selectedIndex) return;
                widget.onSelected(index);
              },
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final color in widget.swatches[index])
                      Expanded(child: ColoredBox(color: color)),
                  ],
                );
              },
            ),
            if (widget.swatches.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final page = _controller.hasClients
                          ? (_controller.page ??
                                widget.selectedIndex.toDouble())
                          : widget.selectedIndex.toDouble();
                      return Center(
                        child: _SwatchPageDots(
                          count: widget.swatches.length,
                          page: page,
                          accent: _accentFor(page),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwatchPageDots extends StatelessWidget {
  final int count;
  final double page;
  final Color accent;

  const _SwatchPageDots({
    required this.count,
    required this.page,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            _dot(i),
          ],
        ],
      ),
    );
  }

  Widget _dot(int index) {
    final t = (1 - (index - page).abs()).clamp(0.0, 1.0);
    final size = 5.0 + 3.0 * t;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          accent.withValues(alpha: 0.28),
          accent,
          t,
        ),
      ),
    );
  }
}
