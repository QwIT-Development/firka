import 'dart:convert';
import 'dart:io';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:firka/ui/theme/style.dart';

class WidgetCacheHelper {
  static Map<String, dynamic> lessonToJson(LessonCacheModel lesson) {
    return {
      'name': lesson.name,
      'start': lesson.start.toIso8601String(),
      'end': lesson.end.toIso8601String(),
      'dailyNth': lesson.dailyNth,
      'yearlyNth': lesson.yearlyNth,
      'roomName': lesson.roomName,
      'substituteTeacher': lesson.substituteTeacher,
      'teacher': lesson.teacher,
      'topic': lesson.topic,
      'state': lesson.state,
      'type': lesson.type,
      // Backward-compatibility aliases for legacy receivers
      'Nev': lesson.name,
      'KezdetIdopont': lesson.start.toIso8601String(),
      'VegIdopont': lesson.end.toIso8601String(),
      'Oraszam': lesson.dailyNth,
      'TeremNeve': lesson.roomName,
      'HelyettesTanarNeve': lesson.substituteTeacher,
    };
  }

  static Map<String, dynamic> toJson(
    FirkaStyle? style,
    List<LessonCacheModel> timetable, {
    Map<String, dynamic>? existingColors,
  }) {
    final timetableJson = timetable.map(lessonToJson).toList();
    final colors = style != null
        ? _colorsMap(style)
        : (existingColors ?? _defaultColors());
    return {'colors': colors, 'timetable': timetableJson};
  }

  static Map<String, dynamic> toAndroidWidgetJson(
    FirkaStyle style,
    List<Lesson> timetable,
  ) {
    final timetableJson = <Map<String, dynamic>>[];
    for (var lesson in timetable) {
      timetableJson.add({
        'name': lesson.name,
        'start': lesson.start.toUtc().toIso8601String(),
        'end': lesson.end.toUtc().toIso8601String(),
        'dailyNth': lesson.lessonNumber,
        'roomName': lesson.roomName,
        'substituteTeacher': lesson.substituteTeacher,
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

  static Map<String, dynamic> _defaultColors() {
    return {
      'background': 0xFFFAFFF0,
      'backgroundAmoled': 0xFF000000,
      'background0p': 0x00000000,
      'success': 0xFF2E7D32,
      'textPrimary': 0xFF1B1C18,
      'textSecondary': 0xFF45483D,
      'textTertiary': 0xFF76786B,
      'card': 0xFFEFF4E3,
      'cardTranslucent': 0xDDEFF4E3,
      'buttonSecondaryFill': 0xFFE0E5D4,
      'accent': 0xFF4C662B,
      'secondary': 0xFF586249,
      'shadowColor': 0x1A000000,
      'a15p': 0x264C662B,
      'warningAccent': 0xFFE65100,
      'warningText': 0xFFBF360C,
      'warning15p': 0x26E65100,
      'warningCard': 0xFFFFE0B2,
      'errorAccent': 0xFFBA1A1A,
      'errorText': 0xFFBA1A1A,
      'error15p': 0x26BA1A1A,
      'errorCard': 0xFFFFDAD6,
      'grade5': 0xFF4C662B,
      'grade4': 0xFF688837,
      'grade3': 0xFFE6A000,
      'grade2': 0xFFE66A00,
      'grade1': 0xFFBA1A1A,
    };
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

  static Future<void> refreshWidget() async {
    if (!Platform.isAndroid) return;
    try {
      await HomeWidget.updateWidget(
        name: 'TimetableWidget',
        qualifiedAndroidName: 'app.firka.naplo.glance.TimetableWidgetReceiver',
      );
      try {
        const channel = MethodChannel("firka.app/main");
        await channel.invokeMethod<void>('refreshTimetableWidget');
      } catch (_) {}
    } catch (e) {
      debugPrint('Error refreshing timetable widget: $e');
    }
  }

  static Future<void> updateWidgetCacheFromLessons(
    List<LessonCacheModel> lessons, {
    FirkaStyle? style,
    String? displayDate,
  }) async {
    final dataDir = await getApplicationDocumentsDirectory();
    final widgetFile = File(p.join(dataDir.path, "widget_state.json"));

    Map<String, dynamic>? existingColors;
    if (style == null && await widgetFile.exists()) {
      try {
        final content = jsonDecode(await widgetFile.readAsString());
        if (content is Map && content['colors'] is Map) {
          existingColors = Map<String, dynamic>.from(content['colors']);
        }
      } catch (_) {}
    }

    final data = toJson(style, lessons, existingColors: existingColors);
    if (displayDate != null) {
      data['displayDate'] = displayDate;
    }

    await widgetFile.writeAsString(jsonEncode(data));
    await refreshWidget();
  }

  static Future<void> updateWidgetCacheFromIsar({
    FirkaStyle? style,
    String? displayDate,
  }) async {
    try {
      final now = timeNow();
      final start = now.subtract(const Duration(days: 7));
      final end = now.add(const Duration(days: 14));
      var lessons = await isarInit.lessonCacheModels
          .filter()
          .startBetween(start, end)
          .sortByStart()
          .findAll();
      if (lessons.isEmpty) {
        lessons = await isarInit.lessonCacheModels.where().sortByStart().findAll();
      }
      await updateWidgetCacheFromLessons(
        lessons,
        style: style,
        displayDate: displayDate,
      );
    } catch (e) {
      debugPrint('Error updating widget cache from Isar: $e');
    }
  }

  static Future<void> updateWidgetCache(
    FirkaStyle style,
    KretaClient client,
  ) async {
    final now = timeNow();
    final start = now.subtract(const Duration(days: 7));
    final end = now.add(const Duration(days: 14));
    final lessons = await client.getLessons(start, end);
    await updateWidgetCacheFromLessons(lessons, style: style);
  }

  static Future<void> generateWidgetStateForDate(
    DateTime date,
    FirkaStyle style,
    KretaClient client,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59));
    final lessons = await client.getLessons(dayStart, dayEnd);
    final displayDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await updateWidgetCacheFromLessons(
      lessons,
      style: style,
      displayDate: displayDate,
    );
  }
}
