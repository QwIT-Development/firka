import 'dart:convert';
import 'dart:math';

import 'package:isar_community/isar.dart';

import 'package:kreta_api/kreta_api.dart';

import 'package:firka_wear/data/models/generic_cache_model.dart';
import 'package:firka_wear/data/models/token_model.dart';

/// Persists and loads synced data (timetable, grades, lastSyncAt) from the phone.
/// Uses [GenericCacheModel] for metadata, timetable (single JSON blob), and grades.
class WearSyncStore {
  WearSyncStore(this.isar);

  final Isar isar;

  List<Lesson> _timetable = [];
  List<Grade> _grades = [];
  DateTime? _lastSyncAt;

  List<Lesson> get timetable => List.unmodifiable(_timetable);
  List<Grade> get grades => List.unmodifiable(_grades);
  DateTime? get lastSyncAt => _lastSyncAt;

  /// True if we have no data or data is older than 1 hour.
  bool get needsSync {
    if (_lastSyncAt == null) return true;
    return DateTime.now().difference(_lastSyncAt!) > const Duration(hours: 1);
  }

  static int _genericCacheKey(int studentIdNorm, CacheId id) {
    return (studentIdNorm + (id.index + 1) * pow(10, 11)) as int;
  }

  Future<int?> _getStudentIdNorm() async {
    final token = await isar.tokenModels.where().findFirst();
    return token?.studentIdNorm;
  }

  Future<void> load() async {
    try {
      final studentIdNorm = await _getStudentIdNorm();
      if (studentIdNorm == null) return;

      final metadataKey = _genericCacheKey(
        studentIdNorm,
        CacheId.wearSyncMetadata,
      );
      final metadataCache = await isar.genericCacheModels.get(metadataKey);
      if (metadataCache?.cacheData != null) {
        final meta =
            jsonDecode(metadataCache!.cacheData!) as Map<String, dynamic>;
        _lastSyncAt = meta['lastSyncAt'] != null
            ? DateTime.parse(meta['lastSyncAt'] as String)
            : null;
      }

      final timetableKey = _genericCacheKey(
        studentIdNorm,
        CacheId.wearSyncTimetable,
      );
      final timetableCache = await isar.genericCacheModels.get(timetableKey);
      if (timetableCache?.cacheData != null) {
        final raw = jsonDecode(timetableCache!.cacheData!) as List<dynamic>;
        _timetable = raw
            .map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      final gradesKey = _genericCacheKey(studentIdNorm, CacheId.getGrades);
      final gradesCache = await isar.genericCacheModels.get(gradesKey);
      if (gradesCache?.cacheData != null) {
        final raw = jsonDecode(gradesCache!.cacheData!) as List<dynamic>;
        _grades = raw
            .map((e) => Grade.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> save({
    required DateTime? lastSyncAt,
    required List<Lesson> timetable,
    required List<Grade> grades,
  }) async {
    final studentIdNorm = await _getStudentIdNorm();
    if (studentIdNorm == null) return;

    _lastSyncAt = lastSyncAt;
    _timetable = timetable;
    _grades = grades;

    await isar.writeTxn(() async {
      final metadataKey = _genericCacheKey(
        studentIdNorm,
        CacheId.wearSyncMetadata,
      );
      await isar.genericCacheModels.put(
        GenericCacheModel()
          ..cacheKey = metadataKey
          ..cacheData = jsonEncode({
            'lastSyncAt': lastSyncAt?.toUtc().toIso8601String(),
          }),
      );

      final timetableKey = _genericCacheKey(
        studentIdNorm,
        CacheId.wearSyncTimetable,
      );
      await isar.genericCacheModels.put(
        GenericCacheModel()
          ..cacheKey = timetableKey
          ..cacheData = jsonEncode(timetable.map((e) => e.toJson()).toList()),
      );

      final gradesKey = _genericCacheKey(studentIdNorm, CacheId.getGrades);
      await isar.genericCacheModels.put(
        GenericCacheModel()
          ..cacheKey = gradesKey
          ..cacheData = jsonEncode(grades.map((e) => e.toJson()).toList()),
      );
    });
  }

  /// Returns lessons that fall on [date] (compare by calendar day via lesson start).
  List<Lesson> getLessonsForDate(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    return _timetable
        .where((l) =>
            l.start.year == y && l.start.month == m && l.start.day == d)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }
}
