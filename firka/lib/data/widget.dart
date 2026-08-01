import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/data/ios_widget_helper.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:firka/ui/theme/style.dart';

class WidgetCacheHelper {
  static Map<String, dynamic> toJson(
    FirkaStyle style,
    List<LessonCacheModel> timetable,
  ) {
    List<Map<String, dynamic>> timetableJson = [];

    return {'colors': _colorsMap(style), 'timetable': timetableJson};
  }

  static Map<String, dynamic> toAndroidWidgetJson(
    FirkaStyle style,
    List<Lesson> timetable,
  ) {
    final timetableJson = <Map<String, dynamic>>[];
    for (var lesson in timetable) {
      timetableJson.add({
        'Nev': lesson.name,
        'KezdetIdopont': lesson.start.toUtc().toIso8601String(),
        'VegIdopont': lesson.end.toUtc().toIso8601String(),
        'Oraszam': lesson.lessonNumber,
        'TeremNeve': lesson.roomName,
        'HelyettesTanarNeve': lesson.substituteTeacher,
      });
    }
    return {'colors': _colorsMap(style), 'timetable': timetableJson};
  }

  static Map<String, dynamic> _colorsMap(FirkaStyle style) {
    return {
      'background': style.colors.background.toARGB32(),
      'backgroundAmoled': style.colors.backgroundAmoled.toARGB32(),
      'background0p': style.colors.background0p.toARGB32(),
      'success': style.colors.success.toARGB32(),
      'textPrimary': style.colors.textPrimary.toARGB32(),
      'textSecondary': style.colors.textSecondary.toARGB32(),
      'textTertiary': style.colors.textTertiary.toARGB32(),
      'card': style.colors.card.toARGB32(),
      'cardTranslucent': style.colors.cardTranslucent.toARGB32(),
      'buttonSecondaryFill': style.colors.buttonSecondaryFill.toARGB32(),
      'accent': style.colors.accent.toARGB32(),
      'secondary': style.colors.secondary.toARGB32(),
      'shadowColor': style.colors.shadowColor.toARGB32(),
      'a15p': style.colors.a15p.toARGB32(),
      'warningAccent': style.colors.warningAccent.toARGB32(),
      'warningText': style.colors.warningText.toARGB32(),
      'warning15p': style.colors.warning15p.toARGB32(),
      'warningCard': style.colors.warningCard.toARGB32(),
      'errorAccent': style.colors.errorAccent.toARGB32(),
      'errorText': style.colors.errorText.toARGB32(),
      'error15p': style.colors.error15p.toARGB32(),
      'errorCard': style.colors.errorCard.toARGB32(),
      'grade5': style.colors.grade5.toARGB32(),
      'grade4': style.colors.grade4.toARGB32(),
      'grade3': style.colors.grade3.toARGB32(),
      'grade2': style.colors.grade2.toARGB32(),
      'grade1': style.colors.grade1.toARGB32(),
    };
  }

  static Future<void> updateWidgetCache(
    FirkaStyle style,
    KretaClient client,
  ) async {
    final dataDir = await getApplicationDocumentsDirectory();

    final now = timeNow();

    final start = now.subtract(Duration(days: 7));
    final end = now.add(Duration(days: 14));
    final lessons = await client.getLessons(start, end);

    final widgetFile = File(p.join(dataDir.path, "widget_state.json"));

    widgetFile.writeAsString(
      jsonEncode(WidgetCacheHelper.toJson(style, lessons)),
    );
  }

  static Future<void> generateWidgetStateForDate(
    DateTime date,
    FirkaStyle style,
    KretaClient client,
  ) async {
    final dataDir = await getApplicationDocumentsDirectory();
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(Duration(hours: 23, minutes: 59));

    final json = toJson(style, []);
    json['displayDate'] =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final widgetFile = File(p.join(dataDir.path, "widget_state.json"));
    await widgetFile.writeAsString(jsonEncode(json));
  }

