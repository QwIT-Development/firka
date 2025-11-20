import 'dart:async';
import 'dart:io';
import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/api/client/live_activity_backend_client.dart';
import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/live_activity_manager.dart';
import 'package:firka/helpers/settings.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

/// Service that coordinates LiveActivity functionality
/// Handles timetable synchronization, device token management, and activity updates
class LiveActivityService {
  static final Logger _logger = Logger('LiveActivityService');
  static final LiveActivityBackendClient _backendClient = LiveActivityBackendClient();

  static const String _deviceTokenKey = 'live_activity_device_token';
  static const String _lastTimetableUpdateKey = 'live_activity_last_update';
  static const String _isRegisteredKey = 'live_activity_is_registered';

  static Timer? _updateTimer;
  static String? _cachedDeviceToken;
  static bool _isInitialized = false;

  /// Get current language code from settings
  static String? _getCurrentLanguageCode() {
    try {
      if (!initDone || initData.settings == null) {
        return 'hu';
      }

      final languageSetting = initData.settings.group("settings")
          .subGroup("application")["language"] as SettingsItemsRadio?;

      if (languageSetting == null) return 'hu';

      switch (languageSetting.activeIndex) {
        case 1: return 'hu';
        case 2: return 'en';
        case 3: return 'de';
        default: // auto
          final systemLang = Platform.localeName.split('_').first;
          if (['hu', 'en', 'de'].contains(systemLang)) {
            return systemLang;
          }
          return 'hu';
      }
    } catch (e) {
      _logger.warning('Error getting current language: $e');
      return 'hu';
    }
  }

  /// Update language preference on backend for Live Activity localization
  static Future<void> updateLanguagePreference(String languageCode) async {
    try {
      if (!Platform.isIOS) return;

      final prefs = await SharedPreferences.getInstance();
      final deviceToken = prefs.getString(_deviceTokenKey);

      if (deviceToken == null) {
        _logger.warning('Cannot update language: device token not found');
        return;
      }

      final success = await _backendClient.updateLanguage(
        deviceToken: deviceToken,
        language: languageCode,
      );

      if (success) {
        _logger.info('Language preference updated to $languageCode');
      } else {
        _logger.warning('Failed to update language preference');
      }
    } catch (e) {
      _logger.severe('Error updating language preference: $e');
    }
  }

  /// Initialize the LiveActivity service
  static Future<void> initialize() async {
    if (!Platform.isIOS) {
      return;
    }

    _isInitialized = false;
    _cachedDeviceToken = null;

    try {
      await LiveActivityManager.initialize();

      LiveActivityManager.setOnPushTokenReceived(_onPushTokenReceived);

      final deviceToken = await LiveActivityManager.registerForPushNotifications();

      if (deviceToken != null) {
        _cachedDeviceToken = deviceToken;
        await _saveDeviceToken(deviceToken);
      }

      _isInitialized = true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize LiveActivity: $e', e, stackTrace);
    }
  }

  /// Check if LiveActivity is enabled in settings
  static Future<bool> isEnabled([SettingsStore? settingsStore]) async {
    try {
      if (settingsStore == null) {
        return false;
      }

      final enabled = settingsStore
          .group("settings")
          .subGroup("application")["live_activity_enabled"] as SettingsBoolean;
      return enabled.value;
    } catch (e) {
      _logger.warning('Error reading LiveActivity setting: $e');
      return false;
    }
  }

  /// Handle LiveActivity enabled state change
  /// Called from settings toggle callback - does NOT save settings (already saved)
  static Future<void> handleEnabledChange(bool enabled) async {
    if (!Platform.isIOS) return;

    try {
      if (!enabled) {
        await LiveActivityManager.endAllActivities();
        _stopTimetableMonitoring();
        await _clearCache();
        _logger.info('LiveActivity disabled - all activities ended');
      } else {
        final studentResp = await initData.client.getStudent();
        final studentName = studentResp.response?.name ?? initData.tokens.first.studentId ?? "Student";

        await onUserLogin(
          client: initData.client,
          studentName: studentName,
          settingsStore: initData.settings,
        );
      }
    } catch (e) {
      _logger.warning('Error handling LiveActivity enabled change: $e');
    }
  }

