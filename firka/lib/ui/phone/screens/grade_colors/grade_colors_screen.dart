import "dart:math" as math;

import "package:firka/app/app_state.dart";
import "package:firka/core/bloc/theme_cubit.dart";
import "package:firka/core/extensions.dart";
import "package:firka/core/settings/setting.dart";
import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";
import "package:firka/ui/components/color_slider.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/filled_circle.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:firka_common/ui/theme/style.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

class GradeColorsScreen extends StatefulWidget {
  final AppInitialization data;

  const GradeColorsScreen(this.data, {super.key});

  @override
  State<GradeColorsScreen> createState() => _GradeColorsScreenState();
}

StringSetting _settingFor(int grade) {
  switch (grade) {
    case 5:
      return SettingsRegistry.customGradeColor5;
    case 4:
      return SettingsRegistry.customGradeColor4;
    case 3:
      return SettingsRegistry.customGradeColor3;
    case 2:
      return SettingsRegistry.customGradeColor2;
    default:
      return SettingsRegistry.customGradeColor1;
  }
}

Color _defaultFor(int grade) {
  switch (grade) {
    case 5:
      return const Color(0xFF22CCAD);
    case 4:
      return const Color(0xFF92EA3B);
    case 3:
      return const Color(0xFFF9CF00);
    case 2:
      return const Color(0xFFFFA046);
    default:
      return const Color(0xFFFF54A1);
  }
}

Color _parseColor(String hex) {
  final value = int.tryParse(hex) ?? 0xFFFFFFFF;
  return Color(value);
}

String _encodeColor(Color color) =>
    "0x${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}";

