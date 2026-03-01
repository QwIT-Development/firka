import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/api/model/grade.dart';
import 'package:firka/api/model/timetable.dart';
import 'package:firka/core/debug_helper.dart';

/// File name for the Wear OS sync cache written by the phone (Dart isolate or main).
const String wearSyncCacheFileName = 'wear_sync_cache.json';

/// Returns the 2-week range: Monday 00:00 of current week through Sunday 23:59 of next week.
(DateTime start, DateTime end) getWearSyncTimetableRange() {
  final now = timeNow();
  final mondayThisWeek = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final sundayNextWeek = mondayThisWeek
      .add(const Duration(days: 14))
      .subtract(const Duration(milliseconds: 1));
  return (mondayThisWeek, sundayNextWeek);
}

/// Builds the sync payload (same shape as init_data / sync_data): timetable (2 weeks), grades, lastSyncAt.
Future<Map<String, dynamic>?> buildWearSyncPayload(KretaClient client) async {
  final (start, end) = getWearSyncTimetableRange();
  final timetableResp = await client.getTimeTable(
    start,
    end,
    forceCache: false,
  );
  if (timetableResp.err != null && timetableResp.response == null) {
    return null;
  }
  final gradesResp = await client.getGrades(forceCache: false);
  if (gradesResp.err != null && gradesResp.response == null) {
    return null;
  }
  final now = timeNow();
  final timetable = (timetableResp.response ?? <Lesson>[])
      .map((l) => l.toJson())
      .toList();
  final grades = (gradesResp.response ?? <Grade>[])
      .map((g) => g.toJson())
      .toList();
  return {
    'lastSyncAt': now.toUtc().toIso8601String(),
    'timetable': timetable,
    'grades': grades,
  };
}

/// Returns the full path for the Wear sync cache file.
Future<String> getWearSyncCachePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$wearSyncCacheFileName';
}

/// Writes the sync payload to the cache file at [path].
Future<void> writeWearSyncCache(
  String path,
  Map<String, dynamic> payload,
) async {
  final file = File(path);
  await file.writeAsString(jsonEncode(payload));
}