  /// Handle token expiration - deactivate LiveActivity
  static Future<void> onTokenExpired() async {
    if (!Platform.isIOS) return;

    try {
      _logger.info('Token expired, deactivating LiveActivity');

      await LiveActivityManager.endAllActivities();

      _stopTimetableMonitoring();

    } catch (e) {
      _logger.severe('Error handling token expiration for LiveActivity: $e');
    }
  }

  /// Handle LiveActivity push token received from Swift side
  static Future<void> _onPushTokenReceived(String activityId, String pushToken) async {
    _logger.info('LiveActivity push token received, updating backend...');

    try {
      final deviceToken = _cachedDeviceToken ?? await LiveActivityManager.getDeviceToken();
      if (deviceToken == null) {
        _logger.warning('No device token available to update push token');
        return;
      }

      final success = await _backendClient.updatePushToken(
        deviceToken: deviceToken,
        pushToken: pushToken,
      );

      if (success) {
        _logger.info('LiveActivity push token updated successfully in backend');
      } else {
        _logger.warning('Failed to update LiveActivity push token in backend');
      }
    } catch (e) {
      _logger.severe('Error updating LiveActivity push token: $e');
    }
  }

  /// Called when user logs in successfully
  /// Registers the device and uploads the *full* timetable
  static Future<void> onUserLogin({
    required KretaClient client,
    required String studentName,
    SettingsStore? settingsStore,
  }) async {
    if (!Platform.isIOS || !_isInitialized) {
      return;
    }

    final enabled = await isEnabled(settingsStore);

    if (!enabled) {
      return;
    }

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final timetableResponse = await client.getTimeTable(startOfWeek, endOfWeek);

      final allLessons = timetableResponse.response ?? [];


      if (allLessons.isEmpty) {
        return;
      }

      final deviceToken = await _getOrWaitDeviceToken();

      if (deviceToken == null) {
        return;
      }

      /*final apnsTokenSuccess = await _backendClient.updateApnsToken(
        deviceToken: deviceToken,
        apnsPushToken: deviceToken,
      );*/

      String? currentLanguage = _getCurrentLanguageCode();

      final success = await _backendClient.registerDevice(
        deviceToken: deviceToken,
        timetable: allLessons,
        language: currentLanguage,
      );

      if (success) {
        await _markAsRegistered();
        await _saveLastUpdate();

        await _startPlaceholderActivity(allLessons, studentName);

        await _startTimetableMonitoring(
          client: client,
          studentName: studentName,
          settingsStore: settingsStore,
        );
        _logger.info('LiveActivity registration completed for $studentName');
      } else {
        _logger.warning('Failed to register device with backend');
      }
    } catch (e, st) {
      _logger.severe('Error during onUserLogin: $e', e, st);
    }
  }

  /// Called when app is opened - sends timetable to backend, backend handles updates
  static Future<void> onAppOpened({
    required KretaClient client,
    required String studentName,
    SettingsStore? settingsStore,
  }) async {
    if (!Platform.isIOS || !_isInitialized) return;

    try {
      final enabled = await isEnabled(settingsStore);
      if (!enabled) {
        _logger.info('LiveActivity is disabled, ending any running activities');
        await LiveActivityManager.endAllActivities();
        return;
      }

      final activeActivities = await LiveActivityManager.getActiveActivities();
      if (activeActivities.isNotEmpty) {
        _logger.info('Activity already running, sending timetable update to backend.');
        await checkAndUpdateTimetable(
            client: client,
            studentName: studentName,
            settingsStore: settingsStore
        );
        return;
      }

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final timetableResponse = await client.getTimeTable(startOfWeek, endOfWeek);
      final allLessons = timetableResponse.response ?? [];

      await _startPlaceholderActivity(allLessons, studentName);

      await checkAndUpdateTimetable(
          client: client,
          studentName: studentName,
          settingsStore: settingsStore
      );

    } catch (e) {
      _logger.severe('Error handling onAppOpened for LiveActivity: $e');
    }
  }

  /// Called when user logs out
  static Future<void> onUserLogout() async {
    if (!Platform.isIOS) return;

    try {
      await LiveActivityManager.endAllActivities();

      final deviceToken = _cachedDeviceToken ?? await LiveActivityManager.getDeviceToken();
      if (deviceToken != null) {
        await _backendClient.unregisterDevice(deviceToken: deviceToken);
      }

      await _clearCache();

      _stopTimetableMonitoring();

      _logger.info('User logout processed for LiveActivity');
    } catch (e) {
      _logger.severe('Error processing user logout for LiveActivity: $e');
    }
  }

  /// Check for timetable changes and update if necessary
  static Future<void> checkAndUpdateTimetable({
    required KretaClient client,
    required String studentName,
    SettingsStore? settingsStore,
  }) async {
    if (!Platform.isIOS || !_isInitialized) return;

    final enabled = await isEnabled(settingsStore);
    if (!enabled) {
      return;
    }

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final timetableResponse = await client.getTimeTable(startOfWeek, endOfWeek);
      final allLessons = timetableResponse.response ?? [];

      if (allLessons.isEmpty) {
        await LiveActivityManager.endAllActivities();
        return;
      }

      final deviceToken = await _getOrWaitDeviceToken();
      if (deviceToken == null) return;

      final lastUpdate = await _getLastUpdate();
      final hasChanges = await _backendClient.checkTimetableChanges(
        deviceToken: deviceToken,
        lastUpdated: lastUpdate,
      );

      if (hasChanges) {
        _logger.info('Timetable changes detected, sending to backend...');

        final success = await _backendClient.updateTimetable(
          deviceToken: deviceToken,
          timetable: allLessons,
        );

        if (success) {
          await _saveLastUpdate();
          _logger.info('Timetable sent to backend successfully. Backend will update LiveActivity.');
        }
      }
    } catch (e) {
      _logger.severe('Error checking and updating timetable: $e');
    }
  }

  /// Start monitoring timetable and updating LiveActivity
  static Future<void> _startTimetableMonitoring({
    required KretaClient client,
    required String studentName,
    SettingsStore? settingsStore,
  }) async {
    _stopTimetableMonitoring();

    await checkAndUpdateTimetable(
      client: client,
      studentName: studentName,
      settingsStore: settingsStore,
    );

    // Pediódikus frissítés (minden 30 percben)
    // Ez azért kell, hogy a KRETA változásokat észleljük,
    // és összevessük az adatbázisban tárolt adatokkal.
    _updateTimer = Timer.periodic(
      const Duration(minutes: 30),
          (timer) async {
        await checkAndUpdateTimetable(
          client: client,
          studentName: studentName,
          settingsStore: settingsStore,
        );
      },
    );

    _logger.info('Timetable monitoring started');
  }

  /// Stop monitoring timetable
  static void _stopTimetableMonitoring() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _logger.info('Timetable monitoring stopped');
  }

  /// Force update LiveActivity with latest data
  static Future<void> forceUpdate({
    required KretaClient client,
    required String studentName,
  }) async {
    await checkAndUpdateTimetable(
      client: client,
      studentName: studentName,
    );
  }

  /// Starts a minimal placeholder activity shell - backend will update with real data
  static Future<void> _startPlaceholderActivity(List<Lesson> allLessons, String studentName) async {
    final activeActivities = await LiveActivityManager.getActiveActivities();
    if (activeActivities.isNotEmpty) {
      _logger.info('_startPlaceholderActivity: Activity already running.');
      return;
    }

    _logger.info('_startPlaceholderActivity: Creating minimal loading shell, backend will update.');

    final now = DateTime.now();

    Lesson placeholderLesson;
    if (allLessons.isNotEmpty) {
      final template = allLessons.first;
      placeholderLesson = Lesson(
        uid: 'loading-placeholder',
        date: now.toIso8601String(),
        start: now,
        end: now.add(const Duration(minutes: 1)),
        name: 'Betöltés...',
        type: template.type,
        state: template.state,
        canStudentEditHomework: false,
        isHomeworkComplete: false,
        attachments: [],
        isDigitalLesson: false,
        digitalSupportDeviceTypeList: [],
        createdAt: now,
        lastModifiedAt: now,
      );
    } else {
      final emptyType = NameUidDesc(uid: 'placeholder', name: 'Placeholder', description: null);
      final emptyState = NameUidDesc(uid: 'active', name: 'Active', description: null);

      placeholderLesson = Lesson(
        uid: 'loading-placeholder',
        date: now.toIso8601String(),
        start: now,
        end: now.add(const Duration(minutes: 1)),
        name: 'Betöltés...',
        type: emptyType,
        state: emptyState,
        canStudentEditHomework: false,
        isHomeworkComplete: false,
        attachments: [],
        isDigitalLesson: false,
        digitalSupportDeviceTypeList: [],
        createdAt: now,
        lastModifiedAt: now,
      );
    }

    await LiveActivityManager.startActivity(
      studentName: studentName,
      schoolName: 'Iskola',
      currentLesson: placeholderLesson,
      isBreak: false,
      mode: 'loading',
    );

    _logger.info('_startPlaceholderActivity: Placeholder created, waiting for backend update.');
  }

  static Future<void> _saveDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceTokenKey, token);
  }

  static Future<String?> _getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceTokenKey);
  }

  static Future<void> _saveLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastTimetableUpdateKey,
      DateTime.now().toIso8601String(),
    );
  }

  static Future<DateTime> _getLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateStr = prefs.getString(_lastTimetableUpdateKey);
    if (lastUpdateStr != null) {
      return DateTime.parse(lastUpdateStr);
    }
    return DateTime.now().subtract(const Duration(days: 365));
  }

  static Future<void> _markAsRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRegisteredKey, true);
  }

  /*static Future<bool> _isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRegisteredKey) ?? false;
  }*/

  static Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceTokenKey);
    await prefs.remove(_lastTimetableUpdateKey);
    await prefs.remove(_isRegisteredKey);
    _cachedDeviceToken = null;
  }

  /// Try to get cached token or wait a short period until iOS provides it
  static Future<String?> _getOrWaitDeviceToken({Duration timeout = const Duration(seconds: 5)}) async {
    if (_cachedDeviceToken != null) {
      return _cachedDeviceToken;
    }

    final saved = await _getDeviceToken();
    if (saved != null) {
      _cachedDeviceToken = saved;
      return saved;
    }

    final start = DateTime.now();
    String? token = await LiveActivityManager.getDeviceToken();
    while (token == null && DateTime.now().difference(start) < timeout) {
      await Future.delayed(const Duration(milliseconds: 300));
      token = await LiveActivityManager.getDeviceToken();
    }
    if (token != null) {
      _cachedDeviceToken = token;
      await _saveDeviceToken(token);
    }
    return token;
  }

  /// Send a test notification (for debugging)
  static Future<bool> sendTestNotification() async {
    if (!Platform.isIOS || !_isInitialized) return false;

    try {
      final deviceToken = await _getOrWaitDeviceToken();
      if (deviceToken == null) {
        _logger.warning('No device token available for test notification');
        return false;
      }

      final success = await _backendClient.sendTestNotification(
        deviceToken: deviceToken,
      );

      if (success) {
        _logger.info('Test notification sent successfully');
      } else {
        _logger.warning('Failed to send test notification');
      }

      return success;
    } catch (e) {
      _logger.severe('Error sending test notification: $e');
      return false;
    }
  }
}