class _GradeColorsScreenState extends State<GradeColorsScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedGrade;
  late HSVColor _hsv;

  final _hexController = TextEditingController();
  bool _hexFocused = false;

  late final AnimationController _ringController;
  Tween<double> _ringTween = Tween<double>(begin: 0, end: 0);
  double _ringRotation = 0;

  SettingsRepository get _settings => widget.data.settings;

  @override
  void initState() {
    super.initState();
    _selectedGrade = 5;
    _hsv = HSVColor.fromColor(_currentColor(_selectedGrade));
    _syncHexField();
    _ringController = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          _ringRotation = _ringTween.transform(
            Curves.easeInOutCubic.transform(_ringController.value),
          );
        });
      });
  }

  @override
  void dispose() {
    _hexController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Color _currentColor(int grade) {
    final raw = _settings.get(_settingFor(grade));
    return _parseColor(raw);
  }

  void _syncHexField() {
    if (!_hexFocused) {
      final hex = _encodeColor(_hsv.toColor()).substring(4);
      _hexController.text = hex.toUpperCase();
    }
  }

  Future<void> _applyHsv(HSVColor hsv) async {
    setState(() => _hsv = hsv);
    _syncHexField();
    await _settings.set(
      _settingFor(_selectedGrade),
      _encodeColor(hsv.toColor()),
    );
    if (!mounted) return;
    context.read<ThemeCubit>().refresh();
  }

  Future<void> _selectGrade(int grade) async {
    final hubIndex = _roleOrder.indexOf("hub");
    final targetMod = (hubIndex - _ring.indexOf(grade)) % _ring.length;
    var delta = (targetMod - _ringRotation) % _ring.length;
    if (delta > _ring.length / 2) delta -= _ring.length;
    final target = _ringRotation + delta;

    _ringTween = Tween<double>(begin: _ringRotation, end: target);

    _ringController
      ..duration = Duration(
        milliseconds: (150 * delta.abs()).clamp(180, 420).round(),
      )
      ..forward(from: 0);

    setState(() {
      _selectedGrade = grade;
      _hsv = HSVColor.fromColor(_currentColor(grade));
    });
    _syncHexField();
  }

  Future<void> _reset() async {
    final defaultColor = _defaultFor(_selectedGrade);
    await _applyHsv(HSVColor.fromColor(defaultColor));
  }

  Future<void> _randomize() async {
    await _applyHsv(math.Random().nextVividHSVColor());
  }

  void _onHexSubmit(String value) {
    final cleaned = value.replaceAll("#", "").trim();
    if (cleaned.length != 6) return;
    final parsed = int.tryParse("0xFF$cleaned");
    if (parsed == null) return;
    _applyHsv(HSVColor.fromColor(Color(parsed)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>.value(
      value: widget.data.themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, _) {
          return Scaffold(
            backgroundColor: appStyle.colors.background,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _gradeBubbles(),
                            const SizedBox(height: 28),
                            _hueSlider(),
                            const SizedBox(height: 8),
                            _saturationSlider(),
                            const SizedBox(height: 8),
                            _valueSlider(),
                            const SizedBox(height: 20),
                            _hexRow(),
                            const SizedBox(height: 12),
                            _gradeTabBar(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                onTap: () => context.pop(),
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
          headingText(l10n.s_c_grade_colors_header),
          style: appStyle.fonts.H_H1.apply(color: appStyle.colors.textPrimary),
        ),
      ],
    );
  }

  static const _roleSlots = <String, (double dx, double dy, double sizeFactor)>{
    "topLeft": (0.39, 0.22, 0.82),
    "topRight": (0.625, 0.22, 0.82),
    "midRight": (0.80, 0.46, 0.76),
    "hub": (0.505, 0.66, 1.0),
    "midLeft": (0.22, 0.46, 0.76),
  };
  static const _roleOrder = [
    "topLeft",
    "topRight",
    "midRight",
    "hub",
    "midLeft",
  ];

  static const _ring = [2, 3, 4, 5, 1];

  Widget _gradeBubbles() {
    const maxCenterSize = 88.0;
    const clusterHeight = 190.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centerSize = math.min(maxCenterSize, width * 0.24);

        return SizedBox(
          height: clusterHeight,
          width: width,
          child: Stack(
            children: [
              for (final grade in _ring)
                Builder(
                  builder: (context) {
                    final u = _ring.indexOf(grade) + _ringRotation;
                    final idx0 = u.floor();
                    final frac = u - idx0;
                    final slotA = _roleSlots[_roleOrder[idx0 % _ring.length]]!;
                    final slotB =
                        _roleSlots[_roleOrder[(idx0 + 1) % _ring.length]]!;
                    final dx = slotA.$1 + (slotB.$1 - slotA.$1) * frac;
                    final dy = slotA.$2 + (slotB.$2 - slotA.$2) * frac;
                    final sizeFactor = slotA.$3 + (slotB.$3 - slotA.$3) * frac;
                    final size = centerSize * sizeFactor;

                    return Positioned(
                      left: dx * width - size / 2,
                      top: dy * clusterHeight - size / 2,
                      child: _gradeBubble(grade, size: size),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _gradeBubble(int grade, {required double size}) {
    final isSelected = grade == _selectedGrade;
    final color = isSelected ? _hsv.toColor() : _currentColor(grade);
    final pastel = Color.alphaBlend(color.withAlpha(38), appStyle.colors.card);
    const ringWidth = 4.0;

    final circle = FilledCircle(
      diameter: isSelected ? size - ringWidth * 2 : size,
      color: pastel,
      child: Text(
        "$grade",
        style: appStyle.fonts.H_H1.copyWith(color: color, fontSize: size * 0.4),
      ),
    );

    return GestureDetector(
      onTap: isSelected ? null : () => _selectGrade(grade),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: appStyle.colors.buttonSecondaryFill,
                  width: ringWidth,
                )
              : null,
          boxShadow: isSelected && appStyle.isLight
              ? [
                  BoxShadow(
                    color: appStyle.colors.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(child: circle),
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
              maxLength: 6,
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

  Widget _gradeTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final grade in [1, 2, 3, 4, 5]) ...[
          if (grade != 1) const SizedBox(width: 8),
          _gradeTab(grade),
        ],
      ],
    );
  }

  Widget _gradeTab(int grade) {
    final isSelected = grade == _selectedGrade;

    return GestureDetector(
      onTap: isSelected ? null : () => _selectGrade(grade),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? appStyle.colors.accent : appStyle.colors.card,
        ),
        child: Center(
          child: Text(
            "$grade",
            style: appStyle.fonts.B_14SB.apply(
              color: isSelected
                  ? appStyle.colors.textPrimary
                  : appStyle.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
