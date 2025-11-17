import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:logging/logging.dart';

class _ActivityState {
  final Lesson? currentLesson;
  final Lesson? nextLesson;
  final bool isBreak;
  final String? mode;

  _ActivityState({this.currentLesson, this.nextLesson, this.isBreak = false, this.mode});
}

class LiveActivityManager {
  static const MethodChannel _channel = MethodChannel('firka.app/live_activity');
  static final Logger _logger = Logger('LiveActivityManager');

  static String? _activityId;
  static bool _isActivityActive = false;
  static Function(String activityId, String pushToken)? _onPushTokenReceived;

  static Future<void> initialize() async {
    if (!Platform.isIOS) return;
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');
      await _syncActivityState();
      _logger.info('LiveActivity initialized');
    } catch (e) {
      _logger.warning('Failed to initialize LiveActivity: $e');
    }
  }

  static Future<void> _syncActivityState() async {
    if (!Platform.isIOS) return;
    try {
      final activeActivities = await getActiveActivities();
      if (activeActivities.isNotEmpty) {
        _activityId = activeActivities.first;
        _isActivityActive = true;
        _logger.info('Synced activity state: Found existing activity $_activityId');
      } else {
        _activityId = null;
        _isActivityActive = false;
        _logger.info('Synced activity state: No active activities found');
      }
    } catch (e) {
      _logger.warning('Failed to sync activity state: $e');
    }
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPushTokenReceived':
        final args = call.arguments as Map;
        final activityId = args['activityId'] as String;
        final pushToken = args['pushToken'] as String;
        _logger.info('Received LiveActivity push token: ${pushToken.substring(0, 10)}...');
        _onPushTokenReceived?.call(activityId, pushToken);
        break;
      default:
        _logger.warning('Unknown method call from Swift: ${call.method}');
    }
  }

  static void setOnPushTokenReceived(Function(String activityId, String pushToken) callback) {
    _onPushTokenReceived = callback;
  }

  static Future<String?> getDeviceToken() async {
    if (!Platform.isIOS) return null;
    try {
      return await _channel.invokeMethod('getDeviceToken');
    } catch (e) {
      _logger.warning('Failed to get device token: $e');
      return null;
    }
  }

  static Future<String?> registerForPushNotifications() async {
    if (!Platform.isIOS) return null;
    try {
      return await _channel.invokeMethod('registerForPushNotifications');
    } catch (e) {
      _logger.warning('Failed to register for push notifications: $e');
      return null;
    }
  }

  static Future<bool> startActivity({
    required String studentName,
    required String schoolName,
    required Lesson currentLesson,
    Lesson? nextLesson,
    bool isBreak = false,
    String? mode,
  }) async {
    if (!Platform.isIOS) return false;
    try {
      await _syncActivityState();
      if (_isActivityActive) {
        _logger.info('Activity already exists, updating instead.');
        return updateActivity(
          currentLesson: currentLesson,
          nextLesson: nextLesson,
          isBreak: isBreak,
          mode: mode,
        );
      }

      final contentState = _createContentState(
        currentLesson: currentLesson,
        nextLesson: nextLesson,
        isBreak: isBreak,
        mode: mode,
      );
      final attributes = {'studentName': studentName, 'schoolName': schoolName};

      final result = await _channel.invokeMethod('startActivity', {
        'attributes': jsonEncode(attributes),
        'contentState': jsonEncode(contentState),
      });

      if (result is String) {
        _activityId = result;
        _isActivityActive = true;
        _logger.info('LiveActivity started with ID: $_activityId');
        return true;
      }
      return false;
    } catch (e) {
      _logger.warning('Failed to start LiveActivity: $e');
      return false;
    }
  }

  static Future<bool> updateActivity({
    required Lesson currentLesson,
    Lesson? nextLesson,
    bool isBreak = false,
    String? mode,
  }) async {
    if (!Platform.isIOS) return false;
    await _syncActivityState();
    if (!_isActivityActive || _activityId == null) {
      _logger.warning('Cannot update: No active Live Activity found.');
      return false;
    }

    try {
      final contentState = _createContentState(
        currentLesson: currentLesson,
        nextLesson: nextLesson,
        isBreak: isBreak,
        mode: mode,
      );
      await _channel.invokeMethod('updateActivity', {
        'activityId': _activityId,
        'contentState': jsonEncode(contentState),
      });
      _logger.info('LiveActivity updated.');
      return true;
    } catch (e) {
      _logger.warning('Failed to update LiveActivity: $e');
      return false;
    }
  }

  static Future<void> endActivity() async {
    if (!Platform.isIOS) return;
    await _syncActivityState();
    if (!_isActivityActive || _activityId == null) return;

    try {
      await _channel.invokeMethod('endActivity', {'activityId': _activityId});
      _activityId = null;
      _isActivityActive = false;
      _logger.info('LiveActivity ended.');
    } catch (e) {
      _logger.warning('Failed to end LiveActivity: $e');
    }
  }

  static Future<List<String>> getActiveActivities() async {
    if (!Platform.isIOS) return [];
    try {
      final result = await _channel.invokeMethod('getActiveActivities');
      return (result as List?)?.cast<String>() ?? [];
    } catch (e) {
      _logger.warning('Failed to get active activities: $e');
      return [];
    }
  }

  static Future<void> endAllActivities() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('endAllActivities');
      _activityId = null;
      _isActivityActive = false;
      _logger.info('All LiveActivities ended.');
    } catch (e) {
      _logger.warning('Failed to end all activities: $e');
    }
  }

  static Map<String, dynamic> _createContentState({
    required Lesson currentLesson,
    Lesson? nextLesson,
    bool isBreak = false,
    String? mode,
  }) {
    final now = DateTime.now();
    final isBeforeSchool = mode == 'beforeSchool';

    DateTime startTimeForActivity;
    DateTime endTimeForActivity;

    if (isBeforeSchool) {
      startTimeForActivity = now;
      endTimeForActivity = currentLesson.start;
    } else {
      startTimeForActivity = currentLesson.start;
      endTimeForActivity = currentLesson.end;
    }

    final nextStartTimeForActivity = nextLesson?.start;

    final payload = {
      'isBreak': isBeforeSchool ? false : isBreak,
      'lessonName': isBeforeSchool ? currentLesson.name : (isBreak ? 'Szünet' : currentLesson.name),
      'lessonTheme': (isBeforeSchool || isBreak) ? null : currentLesson.theme,
      'roomName': (isBeforeSchool || isBreak) ? null : currentLesson.roomName,
      'teacherName': (isBeforeSchool || isBreak) ? null : currentLesson.teacher,
      'startTime': startTimeForActivity.toUtc().toIso8601String(),
      'endTime': endTimeForActivity.toUtc().toIso8601String(),
      'lessonNumber': (isBeforeSchool || isBreak) ? null : currentLesson.lessonNumber,
      'nextLessonName': isBeforeSchool ? null : nextLesson?.name,
      'nextRoomName': isBeforeSchool ? null : nextLesson?.roomName,
      'nextStartTime': nextStartTimeForActivity?.toUtc().toIso8601String(),
      'isSubstitution': currentLesson.substituteTeacher != null,
      'isCancelled': currentLesson.state.name?.toLowerCase().contains('elmarad') ?? false,
      'substituteTeacher': currentLesson.substituteTeacher,
      'currentTime': now.toUtc().toIso8601String(),
      'mode': mode,
    };
    return payload;
  }

  static _ActivityState _findCurrentActivityState(List<Lesson> lessons, DateTime now) {
    lessons.sort((a, b) => a.start.compareTo(b.start));

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final lessonStart = DateTime(now.year, now.month, now.day, lesson.start.hour, lesson.start.minute);
      final lessonEnd = DateTime(now.year, now.month, now.day, lesson.end.hour, lesson.end.minute);

      if (i == 0 && now.isBefore(lessonStart)) {
        if (lessonStart.difference(now).inHours < 2) {
          return _ActivityState(currentLesson: lesson, mode: 'beforeSchool');
        }
      }

      if (now.isAfter(lessonStart) && now.isBefore(lessonEnd)) {
        final correctedLesson = Lesson(
          uid: lesson.uid,
          date: lesson.date,
          start: lessonStart,
          end: lessonEnd,
          name: lesson.name,
          type: lesson.type,
          state: lesson.state,
          lessonNumber: lesson.lessonNumber,
          roomName: lesson.roomName,
          teacher: lesson.teacher,
          theme: lesson.theme,
          substituteTeacher: lesson.substituteTeacher,
          canStudentEditHomework: lesson.canStudentEditHomework,
          isHomeworkComplete: lesson.isHomeworkComplete,
          attachments: lesson.attachments,
          isDigitalLesson: lesson.isDigitalLesson,
          digitalSupportDeviceTypeList: lesson.digitalSupportDeviceTypeList,
          createdAt: lesson.createdAt,
          lastModifiedAt: lesson.lastModifiedAt
        );

        final nextLesson = i + 1 < lessons.length ? lessons[i + 1] : null;
        Lesson? correctedNextLesson;
        if (nextLesson != null) {
            correctedNextLesson = Lesson(
                uid: nextLesson.uid, date: nextLesson.date,
                start: DateTime(now.year, now.month, now.day, nextLesson.start.hour, nextLesson.start.minute),
                end: DateTime(now.year, now.month, now.day, nextLesson.end.hour, nextLesson.end.minute),
                name: nextLesson.name, type: nextLesson.type, state: nextLesson.state,
                lessonNumber: nextLesson.lessonNumber, roomName: nextLesson.roomName, teacher: nextLesson.teacher,
                theme: nextLesson.theme, substituteTeacher: nextLesson.substituteTeacher,
                canStudentEditHomework: nextLesson.canStudentEditHomework, isHomeworkComplete: nextLesson.isHomeworkComplete,
                attachments: nextLesson.attachments, isDigitalLesson: nextLesson.isDigitalLesson,
                digitalSupportDeviceTypeList: nextLesson.digitalSupportDeviceTypeList,
                createdAt: nextLesson.createdAt, lastModifiedAt: nextLesson.lastModifiedAt
            );
        }

        return _ActivityState(
          currentLesson: correctedLesson,
          nextLesson: correctedNextLesson,
        );
      }

      if (i + 1 < lessons.length) {
        final nextLesson = lessons[i + 1];
        final nextLessonStart = DateTime(now.year, now.month, now.day, nextLesson.start.hour, nextLesson.start.minute);
        if (now.isAfter(lessonEnd) && now.isBefore(nextLessonStart)) {
          final breakLesson = Lesson(
            uid: 'break-${lesson.uid}',
            date: lesson.date,
            start: lessonEnd,
            end: nextLessonStart,
            name: 'Szünet',
            type: lesson.type,
            state: lesson.state,
            canStudentEditHomework: false,
            isHomeworkComplete: false,
            attachments: [],
            isDigitalLesson: false,
            digitalSupportDeviceTypeList: [],
            createdAt: now,
            lastModifiedAt: now,
          );
          return _ActivityState(currentLesson: breakLesson, nextLesson: nextLesson, isBreak: true);
        }
      }
    }

    if (lessons.isNotEmpty) {
      final lastLesson = lessons.last;
      final lastLessonEnd = DateTime(now.year, now.month, now.day, lastLesson.end.hour, lastLesson.end.minute);
      final afterSchoolBreakEnd = lastLessonEnd.add(const Duration(minutes: 15));

      if (now.isAfter(lastLessonEnd) && now.isBefore(afterSchoolBreakEnd)) {
        final breakLesson = Lesson(
          uid: 'break-after-school',
          date: lastLesson.date,
          start: lastLessonEnd,
          end: afterSchoolBreakEnd,
          name: 'Szünet',
          type: lastLesson.type,
          state: lastLesson.state,
          canStudentEditHomework: false,
          isHomeworkComplete: false,
          attachments: [],
          isDigitalLesson: false,
          digitalSupportDeviceTypeList: [],
          createdAt: now,
          lastModifiedAt: now,
        );
        return _ActivityState(currentLesson: breakLesson, isBreak: true);
      }
    }
    
    return _ActivityState();
  }

  static Future<void> updateActivityFromTimetable(
    List<Lesson> todayLessons,
    String studentName,
    String schoolName,
  ) async {
    if (!Platform.isIOS) return;

    final now = DateTime.now();
    _logger.info("Checking for activity update at ${now.toIso8601String()}");

    final lessons = todayLessons.where((lesson) {
      final type = lesson.type.name?.toLowerCase() ?? '';
      return !(lesson.state.name?.toLowerCase().contains('törölt') ?? false) &&
             !type.contains('tanevrendje');
    }).toList();

    if (lessons.isEmpty) {
      _logger.info("No relevant lessons today. Ending activity if running.");
      await endAllActivities();
      return;
    }

    final state = _findCurrentActivityState(lessons, now);

    _logger.info("Current state: lesson=${state.currentLesson?.name}, break=${state.isBreak}, mode=${state.mode}");

    await _syncActivityState();

    if (state.currentLesson != null) {
      if (_isActivityActive) {
        _logger.info("Updating existing activity.");
        await updateActivity(
          currentLesson: state.currentLesson!,
          nextLesson: state.nextLesson,
          isBreak: state.isBreak,
          mode: state.mode,
        );
      } else {
        _logger.info("Starting new activity.");
        await startActivity(
          studentName: studentName,
          schoolName: schoolName,
          currentLesson: state.currentLesson!,
          nextLesson: state.nextLesson,
          isBreak: state.isBreak,
          mode: state.mode,
        );
      }
    } else {
      _logger.info("No current lesson or break. Ending activity if running.");
      await endAllActivities();
    }
  }
}
