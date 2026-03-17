import 'package:dio/dio.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client for communicating with the refilc-live-server backend.
/// Handles device registration, schedule uploads, and unregistration
/// for Live Activity push notifications via APNs.
class LiveActivityBackendClient {
  static final Logger _logger = Logger('LiveActivityBackendClient');
  static const String _deviceIdKey = 'live_activity_server_device_id';

  final Dio _dio;

  LiveActivityBackendClient({Dio? dio}) : _dio = dio ?? Dio() {
    final baseUrl = dotenv.env['LIVE_ACTIVITY_SERVER_URL'] ?? 'https://firka-la.devbeni.lol';
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
    _logger.info('LiveActivity backend configured: $baseUrl');
  }

  /// Get or create a persistent device ID (UUID).
  /// This ID is used to identify the device on the server side.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      _logger.info('Created new device ID: ${deviceId.substring(0, 8)}...');
    }
    return deviceId;
  }

  /// Register device with APNs token and settings.
  /// Called when a Live Activity push token is received.
  Future<bool> registerDevice({
    required String apnsToken,
    required String bundleId,
    String liveActivityColor = '#3C6E47',
  }) async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post('/register', data: {
        'device_id': deviceId,
        'apns_token': apnsToken,
        'bundle_id': bundleId,
        'app_type': 'firka',
        'settings': {
          'live_activity_color': liveActivityColor,
        },
      });

      if (response.statusCode == 200) {
        _logger.info('Device registered successfully');
        return true;
      }
      _logger.warning('Failed to register device: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error registering device: $e');
      return false;
    }
  }

  /// Upload today's schedule (lessons + breaks).
  /// The server uses this data to send APNs push updates every minute.
  Future<bool> uploadSchedule({
    required String date,
    required List<Map<String, dynamic>> lessons,
  }) async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post('/schedule', data: {
        'device_id': deviceId,
        'date': date,
        'lessons': lessons,
      });

      if (response.statusCode == 200) {
        _logger.info('Schedule uploaded: ${lessons.length} items for $date');
        return true;
      }
      if (response.statusCode == 401) {
        _logger.warning('Device not registered, cannot upload schedule');
        return false;
      }
      _logger.warning('Failed to upload schedule: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error uploading schedule: $e');
      return false;
    }
  }

  /// Unregister device (deletes device + all schedules from server).
  Future<bool> unregisterDevice() async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post('/unregister', data: {
        'device_id': deviceId,
      });

      if (response.statusCode == 200) {
        _logger.info('Device unregistered successfully');
        return true;
      }
      _logger.warning('Failed to unregister: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.severe('Error unregistering device: $e');
      return false;
    }
  }

  /// Convert Firka Lesson list to the server's LessonItem format.
  /// Also generates break items between consecutive lessons.
  static List<Map<String, dynamic>> lessonsToServerFormat(
    List<Lesson> lessons, {
    double bellDelayMinutes = 0.0,
  }) {
    // Filter out cancelled and empty lessons, then sort
    final filtered = lessons.where((l) {
      final isCancelled =
          l.state.name?.toLowerCase().contains('elmarad') ?? false;
      return !isCancelled && l.name.isNotEmpty;
    }).toList();
    filtered.sort((a, b) => a.start.compareTo(b.start));

    if (filtered.isEmpty) return [];

    final bellDelayMs = (bellDelayMinutes * 60 * 1000).round();
    final result = <Map<String, dynamic>>[];

    for (var i = 0; i < filtered.length; i++) {
      final lesson = filtered[i];
      final nextLesson = i + 1 < filtered.length ? filtered[i + 1] : null;

      // Add lesson item
      result.add({
        'type': 'lesson',
        'index': '${lesson.lessonNumber ?? (i + 1)}',
        'subject': lesson.name,
        'icon': _subjectToIcon(lesson.name),
        'room': lesson.roomName ?? '',
        'description': lesson.theme ?? '',
        'start': lesson.start.millisecondsSinceEpoch + bellDelayMs,
        'end': lesson.end.millisecondsSinceEpoch + bellDelayMs,
        'nextSubject': nextLesson?.name ?? '',
        'nextRoom': nextLesson?.roomName ?? '',
        'nextIndex': nextLesson != null
            ? '${nextLesson.lessonNumber ?? (i + 2)}'
            : '',
        // Firka extra fields for server-side content state building
        'teacher': lesson.teacher ?? '',
        'theme': lesson.theme ?? '',
        'isSubstitution': lesson.substituteTeacher != null,
        'isCancelled': false,
        'substituteTeacher': lesson.substituteTeacher ?? '',
        'lessonNumber': lesson.lessonNumber,
      });

      // Add break between consecutive lessons
      if (nextLesson != null) {
        final breakStart = lesson.end.millisecondsSinceEpoch + bellDelayMs;
        final breakEnd =
            nextLesson.start.millisecondsSinceEpoch + bellDelayMs;
        if (breakEnd > breakStart) {
          result.add({
            'type': 'break',
            'index': '',
            'subject': 'Szünet',
            'icon': 'cup.and.saucer',
            'room': '',
            'description': '',
            'start': breakStart,
            'end': breakEnd,
            'nextSubject': nextLesson.name,
            'nextRoom': nextLesson.roomName ?? '',
            'nextIndex': '${nextLesson.lessonNumber ?? (i + 2)}',
            'teacher': '',
            'theme': '',
            'isSubstitution': false,
            'isCancelled': false,
            'substituteTeacher': '',
            'lessonNumber': null,
          });
        }
      }
    }

    return result;
  }

  /// Map Hungarian subject names to SF Symbol icon names.
  static String _subjectToIcon(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('matek') || lower.contains('matematika')) {
      return 'function';
    }
    if (lower.contains('fizika')) return 'atom';
    if (lower.contains('kémia')) return 'flask';
    if (lower.contains('biológia') || lower.contains('bio')) return 'leaf';
    if (lower.contains('magyar') || lower.contains('irodalom')) return 'book';
    if (lower.contains('történelem') || lower.contains('töri')) {
      return 'clock';
    }
    if (lower.contains('angol') ||
        lower.contains('német') ||
        lower.contains('nyelv')) {
      return 'globe';
    }
    if (lower.contains('informatika') || lower.contains('info')) {
      return 'desktopcomputer';
    }
    if (lower.contains('rajz') || lower.contains('művészet')) {
      return 'paintpalette';
    }
    if (lower.contains('testnevelés') || lower.contains('tesi')) {
      return 'sportscourt';
    }
    if (lower.contains('ének') || lower.contains('zene')) return 'music.note';
    if (lower.contains('földrajz') || lower.contains('föci')) {
      return 'globe.europe.africa';
    }
    return 'book.closed';
  }
}
