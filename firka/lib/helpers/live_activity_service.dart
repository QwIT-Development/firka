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
import 'package:flutter/services.dart';
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

  static Timer? _bellDelayDebounceTimer;
  static double? _pendingBellDelay;
  static double? _lastSentBellDelay;
  static const Duration _bellDelayDebounceInterval = Duration(seconds: 5);

  /// Get current user's studentId for user-specific settings
  /// If client is provided, use it directly instead of initData.client
  static String? _getCurrentStudentId({KretaClient? client}) {
    try {
      if (client != null && client.model != null) {
        return client.model.studentId;
      }
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
  static Future<bool> _getUserLiveActivityEnabled({KretaClient? client}) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_enabled_$studentId';
    return prefs.getBool(key) ?? false;
  }

  /// Set user-specific Live Activity enabled state to SharedPreferences
  static Future<void> _setUserLiveActivityEnabled(bool value, {KretaClient? client}) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_enabled_$studentId';
    await prefs.setBool(key, value);
    _logger.info('Saved LiveActivity enabled=$value for user $studentId');
  }

  /// Get user-specific privacy declined state from SharedPreferences
  static Future<bool> _getUserPrivacyEverDeclined({KretaClient? client}) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_privacy_ever_declined_$studentId';
    return prefs.getBool(key) ?? false;
  }

  /// Set user-specific privacy declined state to SharedPreferences
  static Future<void> _setUserPrivacyEverDeclined(bool value, {KretaClient? client}) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_privacy_ever_declined_$studentId';
    await prefs.setBool(key, value);
    _logger.info('Saved privacy ever declined=$value for user $studentId');
  }

  /// Sync global setting with current user's setting
  /// This ensures the Settings UI shows the correct state for the current user
  static Future<void> syncGlobalSettingWithCurrentUser({KretaClient? client}) async {
    if (!Platform.isIOS) return;

    try {
      final studentId = _getCurrentStudentId(client: client);
      if (studentId == null) {
        _logger.warning('Cannot sync global setting: no current user');
        return;
      }

      final userEnabled = await _getUserLiveActivityEnabled(client: client);

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

      _setupBackgroundFetchChannel();

      _isInitialized = true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize LiveActivity: $e', e, stackTrace);
    }
  }

  /// Setup method channel for background fetch
  static void _setupBackgroundFetchChannel() {
    const platform = MethodChannel('firka.app/background_fetch');
    platform.setMethodCallHandler((call) async {
      if (call.method == 'performBackgroundFetch') {
        _logger.info('Background fetch triggered by iOS');
        final success = await _performBackgroundFetch();
        return success;
      }
      return false;
    });
  }

  /// Schedule background fetch on iOS
  static Future<void> scheduleBackgroundFetch() async {
    if (!Platform.isIOS) return;

    try {
      const platform = MethodChannel('firka.app/background_fetch');
      await platform.invokeMethod('scheduleBackgroundFetch');
      _logger.info('Background fetch scheduled');
    } catch (e) {
      _logger.warning('Failed to schedule background fetch: $e');
    }
  }

  /// Cancel background fetch on iOS
  static Future<void> cancelBackgroundFetch() async {
    if (!Platform.isIOS) return;

    try {
      const platform = MethodChannel('firka.app/background_fetch');
      await platform.invokeMethod('cancelBackgroundFetch');
      _logger.info('Background fetch cancelled');
    } catch (e) {
      _logger.warning('Failed to cancel background fetch: $e');
    }
  }

  /// Check if there are any remaining lessons today
  static bool _hasRemainingLessonsToday(List<Lesson> lessons) {
    final now = DateTime.now();
    final todayLessons = lessons.where((lesson) {
      final uid = lesson.uid?.toLowerCase() ?? '';
      return lesson.date == now.toIso8601String().split('T').first &&
             lesson.end.isAfter(now) &&
             (uid.contains('orarendiora') ||
              uid.contains('tanitasiora') ||
              uid.contains('uresora'));
    }).toList();

    return todayLessons.isNotEmpty;
  }

  /// Perform background fetch - fetch fresh timetable from KRÉTA API and send to backend
  /// This is called by iOS BGTaskScheduler when the app is in background
  static Future<bool> _performBackgroundFetch() async {
    if (!Platform.isIOS || !_isInitialized || !initDone) {
      _logger.warning('Background fetch skipped: not initialized or initDone=false');
      return false;
    }

    try {
      final client = initData.client;
      if (client == null || client.model == null) {
        _logger.warning('Background fetch skipped: no client available');
        return false;
      }

      final enabled = await isEnabled(initData.settings, client);
      if (!enabled) {
        _logger.info('Background fetch skipped: LiveActivity disabled');
        return false;
      }

      _logger.info('Background fetch: fetching fresh timetable from KRÉTA API');

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      List<Lesson> allLessons = [];

      try {
        _logger.info('Background fetch: attempting to fetch fresh data from KRÉTA API');
        final timetableResponse = await client.getTimeTable(startOfWeek, endOfWeek, forceCache: false);

        if (timetableResponse.response != null) {
          allLessons = List<Lesson>.from(timetableResponse.response!);
          _logger.info('Background fetch: successfully fetched ${allLessons.length} lessons from KRÉTA API');
        } else {
          throw Exception('KRÉTA API returned null response');
        }
      } catch (e) {
        _logger.warning('Background fetch: KRÉTA API failed ($e), falling back to cache');
        try {
          final cachedResponse = await client.getTimeTable(startOfWeek, endOfWeek, forceCache: true);
          if (cachedResponse.response != null) {
            allLessons = List<Lesson>.from(cachedResponse.response!);
            _logger.info('Background fetch: successfully loaded ${allLessons.length} lessons from cache');
          } else {
            _logger.severe('Background fetch: both API and cache failed');
            return false;
          }
        } catch (cacheError) {
          _logger.severe('Background fetch: cache fallback also failed: $cacheError');
          return false;
        }
      }

      final nextMonday = endOfWeek.add(const Duration(days: 1));
      final nextMondayEnd = nextMonday.add(const Duration(days: 1));

      try {
        final nextMondayResponse = await client.getTimeTable(nextMonday, nextMondayEnd, forceCache: false);
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
          _logger.info('Background fetch: added next Monday first lesson for notification');
        }
      } catch (e) {
        _logger.warning('Background fetch: could not fetch next Monday lesson: $e');
      }

      if (allLessons.isEmpty) {
        _logger.info('Background fetch: no lessons to send');
        return true;
      }

      final deviceToken = await _getOrWaitDeviceToken();
      if (deviceToken == null) {
        _logger.warning('Background fetch: no device token available');
        return false;
      }

      _logger.info('Background fetch: sending ${allLessons.length} lessons to backend');
      final success = await _backendClient.updateTimetable(
        deviceToken: deviceToken,
        timetable: allLessons,
      );

      if (success) {
        await _saveLastUpdate();
        _logger.info('Background fetch: successfully sent timetable to backend');

        if (!_hasRemainingLessonsToday(allLessons)) {
          _logger.info('Background fetch: no remaining lessons today, cancelling future background fetches until app reopens');
          await cancelBackgroundFetch();
        } else {
          _logger.info('Background fetch: remaining lessons today, will continue background fetches');
        }

        return true;
      } else {
        _logger.warning('Background fetch: failed to send timetable to backend');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.severe('Background fetch: unexpected error: $e', e, stackTrace);
      return false;
    }
  }

  /// Check if LiveActivity is enabled in settings
  static Future<bool> isEnabled([SettingsStore? settingsStore, KretaClient? client]) async {
    try {
      return await _getUserLiveActivityEnabled(client: client);
    } catch (e) {
      _logger.warning('Error reading LiveActivity setting: $e');
      return false;
    }
  }

  /// Handle LiveActivity enabled state change
  /// Called from settings toggle callback
  static Future<void> handleEnabledChange(bool enabled, {bool isManual = false, KretaClient? client}) async {
    if (!Platform.isIOS) return;

    try {
      final effectiveClient = client ?? initData.client;
      final studentId = _getCurrentStudentId(client: effectiveClient);
      if (studentId == null) {
        _logger.warning('Cannot change LiveActivity state: no current user');
        return;
      }

      if (!enabled) {
        await onUserLogout();

        await _setUserLiveActivityEnabled(false, client: effectiveClient);

        await syncGlobalSettingWithCurrentUser(client: effectiveClient);

        _logger.info('LiveActivity disabled and user data cleared.');
      } else {
        _logger.info('Showing privacy consent screen (manual: $isManual)');
        final bool? accepted = await _showPrivacyConsentScreen();

        if (accepted == true) {
          _logger.info('User accepted privacy policy');

          await _setUserLiveActivityEnabled(true, client: effectiveClient);

          await syncGlobalSettingWithCurrentUser(client: effectiveClient);

          final studentResp = await effectiveClient.getStudent();
          final studentName = studentResp.response?.name ?? initData.tokens.first.studentId ?? "Student";

          await onUserLogin(
            client: effectiveClient,
            studentName: studentName,
            settingsStore: initData.settings,
          );
        } else {
          _logger.info('User declined privacy policy or swiped back');

          await _setUserLiveActivityEnabled(false, client: effectiveClient);
          await _setUserPrivacyEverDeclined(true, client: effectiveClient);

          await syncGlobalSettingWithCurrentUser(client: effectiveClient);
        }
      }
    } catch (e) {
      _logger.warning('Error handling LiveActivity enabled change: $e');
    }
  }

  /// Show privacy consent screen automatically on first use or user switch
  /// Only shows if user hasn't declined before
  static Future<void> showConsentScreenIfNeeded({KretaClient? client}) async {
    if (!Platform.isIOS) return;

    try {
      final effectiveClient = client ?? initData.client;
      final studentId = _getCurrentStudentId(client: effectiveClient);
      if (studentId == null) {
        _logger.warning('Cannot check consent screen: no current user');
        return;
      }

      await syncGlobalSettingWithCurrentUser(client: effectiveClient);

      final enabled = await _getUserLiveActivityEnabled(client: effectiveClient);
      final everDeclined = await _getUserPrivacyEverDeclined(client: effectiveClient);

      if (!enabled && !everDeclined) {
        _logger.info('First use or new user - showing privacy consent automatically');
        await handleEnabledChange(true, isManual: false, client: effectiveClient);
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

    final enabled = await isEnabled(settingsStore, client);
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

        await scheduleBackgroundFetch();

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
      final enabled = await isEnabled(settingsStore, client);
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

      await scheduleBackgroundFetch();

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

    final enabled = await isEnabled(settingsStore, client);
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

  /// Handle bellDelay change with debounce
  /// Waits 5 seconds after the last change before sending update to backend
  /// If value changes during the wait, reschedules the update with the new value
  static void onBellDelayChanged(double newValue) {
    if (!Platform.isIOS || !_isInitialized) return;

    _logger.info('BellDelay changed to $newValue minutes, scheduling debounced update');

    _bellDelayDebounceTimer?.cancel();

    _pendingBellDelay = newValue;

    _bellDelayDebounceTimer = Timer(_bellDelayDebounceInterval, () async {
      await _sendBellDelayUpdate();
    });
  }

  /// Internal function to send bellDelay update to backend
  static Future<void> _sendBellDelayUpdate() async {
    if (_pendingBellDelay == null) return;

    final bellDelayToSend = _pendingBellDelay!;

    if (_lastSentBellDelay == bellDelayToSend) {
      _logger.info('BellDelay $bellDelayToSend already sent to backend, skipping');
      _pendingBellDelay = null;
      return;
    }

    try {
      final deviceToken = await _getOrWaitDeviceToken();
      if (deviceToken == null) {
        _logger.warning('No device token available to update bellDelay');
        return;
      }

      _logger.info('Sending bellDelay update to backend: $bellDelayToSend minutes');

      final success = await _backendClient.updateBellDelay(
        deviceToken: deviceToken,
        bellDelay: bellDelayToSend,
      );

      if (success) {
        _lastSentBellDelay = bellDelayToSend;
        _logger.info('BellDelay updated successfully in backend');

        if (_pendingBellDelay != bellDelayToSend) {
          _logger.info('BellDelay changed to $_pendingBellDelay during update, scheduling another update');
          _bellDelayDebounceTimer?.cancel();
          _bellDelayDebounceTimer = Timer(_bellDelayDebounceInterval, () async {
            await _sendBellDelayUpdate();
          });
        } else {
          _pendingBellDelay = null;
        }
      } else {
        _logger.warning('Failed to update bellDelay in backend');
      }
    } catch (e) {
      _logger.severe('Error updating bellDelay: $e');
    }
  }
}