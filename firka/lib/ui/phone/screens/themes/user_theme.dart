import "package:flutter/material.dart";

import "package:firka_common/data/models/user_theme_model.dart";
import "package:firka_common/ui/theme/core_theme.dart";
import "package:firka_common/ui/theme/grade_theme.dart";

import "package:firka/ui/phone/screens/themes/builtin_theme_id.dart";
import "package:firka/ui/theme/style.dart";

enum ThemeOrigin { builtin, own, downloaded }

class UserTheme {
  final String id;
  String name;
  final ThemeOrigin origin;
  final List<Color> swatch;

  UserTheme({
    required this.id,
    required this.name,
    required this.origin,
    required this.swatch,
  });

  bool get isBuiltin =>
      origin == ThemeOrigin.builtin || isBuiltinThemeId(id);
  bool get isOwn => origin == ThemeOrigin.own && !isBuiltinThemeId(id);
  bool get isDownloaded => origin == ThemeOrigin.downloaded;
  bool get canRename => isOwn;
  bool get canDelete => !isBuiltin;

  static List<Color> swatchFromCore(CoreTheme core, {bool isLight = true}) {
    final colors = core.forBrightness(isLight);
    return [colors.accent, colors.textPrimary, colors.background];
  }

  static List<Color> swatchFromAppStyle() {
    return [
      appStyle.colors.accent,
      appStyle.colors.textPrimary,
      appStyle.colors.background,
    ];
  }

  static UserTheme builtin(
    String displayName, {
    String coreId = defaultCoreThemeId,
    String gradeId = defaultGradeThemeId,
    bool isLight = true,
  }) {
    final core = resolveCore(coreId);
    final grade = resolveGrade(gradeId);
    return UserTheme(
      id: composeBuiltinThemeId(core.id, grade.id),
      name: displayName,
      origin: ThemeOrigin.builtin,
      swatch: swatchFromCore(core, isLight: isLight),
    );
  }

  factory UserTheme.fromModel(UserThemeModel model) {
    return UserTheme(
      id: model.themeId,
      name: model.name,
      origin: switch (model.origin) {
        "downloaded" => ThemeOrigin.downloaded,
        _ => ThemeOrigin.own,
      },
      swatch: model.swatchArgb.map(Color.new).toList(),
    );
  }

  UserThemeModel toModel() {
    return UserThemeModel()
      ..themeId = id
      ..name = name
      ..origin = switch (origin) {
        ThemeOrigin.downloaded => "downloaded",
        ThemeOrigin.own || ThemeOrigin.builtin => "own",
      }
      ..swatchArgb = swatch.map((c) => c.toARGB32()).toList();
  }
}

class ThemeScreenArgs {
  final UserTheme theme;
  final Future<void> Function(String id) onUse;
  final Future<void> Function(String id) onDelete;
  final VoidCallback onChanged;

  const ThemeScreenArgs({
    required this.theme,
    required this.onUse,
    required this.onDelete,
    required this.onChanged,
  });
}
