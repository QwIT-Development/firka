import 'dart:convert';
import 'dart:io';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/debug_helper.dart';
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

    final json = toJson(style, []);
    json['displayDate'] =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final widgetFile = File(p.join(dataDir.path, "widget_state.json"));
    await widgetFile.writeAsString(jsonEncode(json));
  }
}
