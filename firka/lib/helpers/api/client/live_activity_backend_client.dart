import 'package:dio/dio.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client for communicating with the LiveActivity backend service
/// This backend handles device tokens and timetable data for push notifications
class LiveActivityBackendClient {
  static final Logger _logger = Logger('LiveActivityBackendClient');

  final Dio _dio;

  LiveActivityBackendClient({Dio? dio}) : _dio = dio ?? Dio() {
    final baseUrl = dotenv.env['BACKEND_BASE_URL'];
    final apiKey = dotenv.env['BACKEND_API_KEY'] ?? '';

    _dio.options.baseUrl = baseUrl!;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-key': apiKey,
    };

    _logger.info('LiveActivity backend configured successfully!');
  }

  /// Register device token and upload timetable data
  Future<bool> registerDevice({
    required String deviceToken,
    required List<Lesson> timetable,
    String? language,
  }) async {
    try {
      final lessonsData = timetable.map((lesson) {
        DateTime validLastModified = lesson.lastModifiedAt;
        if (validLastModified.year < 1900) {
          validLastModified = lesson.start;
        }

        return {
          'uid': lesson.uid,
          'date': lesson.date,
          'startTime': lesson.start.toIso8601String(),
          'endTime': lesson.end.toIso8601String(),
          'name': lesson.name,
          'lessonNumber': lesson.lessonNumber,
          'teacher': lesson.teacher,
          'theme': lesson.theme,
          'roomName': lesson.roomName,
          'isSubstitution': lesson.substituteTeacher != null,
          'substituteTeacher': lesson.substituteTeacher,
          'isCancelled': lesson.state.name?.toLowerCase().contains('elmarad') ?? false,
          'lastModified': validLastModified.toIso8601String(),
        };
      }).toList();

      final requestData = {
        'deviceToken': deviceToken,
        'lessons': lessonsData,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      if (language != null) {
        requestData['language'] = language;
      }

      final response = await _dio.post(
        '/live-activity/register',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Device registered successfully with ${timetable.length} lessons');
        return true;
      }

      _logger.warning('Failed to register device: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error registering device: $e');
      return false;
    }
  }

  /// Update timetable data for existing device
  Future<bool> updateTimetable({
    required String deviceToken,
    required List<Lesson> timetable,
  }) async {
    try {
      final lessonsData = timetable.map((lesson) {
        DateTime validLastModified = lesson.lastModifiedAt;
        if (validLastModified.year < 1900) {
          validLastModified = lesson.start;
        }
        
        return {
          'uid': lesson.uid,
          'date': lesson.date,
          'startTime': lesson.start.toIso8601String(),
          'endTime': lesson.end.toIso8601String(),
          'name': lesson.name,
          'lessonNumber': lesson.lessonNumber,
          'teacher': lesson.teacher,
          'theme': lesson.theme,
          'roomName': lesson.roomName,
          'isSubstitution': lesson.substituteTeacher != null,
          'substituteTeacher': lesson.substituteTeacher,
          'isCancelled': lesson.state.name?.toLowerCase().contains('elmarad') ?? false,
          'lastModified': validLastModified.toIso8601String(),
        };
      }).toList();

      final response = await _dio.put(
        '/live-activity/timetable',
        data: {
          'deviceToken': deviceToken,
          'lessons': lessonsData,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.info('Timetable updated successfully');
        return true;
      }

      _logger.warning('Failed to update timetable: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error updating timetable: $e');
      return false;
    }
  }

  /// Unregister device (called when user logs out)
  Future<bool> unregisterDevice({
    required String deviceToken,
  }) async {
    try {
      final response = await _dio.delete(
        '/live-activity/unregister',
        data: {
          'deviceToken': deviceToken,
        },
      );

      if (response.statusCode == 200) {
        _logger.info('Device unregistered successfully');
        return true;
      }

      _logger.warning('Failed to unregister device: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error unregistering device: $e');
      return false;
    }
  }

  /// Check if timetable has changed on backend
  Future<bool> checkTimetableChanges({
    required String deviceToken,
    required DateTime lastUpdated,
  }) async {
    try {
      final response = await _dio.get(
        '/live-activity/check-changes',
        queryParameters: {
          'deviceToken': deviceToken,
          'lastUpdated': lastUpdated.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final hasChanges = response.data['hasChanges'] as bool? ?? false;
        return hasChanges;
      }

      return false;
    } catch (e) {
      _logger.severe('Error checking timetable changes: $e');
      return false;
    }
  }

  /// Get current timetable from backend
  Future<List<Lesson>?> getTimetable({
    required String deviceToken,
  }) async {
    try {
      final response = await _dio.get(
        '/live-activity/timetable',
        queryParameters: {
          'deviceToken': deviceToken,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final lessonsData = response.data['lessons'] as List<dynamic>?;
        if (lessonsData != null) {
          return null;
        }
      }

      return null;
    } catch (e) {
      _logger.severe('Error getting timetable: $e');
      return null;
    }
  }

  /// Update LiveActivity push token
  Future<bool> updatePushToken({
    required String deviceToken,
    required String pushToken,
  }) async {
    try {
      final response = await _dio.post(
        '/live-activity/push-token',
        data: {
          'deviceToken': deviceToken,
          'pushToken': pushToken,
        },
      );

      if (response.statusCode == 200) {
        _logger.info('LiveActivity push token updated successfully');
        return true;
      }

      _logger.warning('Failed to update push token: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error updating push token: $e');
      return false;
    }
  }

  /// Update normal APNs push token for regular notifications
  Future<bool> updateApnsToken({
    required String deviceToken,
    required String apnsPushToken,
  }) async {
    try {
      final response = await _dio.post(
        '/live-activity/apns-token',
        data: {
          'deviceToken': deviceToken,
          'apnsPushToken': apnsPushToken,
        },
      );

      if (response.statusCode == 200) {
        _logger.info('APNs push token updated successfully');
        return true;
      }

      _logger.warning('Failed to update APNs push token: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error updating APNs push token: $e');
      return false;
    }
  }

  /// Send a test notification (for debugging)
  Future<bool> sendTestNotification({
    required String deviceToken,
  }) async {
    try {
      final response = await _dio.post(
        '/live-activity/test-notification',
        data: {
          'deviceToken': deviceToken,
        },
      );

      if (response.statusCode == 200) {
        _logger.info('Test notification sent successfully');
        return true;
      }

      _logger.warning('Failed to send test notification: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error sending test notification: $e');
      return false;
    }
  }

  /// Update language preference for device
  Future<bool> updateLanguage({
    required String deviceToken,
    required String language,
  }) async {
    try {
      final response = await _dio.put(
        '/live-activity/language',
        data: {
          'deviceToken': deviceToken,
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        _logger.info('Language updated to $language successfully');
        return true;
      }

      _logger.warning('Failed to update language: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error updating language: $e');
      return false;
    }
  }
}

