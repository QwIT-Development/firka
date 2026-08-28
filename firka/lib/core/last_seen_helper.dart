import "dart:convert";

import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";
import "package:firka_common/data/last_seen.dart";
import "package:firka_common/data/models/grade_cache_model.dart";

class LastSeenHelper {
  static const grades = "grades";
  static const homework = "homework";
  static const tests = "tests";
  static const omissions = "omissions";
  static const messages = "messages";

  static Map<String, dynamic> _read() {
    try {
      final decoded = jsonDecode(Settings.lastSeen.value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static LastSeen? get(int accountKey, String kind) {
    final account = _read()["$accountKey"];
    if (account is! Map) return null;

    return LastSeen.parse(account[kind] as String?);
  }

  static List<GradeCacheModel> openedGrades(
    int accountKey,
    List<GradeCacheModel> grades,
  ) {
    if (!Settings.surpriseGrades.value) return grades;

    final seen = get(accountKey, LastSeenHelper.grades);
    if (seen == null) return grades;

    final hidden = LastSeen.newerThan(
      grades,
      seen,
    ).map((g) => g.cacheKey).toSet();

    return grades.where((g) => !hidden.contains(g.cacheKey)).toList();
  }

  static Future<void> set(int accountKey, String kind, LastSeen seen) async {
    final all = _read();
    final account = all["$accountKey"];
    final entry = account is Map
        ? Map<String, dynamic>.from(account)
        : <String, dynamic>{};

    entry[kind] = seen.toText();
    all["$accountKey"] = entry;

    await Settings.lastSeen.set(jsonEncode(all));
  }
}
