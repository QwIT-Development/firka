import 'dart:convert';
import 'dart:io';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/api/model/grade.dart';
import 'package:firka/api/model/timetable.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/data/ios_widget_helper.dart';
import 'package:firka/core/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:firka/ui/theme/style.dart';

class WidgetCacheHelper {
  static Map<String, dynamic> toJson(FirkaStyle style, List<Lesson> timetable) {
    List<Map<String, dynamic>> timetableJson = [];

    for (var lesson in timetable) {
      timetableJson.add(lesson.toJson());
    }

    return {
      'colors': {
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
      },
      'timetable': timetableJson,
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
    final lessons = await client.getTimeTable(start, end, forceCache: false);

    final widgetFile = File(p.join(dataDir.path, "widget_state.json"));

    if (lessons.response != null) {
      debugPrint(
        'Android widget cache: ${lessons.response!.length} lessons (cached: ${lessons.cached})',
      );
      widgetFile.writeAsString(
        jsonEncode(WidgetCacheHelper.toJson(style, lessons.response!)),
      );
    } else {
      debugPrint('Android widget cache: No lessons to cache');
    }
  }

  static Future<void> updateIOSWidgets({
    required String locale,
    required String theme,
    required List<Lesson> todayLessons,
    required List<Lesson> tomorrowLessons,
    List<Lesson> nextSchoolDayLessons = const [],
    DateTime? nextSchoolDayDate,
    required List<Grade> grades,
    required Map<String, double> subjectAverages,
    required double? overallAverage,
    WidgetBreakInfo? currentBreak,
  }) async {
    await IOSWidgetHelper.updateWidgetData(
      locale: locale,
      theme: theme,
      todayLessons: todayLessons,
      tomorrowLessons: tomorrowLessons,
      nextSchoolDayLessons: nextSchoolDayLessons,
      nextSchoolDayDate: nextSchoolDayDate,
      grades: grades,
      subjectAverages: subjectAverages,
      overallAverage: overallAverage,
      currentBreak: currentBreak,
    );
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

      final todayResponse = await client.getTimeTable(
        todayMidnight,
        todayMidnight.add(Duration(hours: 23, minutes: 59)),
        forceCache: false,
      );
      final tomorrowResponse = await client.getTimeTable(
        tomorrowMidnight,
        tomorrowMidnight.add(Duration(hours: 23, minutes: 59)),
        forceCache: false,
      );

      final todayLessons = todayResponse.response ?? [];
      final tomorrowLessons = tomorrowResponse.response ?? [];

      debugPrint(
        'iOS widget refresh: ${todayLessons.length} today lessons, ${tomorrowLessons.length} tomorrow lessons',
      );

      List<Lesson> nextSchoolDayLessons = [];
      DateTime? nextSchoolDayDate;
      if (tomorrowLessons.isEmpty) {
        for (int i = 2; i <= 7; i++) {
          final dayMidnight = todayMidnight.add(Duration(days: i));
          final dayResponse = await client.getTimeTable(
            dayMidnight,
            dayMidnight.add(Duration(hours: 23, minutes: 59)),
            forceCache: false,
          );
          final dayLessons = dayResponse.response ?? [];
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

      final gradesResponse = await client.getGrades(forceCache: false);
      final grades = gradesResponse.response ?? [];

      debugPrint(
        'iOS widget refresh: ${grades.length} grades fetched (cached: ${gradesResponse.cached})',
      );

      final Map<String, double> subjectAverages = {};
      final Set<String> subjectUids = {};

      for (var grade in grades) {
        subjectUids.add(grade.subject.uid);
      }

      double overallSum = 0;
      int validSubjectCount = 0;

      for (var uid in subjectUids) {
        final subjectGrades = grades
            .where((g) => g.subject.uid == uid)
            .toList();
        final avg = _calculateWeightedAverage(subjectGrades);
        if (!avg.isNaN && avg > 0) {
          subjectAverages[uid] = avg;
          overallSum += avg;
          validSubjectCount++;
        }
      }

      final double? overallAverage = validSubjectCount > 0
          ? overallSum / validSubjectCount
          : null;

      WidgetBreakInfo? currentBreak;

      await updateIOSWidgets(
        locale: locale,
        theme: theme,
        todayLessons: todayLessons,
        tomorrowLessons: tomorrowLessons,
        nextSchoolDayLessons: nextSchoolDayLessons,
        nextSchoolDayDate: nextSchoolDayDate,
        grades: grades,
        subjectAverages: subjectAverages,
        overallAverage: overallAverage,
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
      await updateIOSWidgets(
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

  /// Calculate weighted average for a list of grades
  static double _calculateWeightedAverage(List<Grade> grades) {
    var weightTotal = 0.0;
    var sum = 0.0;

    for (var grade in grades) {
      if (grade.numericValue != null) {
        var weight = (grade.weightPercentage ?? 100) / 100.0;
        weightTotal += weight;
        sum += grade.numericValue! * weight;
      }
    }

    if (weightTotal == 0) return double.nan;
    return sum / weightTotal;
  }
}
