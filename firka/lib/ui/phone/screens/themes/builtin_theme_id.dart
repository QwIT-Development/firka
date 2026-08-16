import "package:firka_common/ui/theme/core_theme.dart";
import "package:firka_common/ui/theme/grade_theme.dart";

const defaultCoreThemeId = "firka";
const defaultGradeThemeId = "firka";
const defaultBuiltinThemeId = "builtin-firka-firka";

String composeBuiltinThemeId(String coreId, String gradeId) {
  return "builtin-$coreId-$gradeId";
}

bool isBuiltinThemeId(String id) {
  return id == "builtin" || id.startsWith("builtin-");
}

/// Parses `builtin-{core}-{grade}`. Legacy `builtin` and malformed ids
/// fall back to firka / firka. Map lookup fallback happens at resolve sites.
(String coreId, String gradeId) parseBuiltinThemeId(String id) {
  if (id == "builtin" || id == defaultBuiltinThemeId) {
    return (defaultCoreThemeId, defaultGradeThemeId);
  }
  if (!id.startsWith("builtin-")) {
    return (defaultCoreThemeId, defaultGradeThemeId);
  }
  final rest = id.substring("builtin-".length);
  final sep = rest.indexOf("-");
  if (sep <= 0 || sep >= rest.length - 1) {
    return (defaultCoreThemeId, defaultGradeThemeId);
  }
  final coreId = rest.substring(0, sep);
  final gradeId = rest.substring(sep + 1);
  if (coreId.isEmpty || gradeId.isEmpty) {
    return (defaultCoreThemeId, defaultGradeThemeId);
  }
  return (
    coreThemes.containsKey(coreId) ? coreId : defaultCoreThemeId,
    gradeThemes.containsKey(gradeId) ? gradeId : defaultGradeThemeId,
  );
}

String normalizeSelectedThemeId(String id) {
  if (id == "builtin") return defaultBuiltinThemeId;
  return id;
}
