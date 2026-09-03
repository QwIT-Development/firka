import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client for registering FCM push tokens with firka's backend, mirroring
/// LiveActivityBackendClient's conventions (same backend, same auth scheme).
/// Requires the backend to expose the `/notifications/*` routes below.
class NotificationBackendClient {
  static final Logger _logger = Logger('NotificationBackendClient');

  final Dio _dio;

  NotificationBackendClient({Dio? dio}) : _dio = dio ?? Dio() {
    if (!dotenv.isInitialized) {
      throw StateError(
        'NotificationBackendClient created before dotenv finished loading',
      );
    }

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

    _logger.info('Notification backend configured successfully!');
  }

  /// Register (or refresh) an FCM token for a student, with the current
  /// notification category preferences.
  Future<bool> registerToken({
    required String fcmToken,
    required String studentId,
    required bool notifyAll,
    required bool notifyGrades,
    required bool notifyHomeworkTests,
    required bool notifyAbsences,
    required bool notifyLessons,
    required bool notifyMessages,
    String? language,
  }) async {
    try {
      final response = await _dio.post(
        '/notifications/fcm-token',
        data: {
          'fcmToken': fcmToken,
          'studentId': studentId,
          'notifyAll': notifyAll,
          'notifyGrades': notifyGrades,
          'notifyHomeworkTests': notifyHomeworkTests,
          'notifyAbsences': notifyAbsences,
          'notifyLessons': notifyLessons,
          'notifyMessages': notifyMessages,
          'language': ?language,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('FCM token registered successfully');
        return true;
      }

      _logger.warning('Failed to register FCM token: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error registering FCM token: $e');
      return false;
    }
  }

  /// Update notification category preferences for an already-registered token.
  Future<bool> updatePreferences({
    required String fcmToken,
    required bool notifyAll,
    required bool notifyGrades,
    required bool notifyHomeworkTests,
    required bool notifyAbsences,
    required bool notifyLessons,
    required bool notifyMessages,
  }) async {
    try {
      final response = await _dio.put(
        '/notifications/preferences',
        data: {
          'fcmToken': fcmToken,
          'notifyAll': notifyAll,
          'notifyGrades': notifyGrades,
          'notifyHomeworkTests': notifyHomeworkTests,
          'notifyAbsences': notifyAbsences,
          'notifyLessons': notifyLessons,
          'notifyMessages': notifyMessages,
        },
      );

      if (response.statusCode == 200) {
        _logger.info('Notification preferences updated successfully');
        return true;
      }

      _logger.warning(
        'Failed to update notification preferences: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      _logger.severe('Error updating notification preferences: $e');
      return false;
    }
  }

  /// Unregister an FCM token (called on logout or when push is disabled).
  Future<bool> unregisterToken({required String fcmToken}) async {
    try {
      final response = await _dio.delete(
        '/notifications/fcm-token',
        data: {'fcmToken': fcmToken},
      );

      if (response.statusCode == 200) {
        _logger.info('FCM token unregistered successfully');
        return true;
      }

      _logger.warning(
        'Failed to unregister FCM token: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      _logger.severe('Error unregistering FCM token: $e');
      return false;
    }
  }
}
