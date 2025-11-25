import 'dart:async';
import 'dart:io';
import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/api/client/live_activity_backend_client.dart';
import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/live_activity_manager.dart';
import 'package:firka/helpers/settings.dart';
import 'package:firka/ui/phone/screens/live_activity/live_activity_consent_screen.dart';
import 'package:flutter/material.dart';
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

  /// Get current user's studentId for user-specific settings
  static String? _getCurrentStudentId() {
    try {
      if (!initDone || initData.client == null || initData.client.model == null) {
        return null;
      }
      return initData.client.model.studentId;
    } catch (e) {
      _logger.warning('Error getting current studentId: $e');
      return null;
    }
  }

  /// Get user-specific Live Activity enabled state from SharedPreferences
  static Future<bool> _getUserLiveActivityEnabled() async {
    final studentId = _getCurrentStudentId();
    if (studentId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_enabled_$studentId';
    return prefs.getBool(key) ?? false;
  }

  /// Set user-specific Live Activity enabled state to SharedPreferences
  static Future<void> _setUserLiveActivityEnabled(bool value) async {
    final studentId = _getCurrentStudentId();
    if (studentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_enabled_$studentId';
    await prefs.setBool(key, value);
    _logger.info('Saved LiveActivity enabled=$value for user $studentId');
  }

  /// Get user-specific privacy declined state from SharedPreferences
  static Future<bool> _getUserPrivacyEverDeclined() async {
    final studentId = _getCurrentStudentId();
    if (studentId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_privacy_ever_declined_$studentId';
    return prefs.getBool(key) ?? false;
  }

  /// Set user-specific privacy declined state to SharedPreferences
  static Future<void> _setUserPrivacyEverDeclined(bool value) async {
    final studentId = _getCurrentStudentId();
    if (studentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_privacy_ever_declined_$studentId';
    await prefs.setBool(key, value);
    _logger.info('Saved privacy ever declined=$value for user $studentId');
  }

  /// Sync global setting with current user's setting
  /// This ensures the Settings UI shows the correct state for the current user
  static Future<void> syncGlobalSettingWithCurrentUser() async {
    if (!Platform.isIOS) return;

    try {
      final studentId = _getCurrentStudentId();
      if (studentId == null) {
        _logger.warning('Cannot sync global setting: no current user');
        return;
      }

      final userEnabled = await _getUserLiveActivityEnabled();

      final globalSetting = initData.settings
          .group("settings")
          .subGroup("application")["live_activity_enabled"] as SettingsBoolean;

      if (globalSetting.value != userEnabled) {
        globalSetting.value = userEnabled;
        await initData.isar.writeTxn(() async {
          await globalSetting.save(initData.isar.appSettingsModels);
        });
        globalUpdate.update();
        _logger.info('Global LiveActivity setting synced with user setting: $userEnabled for user $studentId');
      }
    } catch (e) {
      _logger.warning('Error syncing global setting: $e');
    }
  }

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
      return await _getUserLiveActivityEnabled();
    } catch (e) {
      _logger.warning('Error reading LiveActivity setting: $e');
      return false;
    }
  }

  /// Handle LiveActivity enabled state change
  /// Called from settings toggle callback
  static Future<void> handleEnabledChange(bool enabled, {bool isManual = false}) async {
    if (!Platform.isIOS) return;

    try {
      final studentId = _getCurrentStudentId();
      if (studentId == null) {
        _logger.warning('Cannot change LiveActivity state: no current user');
        return;
      }

      if (!enabled) {
        await onUserLogout();

        await _setUserLiveActivityEnabled(false);

        await syncGlobalSettingWithCurrentUser();

        _logger.info('LiveActivity disabled and user data cleared.');
      } else {
        _logger.info('Showing privacy consent screen (manual: $isManual)');
        final bool? accepted = await _showPrivacyConsentScreen();

        if (accepted == true) {
          _logger.info('User accepted privacy policy');

          await _setUserLiveActivityEnabled(true);

          await syncGlobalSettingWithCurrentUser();

          final studentResp = await initData.client.getStudent();
          final studentName = studentResp.response?.name ?? initData.tokens.first.studentId ?? "Student";

          await onUserLogin(
            client: initData.client,
            studentName: studentName,
            settingsStore: initData.settings,
          );
        } else {
          _logger.info('User declined privacy policy or swiped back');

          await _setUserLiveActivityEnabled(false);
          await _setUserPrivacyEverDeclined(true);

          await syncGlobalSettingWithCurrentUser();
        }
      }
    } catch (e) {
      _logger.warning('Error handling LiveActivity enabled change: $e');
    }
  }

  /// Show privacy consent screen automatically on first use or user switch
  /// Only shows if user hasn't declined before
  static Future<void> showConsentScreenIfNeeded() async {
    if (!Platform.isIOS) return;

    try {
      final studentId = _getCurrentStudentId();
      if (studentId == null) {
        _logger.warning('Cannot check consent screen: no current user');
        return;
      }

      await syncGlobalSettingWithCurrentUser();

      final enabled = await _getUserLiveActivityEnabled();
      final everDeclined = await _getUserPrivacyEverDeclined();

      if (!enabled && !everDeclined) {
        _logger.info('First use or new user - showing privacy consent automatically');
        await handleEnabledChange(true, isManual: false);
      } else {
        _logger.info('User already has LiveActivity setting: enabled=$enabled, declined=$everDeclined');
      }
    } catch (e) {
      _logger.warning('Error checking if consent screen needed: $e');
    }
  }

  /// Show privacy consent screen
  static Future<bool?> _showPrivacyConsentScreen() async {
    final context = initData.navigatorKey.currentContext;
    if (context == null) {
      _logger.warning('No context available to show consent screen');
      return false;
    }

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveActivityConsentScreen(
          data: initData,
        ),
      ),
    );

    return result;
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

  /// Get next Monday's date (or this Monday if today is Monday and it's early morning)
  static DateTime _getNextMonday(DateTime now) {
    final int daysUntilMonday = ((DateTime.monday - now.weekday) % 7);
    final int daysToAdd = daysUntilMonday == 0 ? 7 : daysUntilMonday;

    final nextMonday = now.add(Duration(days: daysToAdd));

    return DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
  }

  /// Called when user logs in successfully
  /// Registers the device and uploads the *full* timetable
  static Future<void> onUserLogin({
    required KretaClient client,
    required String studentName,
    SettingsStore? settingsStore,
  }) async {
    _logger.info('onUserLogin: Function called for $studentName');

    if (!Platform.isIOS || !_isInitialized) {
      _logger.warning('onUserLogin: Returning early - Platform.isIOS=${Platform.isIOS}, _isInitialized=$_isInitialized');
      return;
    }

    final enabled = await isEnabled(settingsStore);
    _logger.info('onUserLogin: LiveActivity enabled=$enabled');

    if (!enabled) {
      _logger.warning('onUserLogin: LiveActivity not enabled, returning early');
      return;
    }

    try {
      _logger.info('onUserLogin: Starting timetable fetch');
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      _logger.info('onUserLogin: Fetching timetable from $startOfWeek to $endOfWeek');
      final timetableResponse = await client.getTimeTable(startOfWeek, endOfWeek);

      final allLessons = List<Lesson>.from(timetableResponse.response ?? []);
      _logger.info('onUserLogin: Fetched ${allLessons.length} lessons for current week');

      if (allLessons.isEmpty) {
        _logger.warning('onUserLogin: No lessons found, returning early');
        return;
      }

      final nextMonday = _getNextMonday(now);
      final nextMondayEndOfDay = nextMonday.add(const Duration(days: 1));

      _logger.info('Fetching next Monday timetable from $nextMonday to $nextMondayEndOfDay');

      try {
        final nextMondayTimetable = await client.getTimeTable(nextMonday, nextMondayEndOfDay);
        final nextMondayLessons = nextMondayTimetable.response ?? [];

        _logger.info('Fetched ${nextMondayLessons.length} lessons for next Monday');

        if (nextMondayLessons.isNotEmpty) {
          nextMondayLessons.sort((a, b) => a.start.compareTo(b.start));
          final firstLesson = nextMondayLessons.first;

          final notificationLesson = Lesson(
            uid: '${firstLesson.uid}__FOR_NOTIFICATION_ONLY',
            date: firstLesson.date,
            start: firstLesson.start,
            end: firstLesson.end,
            name: firstLesson.name,
            lessonNumber: firstLesson.lessonNumber,
            teacher: firstLesson.teacher,
            theme: firstLesson.theme,
            roomName: firstLesson.roomName,
            substituteTeacher: firstLesson.substituteTeacher,
            type: firstLesson.type,
            state: firstLesson.state,
            canStudentEditHomework: firstLesson.canStudentEditHomework,
            isHomeworkComplete: firstLesson.isHomeworkComplete,
            attachments: firstLesson.attachments,
            isDigitalLesson: firstLesson.isDigitalLesson,
            digitalSupportDeviceTypeList: firstLesson.digitalSupportDeviceTypeList,
            createdAt: firstLesson.createdAt ?? firstLesson.lastModifiedAt ?? DateTime.now(),
            lastModifiedAt: firstLesson.lastModifiedAt,
          );

          allLessons.add(notificationLesson);
          _logger.info('Added next Monday first lesson for notification: ${firstLesson.name} at ${firstLesson.start}');
        }
      } catch (e) {
        _logger.warning('Could not fetch next Monday timetable for notification: $e');
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
    _logger.info('onUserLogout: Function called');

    if (!Platform.isIOS) {
      _logger.warning('onUserLogout: Not iOS, returning early');
      return;
    }

    try {
      _logger.info('onUserLogout: Ending all activities');
      await LiveActivityManager.endAllActivities();

      final deviceToken = _cachedDeviceToken ?? await LiveActivityManager.getDeviceToken();
      _logger.info('onUserLogout: Device token = ${deviceToken?.substring(0, 10)}...');

      if (deviceToken != null) {
        _logger.info('onUserLogout: Unregistering device from backend');
        await _backendClient.unregisterDevice(deviceToken: deviceToken);
      }

      _logger.info('onUserLogout: Clearing cache');
      await _clearCache();

      _logger.info('onUserLogout: Stopping timetable monitoring');
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
      List<Lesson> allLessons = List<Lesson>.from(timetableResponse.response ?? []);

      final nextMonday = endOfWeek.add(const Duration(days: 1));
      final nextMondayEnd = nextMonday.add(const Duration(days: 1));

      try {
        final nextMondayResponse = await client.getTimeTable(nextMonday, nextMondayEnd);
        if (nextMondayResponse.response != null && nextMondayResponse.response!.isNotEmpty) {
          final mondayLessons = nextMondayResponse.response!;
          mondayLessons.sort((a, b) => a.start.compareTo(b.start));
          final firstLesson = mondayLessons.first;

          final markedLesson = Lesson(
            uid: '${firstLesson.uid}__FOR_NOTIFICATION_ONLY',
            date: firstLesson.date,
            start: firstLesson.start,
            end: firstLesson.end,
            name: firstLesson.name,
            lessonNumber: firstLesson.lessonNumber,
            teacher: firstLesson.teacher,
            theme: firstLesson.theme,
            roomName: firstLesson.roomName,
            substituteTeacher: firstLesson.substituteTeacher,
            type: firstLesson.type,
            state: firstLesson.state,
            canStudentEditHomework: firstLesson.canStudentEditHomework,
            isHomeworkComplete: firstLesson.isHomeworkComplete,
            attachments: firstLesson.attachments,
            isDigitalLesson: firstLesson.isDigitalLesson,
            digitalSupportDeviceTypeList: firstLesson.digitalSupportDeviceTypeList,
            createdAt: firstLesson.createdAt ?? firstLesson.lastModifiedAt ?? DateTime.now(),
            lastModifiedAt: firstLesson.lastModifiedAt,
          );

          allLessons.add(markedLesson);
          _logger.info('Added first lesson from next Monday (${firstLesson.name}) marked for notification scheduling only');
        }
      } catch (e) {
        _logger.warning('Could not fetch next Monday first lesson: $e');
      }

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