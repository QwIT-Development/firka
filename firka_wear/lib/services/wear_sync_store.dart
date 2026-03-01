import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:kreta_api/kreta_api.dart';

const String _syncFileName = 'wear_sync_data.json';

/// Persists and loads synced data (timetable, grades, lastSyncAt) from the phone.
class WearSyncStore {
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

  Future<String> _getSyncFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_syncFileName';
  }

  Future<void> load() async {
    try {
      final path = await _getSyncFilePath();
      final file = File(path);
      if (!await file.exists()) return;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _lastSyncAt = json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null;
      final rawTimetable = json['timetable'] as List<dynamic>? ?? [];
      _timetable = rawTimetable
          .map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final rawGrades = json['grades'] as List<dynamic>? ?? [];
      _grades = rawGrades
          .map((e) => Grade.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {}
  }

  Future<void> save({
    required DateTime? lastSyncAt,
    required List<Lesson> timetable,
    required List<Grade> grades,
  }) async {
    _lastSyncAt = lastSyncAt;
    _timetable = timetable;
    _grades = grades;
    final path = await _getSyncFilePath();
    final file = File(path);
    await file.writeAsString(
      jsonEncode({
        'lastSyncAt': lastSyncAt?.toUtc().toIso8601String(),
        'timetable': timetable.map((e) => e.toJson()).toList(),
        'grades': grades.map((e) => e.toJson()).toList(),
      }),
    );
  }

  /// Returns lessons that fall on [date] (by date string or start date).
  List<Lesson> getLessonsForDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _timetable.where((l) => l.date == dateStr).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }
}