  /// Comprehensive iOS widget refresh that collects all necessary data
  /// Call this on: app open, user switch, data refresh
  static Future<void> refreshIOSWidgets(
    KretaClient client,
    SettingsStore settings,
  ) async {
    if (!Platform.isIOS) return;

    try {
      final langIndex =
          (settings.group("settings").subGroup("application")["language"]
                  as SettingsItemsRadio)
              .activeIndex;
      String locale;
      switch (langIndex) {
        case 1:
          locale = 'hu';
          break;
        case 2:
          locale = 'en';
          break;
        case 3:
          locale = 'de';
          break;
        default:
          locale = 'hu';
      }

      final themeIndex =
          (settings.group("settings").subGroup("customization")["theme"]
                  as SettingsItemsRadio)
              .activeIndex;
      String theme;
      switch (themeIndex) {
        case 1:
          theme = 'light';
          break;
        case 2:
          theme = 'dark';
          break;
        default:
          theme =
              SchedulerBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.light
              ? 'light'
              : 'dark';
      }

      final now = timeNow();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final tomorrowMidnight = todayMidnight.add(Duration(days: 1));

      final todayResponse = await client.getLessons(
        todayMidnight,
        todayMidnight.add(Duration(hours: 23, minutes: 59)),
      );
      final tomorrowResponse = await client.getLessons(
        tomorrowMidnight,
        tomorrowMidnight.add(Duration(hours: 23, minutes: 59)),
      );

      final todayLessons = [];
      final tomorrowLessons = [];

      debugPrint(
        'iOS widget refresh: ${todayLessons.length} today lessons, ${tomorrowLessons.length} tomorrow lessons',
      );

      List<Lesson> nextSchoolDayLessons = [];
      DateTime? nextSchoolDayDate;
      if (tomorrowLessons.isEmpty) {
        for (int i = 2; i <= 7; i++) {
          final dayMidnight = todayMidnight.add(Duration(days: i));
          final dayResponse = await client.getLessons(
            dayMidnight,
            dayMidnight.add(Duration(hours: 23, minutes: 59)),
          );
          final dayLessons = <Lesson>[];
          if (dayLessons.isNotEmpty) {
            nextSchoolDayLessons = dayLessons;
            nextSchoolDayDate = dayMidnight;
            debugPrint(
              'iOS widget: Next school day found $i days ahead with ${dayLessons.length} lessons',
            );
            break;
          }
        }
      }

      final gradesResponse = await client.getGrades();
      final grades = [];

      debugPrint(
        'iOS widget refresh: ${grades.length} grades fetched (cached: ${gradesResponse})',
      );

      final Map<String, double> subjectAverages = {};
      final HashSet<Subject> subjects = HashSet(
        hashCode: (s) => s.uid.hashCode,
        equals: (s, s2) => s.uid == s2.uid,
      );

      subjects.addAll(grades.map((g) => g.subject));

      WidgetBreakInfo? currentBreak;

      await IOSWidgetHelper.updateWidgetData(
        locale: locale,
        theme: theme,
        todayLessons: [],
        tomorrowLessons: [],
        nextSchoolDayLessons: nextSchoolDayLessons,
        nextSchoolDayDate: nextSchoolDayDate,
        grades: [],
        subjectAverages: subjectAverages,
        overallAverage: 0.0,
        currentBreak: currentBreak,
      );

      debugPrint('iOS widgets refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing iOS widgets: $e');
    }
  }

  /// Clear iOS widget data (call on logout)
  static Future<void> clearIOSWidgets() async {
    if (!Platform.isIOS) return;

    try {
      await IOSWidgetHelper.updateWidgetData(
        locale: 'hu',
        theme: 'light',
        todayLessons: [],
        tomorrowLessons: [],
        grades: [],
        subjectAverages: {},
        overallAverage: null,
        currentBreak: null,
      );
      debugPrint('iOS widgets cleared');
    } catch (e) {
      debugPrint('Error clearing iOS widgets: $e');
    }
  }
}
