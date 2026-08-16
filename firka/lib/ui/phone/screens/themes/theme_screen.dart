import "package:carousel_slider/carousel_slider.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

import "package:firka/app/app_state.dart";
import "package:firka/ui/components/firka_icon_button.dart";
import "package:firka/ui/phone/screens/themes/preview/theme_preview_data.dart";
import "package:firka/ui/phone/screens/themes/preview/theme_preview_pages.dart";
import "package:firka/ui/phone/screens/themes/sheets/theme_sheets.dart";
import "package:firka/ui/phone/screens/themes/user_theme.dart";
import "package:firka/ui/phone/screens/themes/widgets/theme_name_label.dart";
import "package:firka/ui/phone/screens/themes/widgets/theme_swatch_icon.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";

class ThemeScreen extends StatefulWidget {
  final AppInitialization data;
  final ThemeScreenArgs args;

  const ThemeScreen(this.data, this.args, {super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late final ThemePreviewData _preview;

  UserTheme get _theme => widget.args.theme;

  @override
  void initState() {
    super.initState();
    _preview = ThemePreviewData.build();
  }

  String get _originLabel {
    final l10n = widget.data.l10n;
    switch (_theme.origin) {
      case ThemeOrigin.builtin:
        return l10n.s_c_themes_builtin_label;
      case ThemeOrigin.own:
        return l10n.s_c_themes_own_label;
      case ThemeOrigin.downloaded:
        return l10n.s_c_themes_imported_label;
    }
  }

  Future<void> _delete() async {
    final confirmed = await showThemeDeleteSheet(context, widget.data.l10n);
    if (!confirmed || !mounted) return;
    await widget.args.onDelete(_theme.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.data.l10n;

    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                  Transform.translate(
                    offset: const Offset(-4, 1),
                    child: Text(
                      l10n.s_c_theme_header,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThemeSwatchIcon(swatch: _theme.swatch, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ThemeNameLabel(
                          name: _theme.name,
                          editable: _theme.canRename,
                          style: appStyle.fonts.H_H2.apply(
                            color: appStyle.colors.textPrimary,
                          ),
                          onChanged: (value) {
                            setState(() => _theme.name = value);
                            widget.args.onChanged();
                          },
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _originLabel,
                          style: appStyle.fonts.B_14R.apply(
                            color: appStyle.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      if (_theme.isOwn) ...[
                        FirkaIconButton(
                          onTap: () {},
                          child: FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.editPen4Line,
                            size: 18,
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                        FirkaIconButton(
                          onTap: () {},
                          child: FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.shareLine,
                            size: 18,
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                      ],
                      if (_theme.canDelete)
                        FirkaIconButton(
                          onTap: _delete,
                          color: appStyle.colors.accent,
                          child: FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.deleteBinLine,
                            size: 18,
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: double.infinity,
                    viewportFraction: 0.72,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: false,
                    padEnds: false,
                  ),
                  items: buildThemePreviewCarouselItems(
                    data: widget.data,
                    preview: _preview,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await widget.args.onUse(_theme.id);
                  if (!context.mounted) return;
                  context.pop();
                },
                child: FirkaCard(
                  color: appStyle.colors.accent,
                  left: const [],
                  center: [
                    Text(
                      l10n.s_c_themes_use,
                      style: appStyle.fonts.B_16SB.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
