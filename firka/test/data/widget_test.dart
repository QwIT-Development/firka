import 'dart:convert';
import 'dart:io';

import 'package:firka/data/widget.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetCacheHelper serialization', () {
    test('serializes LessonCacheModel fields without custom DTO', () {
      final start = DateTime(2026, 9, 8, 8, 0);
      final end = DateTime(2026, 9, 8, 8, 45);

      final lesson = LessonCacheModel()
        ..name = 'Matematika'
        ..start = start
        ..end = end
        ..dailyNth = 1
        ..yearlyNth = 12
        ..roomName = '101'
        ..teacher = 'Kovács Péter'
        ..substituteTeacher = 'Nagy Anna'
        ..topic = 'Trigonometria'
        ..state = 'Megtartott óra'
        ..type = 'Tanóra';

      final json = WidgetCacheHelper.lessonToJson(lesson);

      // Check standard LessonCacheModel properties
      expect(json['name'], equals('Matematika'));
      expect(json['start'], equals(start.toIso8601String()));
      expect(json['end'], equals(end.toIso8601String()));
      expect(json['dailyNth'], equals(1));
      expect(json['yearlyNth'], equals(12));
      expect(json['roomName'], equals('101'));
      expect(json['teacher'], equals('Kovács Péter'));
      expect(json['substituteTeacher'], equals('Nagy Anna'));
      expect(json['topic'], equals('Trigonometria'));
      expect(json['state'], equals('Megtartott óra'));
      expect(json['type'], equals('Tanóra'));

      // Check backward compatibility aliases
      expect(json['Nev'], equals('Matematika'));
      expect(json['KezdetIdopont'], equals(start.toIso8601String()));
      expect(json['VegIdopont'], equals(end.toIso8601String()));
      expect(json['Oraszam'], equals(1));
      expect(json['TeremNeve'], equals('101'));
      expect(json['HelyettesTanarNeve'], equals('Nagy Anna'));
    });

    test('toJson generates complete widget state with colors and timetable', () {
      final start = DateTime(2026, 9, 8, 8, 55);
      final end = DateTime(2026, 9, 8, 9, 40);

      final lesson = LessonCacheModel()
        ..name = 'Történelem'
        ..start = start
        ..end = end
        ..dailyNth = 2
        ..state = 'Megtartott óra'
        ..type = 'Tanóra';

      final result = WidgetCacheHelper.toJson(null, [lesson]);

      expect(result.containsKey('colors'), isTrue);
      expect(result.containsKey('timetable'), isTrue);
      expect(result['timetable'], hasLength(1));

      final first = (result['timetable'] as List).first as Map<String, dynamic>;
      expect(first['name'], equals('Történelem'));
      expect(first['dailyNth'], equals(2));
    });

    test('toJson preserves existing colors in headless mode when style is null', () {
      final customColors = <String, dynamic>{
        'background': 0xFF123456,
        'card': 0xFF654321,
      };

      final result = WidgetCacheHelper.toJson(
        null,
        [],
        existingColors: customColors,
      );

      expect(result['colors']['background'], equals(0xFF123456));
      expect(result['colors']['card'], equals(0xFF654321));
      expect(result['timetable'], isEmpty);
    });
  });

  group('Timetable change detection for FCM wakeups', () {
    test('detects change when timetable content differs', () {
      final tempDir = Directory.systemTemp.createTempSync('widget_test_');
      final widgetFile = File('${tempDir.path}/widget_state.json');

      final start1 = DateTime(2026, 9, 8, 8, 0);
      final end1 = DateTime(2026, 9, 8, 8, 45);

      final oldLesson = LessonCacheModel()
        ..name = 'Angol'
        ..start = start1
        ..end = end1
        ..dailyNth = 1
        ..roomName = '102'
        ..state = 'Megtartott óra'
        ..type = 'Tanóra';

      final initialData = WidgetCacheHelper.toJson(null, [oldLesson]);
      widgetFile.writeAsStringSync(jsonEncode(initialData));

      // Same lesson: no change
      final readJson = jsonDecode(widgetFile.readAsStringSync());
      final tt = readJson['timetable'] as List;
      expect(tt[0]['name'], equals(oldLesson.name));
      expect(tt[0]['roomName'], equals(oldLesson.roomName));

      // Substitute teacher assigned: changed!
      final updatedLesson = LessonCacheModel()
        ..name = 'Angol'
        ..start = start1
        ..end = end1
        ..dailyNth = 1
        ..roomName = '102'
        ..substituteTeacher = 'Kiss Éva'
        ..state = 'Megtartott óra'
        ..type = 'Tanóra';

      expect(tt[0]['substituteTeacher'], isNot(equals(updatedLesson.substituteTeacher)));

      tempDir.deleteSync(recursive: true);
    });
  });
}
