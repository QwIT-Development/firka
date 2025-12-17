import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:logging/logging.dart';

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
        _logger.info('Activity already exists, ending it to create new one with fresh token');
        await endAllActivities();
        await Future.delayed(const Duration(milliseconds: 500));
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
}
