import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:isar_community/isar.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

import "package:firka/app/app_state.dart";
import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";
import "package:firka/core/snowflake.dart";
import "package:firka/ui/components/firka_icon_button.dart";
import "package:firka/ui/phone/screens/themes/builtin_theme_id.dart";
import "package:firka/ui/phone/screens/themes/sheets/theme_sheets.dart";
import "package:firka/ui/phone/screens/themes/user_theme.dart";
import "package:firka/ui/phone/screens/themes/widgets/theme_name_label.dart";
import "package:firka/ui/phone/screens/themes/widgets/theme_swatch_icon.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/data/database.dart";
import "package:firka_common/data/models/user_theme_model.dart";
import "package:firka_common/ui/components/firka_card.dart";

class ThemesScreen extends StatefulWidget {
  final AppInitialization data;

  const ThemesScreen(this.data, {super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  late List<UserTheme> _storedThemes;
  late String _selectedId;
  bool _loading = true;

  UserTheme get _builtin => UserTheme.builtin(
    widget.data.l10n.s_c_themes_builtin_name,
    coreId: Settings.selectedCoreThemeId.value,
    gradeId: Settings.selectedGradeThemeId.value,
    isLight: appStyle.isLight,
  );

  @override
  void initState() {
    super.initState();
    _storedThemes = [];
    _selectedId = normalizeSelectedThemeId(Settings.selectedThemeId.value);
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    final stored = await isarInit.userThemeModels.where().findAll();
    if (!mounted) return;

    final normalized = normalizeSelectedThemeId(Settings.selectedThemeId.value);
    if (normalized != Settings.selectedThemeId.value) {
      await Settings.selectedThemeId.set(normalized);
    }

    setState(() {
      _storedThemes = stored.map(UserTheme.fromModel).toList();
      _selectedId = normalized;
      final knownIds = {
        _builtin.id,
        ..._storedThemes.map((t) => t.id),
      };
      if (isBuiltinThemeId(_selectedId)) {
        // Always use the composed builtin id for the current core/grade.
        _selectedId = _builtin.id;
      } else if (!knownIds.contains(_selectedId)) {
        _selectedId = _builtin.id;
      }
      _loading = false;
    });

    if (isBuiltinThemeId(_selectedId) &&
        Settings.selectedThemeId.value != _builtin.id) {
      await Settings.selectedThemeId.set(_builtin.id);
    }
  }

  UserTheme get _selected {
    if (isBuiltinThemeId(_selectedId)) {
      return _builtin;
    }
    return _storedThemes.firstWhere(
      (t) => t.id == _selectedId,
      orElse: () => _builtin,
    );
  }

  List<UserTheme> get _ownThemes =>
      _storedThemes.where((t) => t.isOwn).toList(growable: false);

  List<UserTheme> get _downloadedThemes =>
      _storedThemes.where((t) => t.isDownloaded).toList(growable: false);

  Future<void> _persistTheme(UserTheme theme) async {
    if (theme.isBuiltin) return;
    await isarInit.writeTxn(() async {
      await isarInit.userThemeModels.putByThemeId(theme.toModel());
    });
  }

  Future<void> _deleteTheme(String id) async {
    await isarInit.writeTxn(() async {
      await isarInit.userThemeModels.deleteByThemeId(id);
    });
  }

  Future<void> _setSelected(String id) async {
    final next = isBuiltinThemeId(id) ? _builtin.id : id;
    if (isBuiltinThemeId(next)) {
      final (coreId, gradeId) = parseBuiltinThemeId(next);
      await Settings.selectedCoreThemeId.set(coreId);
      await Settings.selectedGradeThemeId.set(gradeId);
    }
    setState(() => _selectedId = next);
    await Settings.selectedThemeId.set(next);
  }

  Future<void> _selectBuiltin() async {
    final id = composeBuiltinThemeId(
      Settings.selectedCoreThemeId.value,
      Settings.selectedGradeThemeId.value,
    );
    await _setSelected(id);
  }

  Future<void> _createTheme() async {
    final name = await showThemeNameSheet(context, widget.data.l10n);
    if (name == null || !mounted) return;

    final theme = UserTheme(
      id: Snowflake.nextId(),
      name: name,
      origin: ThemeOrigin.own,
      swatch: UserTheme.swatchFromAppStyle(),
    );
    await _persistTheme(theme);
    if (!mounted) return;
    setState(() => _storedThemes.add(theme));
    await _openTheme(theme);
  }

  Future<void> _renameTheme(UserTheme theme, String name) async {
    setState(() => theme.name = name);
    await _persistTheme(theme);
  }

  Future<void> _openTheme(UserTheme theme) async {
    final openTheme = theme.isBuiltin ? _builtin : theme;
    await context.push(
      "/theme",
      extra: ThemeScreenArgs(
        theme: openTheme,
        onUse: (id) => _setSelected(id),
        onDelete: (id) async {
          await _deleteTheme(id);
          if (!mounted) return;
          setState(() {
            _storedThemes.removeWhere((t) => t.id == id);
            if (_selectedId == id) {
              _selectedId = _builtin.id;
            }
          });
          if (isBuiltinThemeId(_selectedId)) {
            await _selectBuiltin();
          }
        },
        onChanged: () {
          _persistTheme(theme);
          setState(() {});
        },
      ),
    );
    if (mounted) setState(() {});
  }

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

  Widget _themeRow(UserTheme theme, {required bool selected}) {
    return GestureDetector(
      onTap: () => _openTheme(theme),
      child: FirkaCard(
        left: [
          ThemeSwatchIcon(swatch: theme.swatch, size: 36),
          const SizedBox(width: 10),
          ThemeNameLabel(
            name: theme.name,
            editable: theme.canRename,
            onChanged: (value) => _renameTheme(theme, value),
          ),
        ],
        right: selected
            ? [_checkMark(), const SizedBox(width: 4)]
            : const [SizedBox(width: 20)],
      ),
    );
  }

  Widget _actionRow({
    required Object icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: FirkaCard(
        left: [
          FirkaIconWidget(
            FirkaIconType.majesticons,
            icon,
            size: 20,
            color: appStyle.colors.textPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: appStyle.fonts.B_16SB.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
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
                  Expanded(
                    child: Row(
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
                            l10n.s_c_my_themes,
                            style: appStyle.fonts.H_H2.apply(
                              color: appStyle.colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      FirkaIconButton(
                        onTap: _createTheme,
                        child: FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.plusLine,
                          size: 20,
                          color: appStyle.colors.accent,
                        ),
                      ),
                      FirkaIconButton(
                        onTap: () {},
                        child: FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.shareLine,
                          size: 20,
                          color: appStyle.colors.accent,
                        ),
                      ),
                      FirkaIconButton(
                        onTap: () {},
                        child: FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.arrowDownCircleLine,
                          size: 20,
                          color: appStyle.colors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          _sectionLabel(l10n.s_c_themes_current),
                          _themeRow(_selected, selected: true),
                          if (!_selected.isBuiltin)
                            _actionRow(
                              icon: Majesticon.shareLine,
                              label: l10n.s_c_themes_share_current,
                              onTap: () {},
                            ),
                          _sectionLabel(l10n.s_c_themes_own),
                          for (final theme in _ownThemes)
                            _themeRow(
                              theme,
                              selected: theme.id == _selectedId,
                            ),
                          _actionRow(
                            icon: Majesticon.plusLine,
                            label: l10n.s_c_themes_create_new,
                            onTap: _createTheme,
                          ),
                          _sectionLabel(l10n.s_c_themes_downloaded),
                          for (final theme in _downloadedThemes)
                            _themeRow(
                              theme,
                              selected: theme.id == _selectedId,
                            ),
                          _actionRow(
                            icon: Majesticon.arrowDownCircleLine,
                            label: l10n.s_c_themes_import,
                            onTap: () {},
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
