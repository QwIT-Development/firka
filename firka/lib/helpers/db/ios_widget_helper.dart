import 'dart:convert';
import 'dart:io';

import 'package:firka/helpers/api/model/grade.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IOSWidgetHelper {
  static const _channel = MethodChannel('app.firka/home_widgets');

  static Future<Directory?> _getAppGroupDirectory() async {
    if (!Platform.isIOS) return null;

    try {
      final result = await _channel.invokeMethod<String>('getAppGroupDirectory');
      if (result != null) {
        return Directory(result);
      }
    } catch (e) {
      debugPrint('Error getting app group directory: $e');
    }
    return null;
  }

  static Future<void> updateWidgetData({
    required String locale,
    required String theme,
    required List<Lesson> todayLessons,
    required List<Lesson> tomorrowLessons,
    required List<Grade> grades,
    required Map<String, double> subjectAverages,
    required double? overallAverage,
    WidgetBreakInfo? currentBreak,
  }) async {
    if (!Platform.isIOS) return;

    debugPrint('[IOSWidget] Starting updateWidgetData...');
    debugPrint('[IOSWidget] todayLessons: ${todayLessons.length}, tomorrowLessons: ${tomorrowLessons.length}');
    debugPrint('[IOSWidget] grades: ${grades.length}, subjectAverages: ${subjectAverages.length}');

    final dir = await _getAppGroupDirectory();
    if (dir == null) {
      debugPrint('[IOSWidget] ERROR: App Group directory is null!');
      return;
    }
    debugPrint('[IOSWidget] App Group directory: ${dir.path}');

    final data = {
      'lastUpdated': DateTime.now().toIso8601String(),
      'locale': locale,
      'theme': theme,
      'timetable': {
        'today': todayLessons.map((l) => _lessonToJson(l)).toList(),
        'tomorrow': tomorrowLessons.map((l) => _lessonToJson(l)).toList(),
        'currentBreak': currentBreak != null ? {
          'name': currentBreak.name,
          'nameKey': currentBreak.nameKey,
          'endDate': currentBreak.endDate.toIso8601String(),
        } : null,
      },
      'grades': grades.take(20).map((g) => _gradeToJson(g)).toList(),
      'averages': {
        'overall': overallAverage,
        'subjects': subjectAverages.entries.map((e) => {
          'uid': e.key,
          'name': _getSubjectNameFromGrades(e.key, grades),
          'average': e.value,
          'gradeCount': _getGradeCount(e.key, grades),
        }).toList(),
      },
    };

    final jsonString = jsonEncode(data);
    debugPrint('[IOSWidget] JSON data length: ${jsonString.length} bytes');

    final file = File('${dir.path}/widget_data.json');
    await file.writeAsString(jsonString);
    debugPrint('[IOSWidget] File written to: ${file.path}');

    final exists = await file.exists();
    debugPrint('[IOSWidget] File exists after write: $exists');

    await reloadAllWidgets();
    debugPrint('[IOSWidget] Widget reload triggered');
  }

  /// Format DateTime with explicit timezone offset for proper Swift parsing
  static String _formatDateTimeWithOffset(DateTime dt) {
    final local = dt.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${local.toIso8601String()}$sign$hours:$minutes';
  }

  static Map<String, dynamic> _lessonToJson(Lesson lesson) {
    final subject = lesson.subject;
    return {
      'uid': lesson.uid,
      'date': lesson.date,
      'start': _formatDateTimeWithOffset(lesson.start),
      'end': _formatDateTimeWithOffset(lesson.end),
      'name': lesson.name,
      'lessonNumber': lesson.lessonNumber,
      'teacher': lesson.teacher,
      'subject': subject != null ? {
        'uid': subject.uid,
        'name': subject.name,
        'category': subject.category != null ? {
          'uid': subject.category!.uid,
          'name': subject.category!.name,
          'description': subject.category!.description,
        } : null,
        'sortIndex': subject.sortIndex,
        'teacherName': subject.teacherName,
      } : {
        'uid': '',
        'name': lesson.name,
        'category': null,
        'sortIndex': 0,
        'teacherName': null,
      },
      'theme': lesson.theme,
      'roomName': lesson.roomName,
      'isCancelled': lesson.state.name?.toLowerCase().contains('elmarad') ?? false,
      'isSubstitution': lesson.substituteTeacher != null,
    };
  }

  static Map<String, dynamic> _gradeToJson(Grade grade) {
    return {
      'uid': grade.uid,
      'recordDate': _formatDateTimeWithOffset(grade.creationDate),
      'subject': {
        'uid': grade.subject.uid,
        'name': grade.subject.name,
        'category': grade.subject.category != null ? {
          'uid': grade.subject.category!.uid,
          'name': grade.subject.category!.name,
          'description': grade.subject.category!.description,
        } : null,
        'sortIndex': grade.subject.sortIndex,
        // Use the grade's teacher field, not subject.teacherName (which is usually null for grades)
        'teacherName': grade.teacher,
      },
      'topic': grade.topic,
      'type': {
        'uid': grade.type.uid,
        'name': grade.type.name,
        'description': grade.type.description,
      },
      'numericValue': grade.numericValue,
      'strValue': grade.strValue,
      'weightPercentage': grade.weightPercentage,
    };
  }

  static String _getSubjectNameFromGrades(String uid, List<Grade> grades) {
    try {
      final grade = grades.firstWhere((g) => g.subject.uid == uid);
      return grade.subject.name;
    } catch (e) {
      return uid;
    }
  }

  static int _getGradeCount(String uid, List<Grade> grades) {
    return grades.where((g) => g.subject.uid == uid).length;
  }

  static Future<void> reloadAllWidgets() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('reloadAllWidgets');
    } catch (e) {
      debugPrint('Error reloading widgets: $e');
    }
  }
}

class WidgetBreakInfo {
  final String name;
  final String nameKey;
  final DateTime endDate;

  WidgetBreakInfo({
    required this.name,
    required this.nameKey,
    required this.endDate,
  });
}
