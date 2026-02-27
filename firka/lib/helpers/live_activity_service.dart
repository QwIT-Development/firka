import 'dart:async';
import 'dart:io';
import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/api/client/live_activity_backend_client.dart';
import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/db/widget.dart';
import 'package:firka/helpers/live_activity_manager.dart';
import 'package:firka/helpers/active_account_helper.dart';
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
  static final LiveActivityBackendClient _backendClient =
      LiveActivityBackendClient();

  static const String _deviceTokenKey = 'live_activity_device_token';
  static const String _lastTimetableUpdateKey = 'live_activity_last_update';
  static const String _isRegisteredKey = 'live_activity_is_registered';

  static Timer? _updateTimer;
  static String? _cachedDeviceToken;
  static bool _isInitialized = false;

  static Timer? _bellDelayDebounceTimer;
  static double? _pendingBellDelay;
  static double? _lastSentBellDelay;
  static const Duration _bellDelayDebounceInterval = Duration(seconds: 3);

  static Timer? _morningNotificationDebounceTimer;
  static double? _pendingMorningNotificationTime;
  static bool? _pendingMorningNotificationEnabled;
  static double? _lastSentMorningNotificationTime;
  static bool? _lastSentMorningNotificationEnabled;
  static const Duration _morningNotificationDebounceInterval = Duration(
    seconds: 3,
  );

  static bool _tokenExpired = false;

  /// Check if token has expired (for UI notification)
  static bool get isTokenExpired => _tokenExpired;

  /// Clear token expiration flag (call after successful login)
  static void clearTokenExpiration() {
    _tokenExpired = false;
    _logger.info('Token expiration flag cleared');
  }

  /// Get current user's studentId for user-specific settings
  /// If client is provided, use it directly instead of initData.client
  static String? _getCurrentStudentId({KretaClient? client}) {
    try {
      if (client != null) {
        return client.model.studentId;
      }
      if (!initDone) {
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
  static Future<void> _setUserLiveActivityEnabled(
    bool value, {
    KretaClient? client,
  }) async {
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
  static Future<void> _setUserPrivacyEverDeclined(
    bool value, {
    KretaClient? client,
  }) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'live_activity_privacy_ever_declined_$studentId';
    await prefs.setBool(key, value);
    _logger.info('Saved privacy ever declined=$value for user $studentId');
  }

  /// Get user-specific morning notification enabled state from SharedPreferences
  static Future<bool> _getUserMorningNotificationEnabled({
    KretaClient? client,
  }) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return true;

    final prefs = await SharedPreferences.getInstance();
    final key = 'morning_notification_enabled_$studentId';
    return prefs.getBool(key) ?? true;
  }

  /// Set user-specific morning notification enabled state to SharedPreferences
  static Future<void> _setUserMorningNotificationEnabled(
    bool value, {
    KretaClient? client,
  }) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'morning_notification_enabled_$studentId';
    await prefs.setBool(key, value);
    _logger.info(
      'Saved morning notification enabled=$value for user $studentId',
    );
  }

  /// Get user-specific morning notification time from SharedPreferences
  static Future<int> _getUserMorningNotificationTime({
    KretaClient? client,
  }) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return 120;

    final prefs = await SharedPreferences.getInstance();
    final key = 'morning_notification_time_$studentId';
    return prefs.getInt(key) ?? 120;
  }

  /// Set user-specific morning notification time to SharedPreferences
  static Future<void> _setUserMorningNotificationTime(
    int value, {
    KretaClient? client,
  }) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'morning_notification_time_$studentId';
    await prefs.setInt(key, value);
    _logger.info('Saved morning notification time=$value for user $studentId');
  }

  /// Get user-specific bell delay from SharedPreferences
  static Future<double> _getUserBellDelay({KretaClient? client}) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return 0.0;

    final prefs = await SharedPreferences.getInstance();
    final key = 'bell_delay_$studentId';
    return prefs.getDouble(key) ?? 0.0;
  }

  /// Set user-specific bell delay to SharedPreferences
  static Future<void> _setUserBellDelay(
    double value, {
    KretaClient? client,
  }) async {
    final studentId = _getCurrentStudentId(client: client);
    if (studentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'bell_delay_$studentId';
    await prefs.setDouble(key, value);
    _logger.info('Saved bell delay=$value for user $studentId');
  }

  /// Sync global settings with current user's settings
  /// This ensures the Settings UI shows the correct state for the current user
  static Future<void> syncGlobalSettingWithCurrentUser({
    KretaClient? client,
  }) async {
    if (!Platform.isIOS) return;

    try {
      final studentId = _getCurrentStudentId(client: client);
      if (studentId == null) {
        _logger.warning('Cannot sync global setting: no current user');
        return;
      }

      final userLiveActivityEnabled = await _getUserLiveActivityEnabled(
        client: client,
      );
      final globalLiveActivitySetting =
          initData.settings
                  .group("settings")
                  .subGroup("notifications")["live_activity_enabled"]
              as SettingsBoolean;

      if (globalLiveActivitySetting.value != userLiveActivityEnabled) {
        globalLiveActivitySetting.value = userLiveActivityEnabled;
        await initData.isar.writeTxn(() async {
          await globalLiveActivitySetting.save(initData.isar.appSettingsModels);
        });
        _logger.info(
          'Global LiveActivity setting synced: $userLiveActivityEnabled for user $studentId',
        );
      }

      final userMorningEnabled = await _getUserMorningNotificationEnabled(
        client: client,
      );
      final globalMorningEnabledSetting =
          initData.settings
                  .group("settings")
                  .subGroup("notifications")["morning_notification_enabled"]
              as SettingsBoolean;

      if (globalMorningEnabledSetting.value != userMorningEnabled) {
        globalMorningEnabledSetting.value = userMorningEnabled;
        await initData.isar.writeTxn(() async {
          await globalMorningEnabledSetting.save(
            initData.isar.appSettingsModels,
          );
        });
        _logger.info(
          'Global morning notification enabled synced: $userMorningEnabled for user $studentId',
        );
      }

      final userMorningTime = await _getUserMorningNotificationTime(
        client: client,
      );
      final globalMorningTimeSetting =
          initData.settings
                  .group("settings")
                  .subGroup("notifications")["morning_notification_time"]
              as SettingsDouble;

      if (globalMorningTimeSetting.value.toInt() != userMorningTime) {
        globalMorningTimeSetting.value = userMorningTime.toDouble();
        await initData.isar.writeTxn(() async {
          await globalMorningTimeSetting.save(initData.isar.appSettingsModels);
        });
        _logger.info(
          'Global morning notification time synced: $userMorningTime for user $studentId',
        );
      }

      final userBellDelay = await _getUserBellDelay(client: client);
      final globalBellDelaySetting =
          initData.settings
                  .group("settings")
                  .subGroup("application")["bell_delay"]
              as SettingsDouble;

      if (globalBellDelaySetting.value != userBellDelay) {
        globalBellDelaySetting.value = userBellDelay;
        await initData.isar.writeTxn(() async {
          await globalBellDelaySetting.save(initData.isar.appSettingsModels);
        });
        _logger.info(
          'Global bell delay synced: $userBellDelay for user $studentId',
        );
      }

      globalUpdate.update();
    } catch (e) {
      _logger.warning('Error syncing global settings: $e');
    }
  }

  /// Get current language code from settings
  static String? _getCurrentLanguageCode() {
    try {
      if (!initDone) {
        return 'hu';
      }

      final languageSetting =
          initData.settings
                  .group("settings")
                  .subGroup("application")["language"]
              as SettingsItemsRadio?;

      if (languageSetting == null) return 'hu';

      switch (languageSetting.activeIndex) {
        case 1:
          return 'hu';
        case 2:
          return 'en';
        case 3:
          return 'de';
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

      final isEnabled = await _getUserLiveActivityEnabled();
      if (!isEnabled) {
        _logger.fine('Skipping language update: Live Activity is disabled');
        return;
      }

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

      final deviceToken =
          await LiveActivityManager.registerForPushNotifications();

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

  /// Perform background fetch - fetch fresh timetable from KRÉTA API and send to backend
  /// This is called by iOS BGTaskScheduler when the app is in background
  static Future<bool> _performBackgroundFetch() async {
    if (!Platform.isIOS || !_isInitialized || !initDone) {
      _logger.warning(
        'Background fetch skipped: not initialized or initDone=false',
      );
      return false;
    }

    try {
      final client = initData.client;

      final enabled = await isEnabled(initData.settings, client);
      if (!enabled) {
        _logger.info('Background fetch skipped: LiveActivity disabled');
        return false;
      }

      _logger.info('Background fetch: fetching fresh timetable from KRÉTA API');

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      List<Lesson> allLessons = [];

      try {
        _logger.info(
          'Background fetch: attempting to fetch fresh data from KRÉTA API',
        );
        final timetableResponse = await client.getTimeTable(
          startOfWeek,
          endOfWeek,
          forceCache: false,
        );

        if (timetableResponse.response != null) {
          allLessons = List<Lesson>.from(timetableResponse.response!);
          _logger.info(
            'Background fetch: successfully fetched ${allLessons.length} lessons from KRÉTA API',
          );
        } else {
          throw Exception('KRÉTA API returned null response');
        }
      } catch (e) {
        _logger.warning(
          'Background fetch: KRÉTA API failed ($e), falling back to cache',
        );
        try {
          final cachedResponse = await client.getTimeTable(
            startOfWeek,
            endOfWeek,
            forceCache: true,
          );
          if (cachedResponse.response != null) {
            allLessons = List<Lesson>.from(cachedResponse.response!);
            _logger.info(
              'Background fetch: successfully loaded ${allLessons.length} lessons from cache',
            );
          } else {
            _logger.severe('Background fetch: both API and cache failed');
            return false;
          }
        } catch (cacheError) {
          _logger.severe(
            'Background fetch: cache fallback also failed: $cacheError',
          );
          return false;
        }
      }

      try {
        _logger.info('Background fetch: refreshing iOS widgets...');
        await WidgetCacheHelper.refreshIOSWidgets(client, initData.settings);
        _logger.info('Background fetch: iOS widgets refreshed successfully');
      } catch (e) {
        _logger.warning('Background fetch: failed to refresh iOS widgets: $e');
      }

      bool foundFirstSchoolDay = false;
      for (int dayOffset = 1; dayOffset <= 5; dayOffset++) {
        final candidateDay = endOfWeek.add(Duration(days: dayOffset));

        if (candidateDay.weekday == DateTime.saturday ||
            candidateDay.weekday == DateTime.sunday) {
          continue;
        }

        try {
          final candidateDayEnd = candidateDay.add(const Duration(days: 1));
          final response = await client.getTimeTable(
            candidateDay,
            candidateDayEnd,
            forceCache: false,
          );

          if (response.response != null && response.response!.isNotEmpty) {
            final schoolLessons = response.response!.where((lesson) {
              final uid = lesson.uid.toLowerCase();
              return uid.contains('orarendiora') ||
                  uid.contains('tanitasiora') ||
                  uid.contains('uresora');
            }).toList();

            if (schoolLessons.isNotEmpty) {
              schoolLessons.sort((a, b) => a.start.compareTo(b.start));
              final firstLesson = schoolLessons.first;

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
                digitalSupportDeviceTypeList:
                    firstLesson.digitalSupportDeviceTypeList,
                createdAt: firstLesson.createdAt,
                lastModifiedAt: firstLesson.lastModifiedAt,
              );

              allLessons.add(markedLesson);

              const dayNames = [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
              ];
              final dayName = dayNames[candidateDay.weekday - 1];
              _logger.info(
                'Background fetch: added first lesson from next week $dayName (${firstLesson.name}) marked for notification scheduling only',
              );

              foundFirstSchoolDay = true;
              break;
            }
          }
        } catch (e) {
          _logger.warning(
            'Background fetch: could not fetch lessons for day offset $dayOffset: $e',
          );
        }
      }

      if (!foundFirstSchoolDay) {
        _logger.info(
          'Background fetch: no school lessons found in next week for push notification scheduling',
        );
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

      final userBellDelay = await _getUserBellDelay();
      _logger.info(
        'Background fetch: sending ${allLessons.length} lessons to backend',
      );
      final success = await _backendClient.updateTimetable(
        deviceToken: deviceToken,
        timetable: allLessons,
        bellDelay: userBellDelay,
      );

      if (success) {
        await _saveLastUpdate();
        _logger.info(
          'Background fetch: successfully sent timetable to backend',
        );
        _logger.info('Background fetch: keeping periodic scheduling active');
        return true;
      } else {
        _logger.warning(
          'Background fetch: failed to send timetable to backend',
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.severe('Background fetch: unexpected error: $e', e, stackTrace);
      return false;
    }
  }

  /// Check if LiveActivity is enabled in settings
  static Future<bool> isEnabled([
    SettingsStore? settingsStore,
    KretaClient? client,
  ]) async {
    try {
      return await _getUserLiveActivityEnabled(client: client);
    } catch (e) {
      _logger.warning('Error reading LiveActivity setting: $e');
      return false;
    }
  }

  /// Handle LiveActivity enabled state change
  /// Called from settings toggle callback
  static Future<void> handleEnabledChange(
    bool enabled, {
    bool isManual = false,
    KretaClient? client,
  }) async {
    if (!Platform.isIOS) return;

    try {
      final effectiveClient = client ?? initData.client;
      final studentId = _getCurrentStudentId(client: effectiveClient);
      if (studentId == null) {
        _logger.warning('Cannot change LiveActivity state: no current user');
        return;
      }

      if (!enabled) {
        final deviceToken =
            _cachedDeviceToken ?? await LiveActivityManager.getDeviceToken();
        if (deviceToken != null) {
          _logger.info('Notifying backend that Live Activity is disabled');
          await _backendClient.toggleLiveActivity(
            deviceToken: deviceToken,
            liveActivityEnabled: false,
          );
        }

        _logger.info('Ending all LiveActivities');
        await LiveActivityManager.endAllActivities();

        _logger.info('Clearing cache');
        await _clearCache();

        _logger.info('Stopping timetable monitoring');
        _stopTimetableMonitoring();

        await _setUserLiveActivityEnabled(false, client: effectiveClient);
        await syncGlobalSettingWithCurrentUser(client: effectiveClient);

        _logger.info(
          'LiveActivity disabled and user data cleared (device remains in backend for push notifications)',
        );
      } else {
        _logger.info('Showing privacy consent screen (manual: $isManual)');
        final bool? accepted = await _showPrivacyConsentScreen();

        if (accepted == true) {
          _logger.info('User accepted privacy policy');

          await _setUserLiveActivityEnabled(true, client: effectiveClient);
          await syncGlobalSettingWithCurrentUser(client: effectiveClient);

          final deviceToken =
              _cachedDeviceToken ?? await LiveActivityManager.getDeviceToken();

          if (deviceToken != null) {
            _logger.info('Notifying backend that Live Activity is enabled');
            await _backendClient.toggleLiveActivity(
              deviceToken: deviceToken,
              liveActivityEnabled: true,
            );
          }

          final studentResp = await effectiveClient.getStudent();
          final activeToken = pickActiveToken(
            tokens: initData.tokens,
            settings: initData.settings,
            preferredStudentIdNorm: effectiveClient.model.studentIdNorm,
          );
          final studentName =
              studentResp.response?.name ?? activeToken?.studentId ?? "Student";

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

      final enabled = await _getUserLiveActivityEnabled(
        client: effectiveClient,
      );
      final everDeclined = await _getUserPrivacyEverDeclined(
        client: effectiveClient,
      );

      if (!enabled && !everDeclined) {
        _logger.info(
          'First use or new user - showing privacy consent automatically',
        );
        await handleEnabledChange(
          true,
          isManual: false,
          client: effectiveClient,
        );
      } else {
        _logger.info(
          'User already has LiveActivity setting: enabled=$enabled, declined=$everDeclined',
        );
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
        builder: (context) => LiveActivityConsentScreen(data: initData),
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
  static Future<void> _onPushTokenReceived(
    String activityId,
    String pushToken,
  ) async {
    _logger.info('LiveActivity push token received, updating backend...');

    try {
      final deviceToken =
          _cachedDeviceToken ?? await LiveActivityManager.getDeviceToken();
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
    _logger.info('onUserLogin: Function called for $studentName');

    if (!Platform.isIOS || !_isInitialized) {
      _logger.warning(
        'onUserLogin: Returning early - Platform.isIOS=${Platform.isIOS}, _isInitialized=$_isInitialized',
      );
      return;
    }

    final liveActivityEnabled = await isEnabled(settingsStore, client);
    final morningNotificationEnabled =
        _getCurrentMorningNotificationEnabled() ?? false;
    _logger.info(
      'onUserLogin: liveActivityEnabled=$liveActivityEnabled, morningNotificationEnabled=$morningNotificationEnabled',
    );

    if (!liveActivityEnabled && !morningNotificationEnabled) {
      _logger.warning(
        'onUserLogin: Both Live Activity and Morning Notifications are disabled, returning early',
      );
      return;
    }

    try {
      _logger.info('onUserLogin: Starting timetable fetch');
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      List<Lesson> allLessons = [];

      try {
        _logger.info(
          'onUserLogin: Attempting to fetch fresh timetable from KRÉTA API',
        );
        final timetableResponse = await client.getTimeTable(
          startOfWeek,
          endOfWeek,
          forceCache: false,
        );

        if (timetableResponse.response != null) {
          allLessons = List<Lesson>.from(timetableResponse.response!);
          _logger.info(
            'onUserLogin: Successfully fetched ${allLessons.length} lessons from KRÉTA API',
          );
        } else {
          throw Exception('KRÉTA API returned null response');
        }
      } catch (e) {
        _logger.warning(
          'onUserLogin: KRÉTA API failed ($e), falling back to cache',
        );
        try {
          final cachedResponse = await client.getTimeTable(
            startOfWeek,
            endOfWeek,
            forceCache: true,
          );
          if (cachedResponse.response != null) {
            allLessons = List<Lesson>.from(cachedResponse.response!);
            _logger.info(
              'onUserLogin: Successfully loaded ${allLessons.length} lessons from cache',
            );
          } else {
            _logger.severe('onUserLogin: Both API and cache failed');
            return;
          }
        } catch (cacheError) {
          _logger.severe(
            'onUserLogin: Cache fallback also failed: $cacheError',
          );
          return;
        }
      }

      if (allLessons.isEmpty) {
        _logger.warning('onUserLogin: No lessons found, returning early');
        return;
      }

      final nextWeekStart = endOfWeek.add(const Duration(days: 1));
      final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));

      _logger.info(
        '[GlobalSearch] onUserLogin: Checking next week (${nextWeekStart.toString().split(' ')[0]} - ${nextWeekEnd.toString().split(' ')[0]}) for events',
      );

      List<Lesson> nextWeekBreakEvents = [];
      try {
        final nextWeekResponse = await client.getTimeTable(
          nextWeekStart,
          nextWeekEnd,
          forceCache: false,
        );

        if (nextWeekResponse.response != null) {
          nextWeekBreakEvents = nextWeekResponse.response!.where((lesson) {
            final uid = lesson.uid.toLowerCase();
            final name = lesson.name.toLowerCase();
            return uid.contains('tanevrendjeesemeny') &&
                !name.contains('tanítási nap') &&
                (name.contains('szünet') ||
                    name.contains('pihenőnap') ||
                    name.contains('munkaszüneti') ||
                    name.contains('ünnepnap') ||
                    name.contains('tanítás nélküli') ||
                    name.contains('nem órarendi nap'));
          }).toList();

          if (nextWeekBreakEvents.isNotEmpty) {
            _logger.info(
              '[GlobalSearch] onUserLogin: Found ${nextWeekBreakEvents.length} break event(s) in next week - triggering global searcher',
            );
          }
        }
      } catch (e) {
        _logger.warning(
          '[GlobalSearch] onUserLogin: Could not fetch next week: $e',
        );
      }

      if (nextWeekBreakEvents.isNotEmpty) {
        nextWeekBreakEvents.sort((a, b) => a.start.compareTo(b.start));
        final firstBreakEvent = nextWeekBreakEvents.first;

        _logger.info(
          '[GlobalSearch] onUserLogin: Triggering global break searcher from ${firstBreakEvent.date.split('T')[0]}',
        );

        final searchResult = await _globalBreakSearcher(
          client: client,
          searchStartDate: nextWeekStart,
        );

        if (searchResult.tokenExpired) {
          _tokenExpired = true;
          _logger.warning(
            '[GlobalSearch] onUserLogin: Token expired during global search',
          );
        }

        allLessons.addAll(searchResult.allLessons);

        _logger.info(
          '[GlobalSearch] onUserLogin: Global searcher returned ${searchResult.allLessons.length} lessons',
        );

        if (searchResult.firstSchoolDayAfterBreak != null) {
          final notificationLesson = Lesson(
            uid:
                '${searchResult.firstSchoolDayAfterBreak!.uid}__FOR_NOTIFICATION_ONLY',
            date: searchResult.firstSchoolDayAfterBreak!.date,
            start: searchResult.firstSchoolDayAfterBreak!.start,
            end: searchResult.firstSchoolDayAfterBreak!.end,
            name: searchResult.firstSchoolDayAfterBreak!.name,
            lessonNumber: searchResult.firstSchoolDayAfterBreak!.lessonNumber,
            teacher: searchResult.firstSchoolDayAfterBreak!.teacher,
            theme: searchResult.firstSchoolDayAfterBreak!.theme,
            roomName: searchResult.firstSchoolDayAfterBreak!.roomName,
            substituteTeacher:
                searchResult.firstSchoolDayAfterBreak!.substituteTeacher,
            type: searchResult.firstSchoolDayAfterBreak!.type,
            state: searchResult.firstSchoolDayAfterBreak!.state,
            canStudentEditHomework:
                searchResult.firstSchoolDayAfterBreak!.canStudentEditHomework,
            isHomeworkComplete:
                searchResult.firstSchoolDayAfterBreak!.isHomeworkComplete,
            attachments: searchResult.firstSchoolDayAfterBreak!.attachments,
            isDigitalLesson:
                searchResult.firstSchoolDayAfterBreak!.isDigitalLesson,
            digitalSupportDeviceTypeList: searchResult
                .firstSchoolDayAfterBreak!
                .digitalSupportDeviceTypeList,
            createdAt: searchResult.firstSchoolDayAfterBreak!.createdAt,
            lastModifiedAt:
                searchResult.firstSchoolDayAfterBreak!.lastModifiedAt,
          );

          allLessons.add(notificationLesson);
          _logger.info(
            '[GlobalSearch] onUserLogin: Added first school day after break for push notification: ${notificationLesson.date.split('T')[0]}',
          );
        }
      } else {
        _logger.info(
          '[GlobalSearch] onUserLogin: No break events in next week, searching for first school day...',
        );

        bool foundFirstSchoolDay = false;
        for (int dayOffset = 1; dayOffset <= 14; dayOffset++) {
          final candidateDay = endOfWeek.add(Duration(days: dayOffset));

          try {
            final candidateDayEnd = candidateDay.add(const Duration(days: 1));
            final response = await client.getTimeTable(
              candidateDay,
              candidateDayEnd,
              forceCache: false,
            );

            if (response.response != null && response.response!.isNotEmpty) {
              final schoolLessons = response.response!.where((lesson) {
                final uid = lesson.uid.toLowerCase();
                return uid.contains('orarendiora') ||
                    uid.contains('tanitasiora') ||
                    uid.contains('uresora');
              }).toList();

              if (schoolLessons.isNotEmpty) {
                schoolLessons.sort((a, b) => a.start.compareTo(b.start));
                final firstLesson = schoolLessons.first;

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
                  digitalSupportDeviceTypeList:
                      firstLesson.digitalSupportDeviceTypeList,
                  createdAt: firstLesson.createdAt,
                  lastModifiedAt: firstLesson.lastModifiedAt,
                );

                allLessons.add(markedLesson);
                _logger.info(
                  '[GlobalSearch] onUserLogin: Found first school day for push notification: ${candidateDay.toString().split(' ')[0]}',
                );

                foundFirstSchoolDay = true;
                break;
              }
            }
          } catch (e) {
            _logger.warning(
              '[GlobalSearch] onUserLogin: Could not fetch day offset $dayOffset: $e',
            );
          }
        }

        if (!foundFirstSchoolDay) {
          _logger.info(
            '[GlobalSearch] onUserLogin: No school lessons found in next 14 days for push notification scheduling',
          );
        }
      }

      final deviceToken = await _getOrWaitDeviceToken();

      if (deviceToken == null) {
        return;
      }

      String? currentLanguage = _getCurrentLanguageCode();

      final userMorningNotificationTime =
          await _getUserMorningNotificationTime();
      final userMorningNotificationEnabled =
          await _getUserMorningNotificationEnabled();
      final userLiveActivityEnabled = await _getUserLiveActivityEnabled();
      final userBellDelay = await _getUserBellDelay();

      final success = await _backendClient.registerDevice(
        deviceToken: deviceToken,
        timetable: allLessons,
        language: currentLanguage,
        bellDelay: userBellDelay,
        morningNotificationTime: userMorningNotificationTime,
        morningNotificationEnabled: userMorningNotificationEnabled,
        liveActivityEnabled: userLiveActivityEnabled,
      );

      if (success) {
        await _markAsRegistered();
        await _saveLastUpdate();

        if (liveActivityEnabled) {
          await _startPlaceholderActivity(allLessons, studentName);
        }

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
  /// IMPORTANT: Recreates Live Activity on every app open to refresh the 8-hour push token
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
        _logger.info(
          'Ending existing activity to refresh push token (8-hour expiration)',
        );
        await LiveActivityManager.endAllActivities();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final timetableResponse = await client.getTimeTable(
        startOfWeek,
        endOfWeek,
      );
      final allLessons = timetableResponse.response ?? [];

      await _startPlaceholderActivity(allLessons, studentName);

      _logger.info('New activity created with fresh push token');

      await checkAndUpdateTimetable(
        client: client,
        studentName: studentName,
        settingsStore: settingsStore,
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

      final deviceToken =
          _cachedDeviceToken ?? await LiveActivityManager.getDeviceToken();
      _logger.info(
        'onUserLogout: Device token = ${deviceToken?.substring(0, 10)}...',
      );

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
    bool forceUpdate = false,
  }) async {
    if (!Platform.isIOS || !_isInitialized) return;

    final liveActivityEnabled = await isEnabled(settingsStore, client);
    final morningNotificationEnabled =
        _getCurrentMorningNotificationEnabled() ?? false;

    if (!liveActivityEnabled && !morningNotificationEnabled) {
      _logger.info(
        'Both Live Activity and Morning Notifications are disabled, skipping timetable fetch',
      );
      return;
    }

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      List<Lesson> allLessons = [];

      try {
        final timetableResponse = await client.getTimeTable(
          startOfWeek,
          endOfWeek,
          forceCache: false,
        );

        if (timetableResponse.response != null) {
          allLessons = List<Lesson>.from(timetableResponse.response!);
        } else {
          throw Exception('KRÉTA API returned null response');
        }
      } catch (e) {
        _logger.warning(
          'checkAndUpdateTimetable: KRÉTA API failed ($e), falling back to cache',
        );
        try {
          final cachedResponse = await client.getTimeTable(
            startOfWeek,
            endOfWeek,
            forceCache: true,
          );
          if (cachedResponse.response != null) {
            allLessons = List<Lesson>.from(cachedResponse.response!);
          } else {
            _logger.severe(
              'checkAndUpdateTimetable: Both API and cache failed',
            );
            return;
          }
        } catch (cacheError) {
          _logger.severe(
            'checkAndUpdateTimetable: Cache fallback also failed: $cacheError',
          );
          return;
        }
      }

      final nextWeekStart = endOfWeek.add(const Duration(days: 1));
      final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));

      _logger.info(
        '[GlobalSearch] Checking next week (${nextWeekStart.toString().split(' ')[0]} - ${nextWeekEnd.toString().split(' ')[0]}) for events',
      );

      List<Lesson> nextWeekBreakEvents = [];
      try {
        final nextWeekResponse = await client.getTimeTable(
          nextWeekStart,
          nextWeekEnd,
          forceCache: false,
        );

        if (nextWeekResponse.response != null) {
          nextWeekBreakEvents = nextWeekResponse.response!.where((lesson) {
            final uid = lesson.uid.toLowerCase();
            final name = lesson.name.toLowerCase();
            return uid.contains('tanevrendjeesemeny') &&
                !name.contains('tanítási nap') &&
                (name.contains('szünet') ||
                    name.contains('pihenőnap') ||
                    name.contains('munkaszüneti') ||
                    name.contains('ünnepnap') ||
                    name.contains('tanítás nélküli') ||
                    name.contains('nem órarendi nap'));
          }).toList();

          if (nextWeekBreakEvents.isNotEmpty) {
            _logger.info(
              '[GlobalSearch] Found ${nextWeekBreakEvents.length} break event(s) in next week - triggering global searcher',
            );
          }
        }
      } catch (e) {
        _logger.warning('[GlobalSearch] Could not fetch next week: $e');
      }

      if (nextWeekBreakEvents.isNotEmpty) {
        nextWeekBreakEvents.sort((a, b) => a.start.compareTo(b.start));
        final firstBreakEvent = nextWeekBreakEvents.first;

        _logger.info(
          '[GlobalSearch] Triggering global break searcher from ${firstBreakEvent.date.split('T')[0]}',
        );

        final searchResult = await _globalBreakSearcher(
          client: client,
          searchStartDate: nextWeekStart,
        );

        if (searchResult.tokenExpired) {
          _tokenExpired = true;
          _logger.warning('[GlobalSearch] Token expired during global search');
        }

        allLessons.addAll(searchResult.allLessons);

        _logger.info(
          '[GlobalSearch] Global searcher returned ${searchResult.allLessons.length} lessons',
        );

        if (searchResult.firstSchoolDayAfterBreak != null) {
          final notificationLesson = Lesson(
            uid:
                '${searchResult.firstSchoolDayAfterBreak!.uid}__FOR_NOTIFICATION_ONLY',
            date: searchResult.firstSchoolDayAfterBreak!.date,
            start: searchResult.firstSchoolDayAfterBreak!.start,
            end: searchResult.firstSchoolDayAfterBreak!.end,
            name: searchResult.firstSchoolDayAfterBreak!.name,
            lessonNumber: searchResult.firstSchoolDayAfterBreak!.lessonNumber,
            teacher: searchResult.firstSchoolDayAfterBreak!.teacher,
            theme: searchResult.firstSchoolDayAfterBreak!.theme,
            roomName: searchResult.firstSchoolDayAfterBreak!.roomName,
            substituteTeacher:
                searchResult.firstSchoolDayAfterBreak!.substituteTeacher,
            type: searchResult.firstSchoolDayAfterBreak!.type,
            state: searchResult.firstSchoolDayAfterBreak!.state,
            canStudentEditHomework:
                searchResult.firstSchoolDayAfterBreak!.canStudentEditHomework,
            isHomeworkComplete:
                searchResult.firstSchoolDayAfterBreak!.isHomeworkComplete,
            attachments: searchResult.firstSchoolDayAfterBreak!.attachments,
            isDigitalLesson:
                searchResult.firstSchoolDayAfterBreak!.isDigitalLesson,
            digitalSupportDeviceTypeList: searchResult
                .firstSchoolDayAfterBreak!
                .digitalSupportDeviceTypeList,
            createdAt: searchResult.firstSchoolDayAfterBreak!.createdAt,
            lastModifiedAt:
                searchResult.firstSchoolDayAfterBreak!.lastModifiedAt,
          );

          allLessons.add(notificationLesson);
          _logger.info(
            '[GlobalSearch] Added first school day after break for push notification: ${notificationLesson.date.split('T')[0]}',
          );
        }
      } else {
        _logger.info(
          '[GlobalSearch] No break events in next week, searching for first school day...',
        );

        bool foundFirstSchoolDay = false;
        for (int dayOffset = 1; dayOffset <= 14; dayOffset++) {
          final candidateDay = endOfWeek.add(Duration(days: dayOffset));

          try {
            final candidateDayEnd = candidateDay.add(const Duration(days: 1));
            final response = await client.getTimeTable(
              candidateDay,
              candidateDayEnd,
              forceCache: false,
            );

            if (response.response != null && response.response!.isNotEmpty) {
              final schoolLessons = response.response!.where((lesson) {
                final uid = lesson.uid.toLowerCase();
                return uid.contains('orarendiora') ||
                    uid.contains('tanitasiora') ||
                    uid.contains('uresora');
              }).toList();

              if (schoolLessons.isNotEmpty) {
                schoolLessons.sort((a, b) => a.start.compareTo(b.start));
                final firstLesson = schoolLessons.first;

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
                  digitalSupportDeviceTypeList:
                      firstLesson.digitalSupportDeviceTypeList,
                  createdAt: firstLesson.createdAt,
                  lastModifiedAt: firstLesson.lastModifiedAt,
                );

                allLessons.add(markedLesson);
                _logger.info(
                  '[GlobalSearch] Found first school day for push notification: ${candidateDay.toString().split(' ')[0]}',
                );

                foundFirstSchoolDay = true;
                break;
              }
            }
          } catch (e) {
            _logger.warning(
              '[GlobalSearch] Could not fetch day offset $dayOffset: $e',
            );
          }
        }

        if (!foundFirstSchoolDay) {
          _logger.info(
            '[GlobalSearch] No school lessons found in next 14 days for push notification scheduling',
          );
        }
      }

      if (allLessons.isEmpty) {
        await LiveActivityManager.endAllActivities();
        return;
      }

      final deviceToken = await _getOrWaitDeviceToken();
      if (deviceToken == null) return;

      bool shouldUpdate = forceUpdate;

      if (!forceUpdate) {
        final lastUpdate = await _getLastUpdate();
        final hasChanges = await _backendClient.checkTimetableChanges(
          deviceToken: deviceToken,
          lastUpdated: lastUpdate,
        );
        shouldUpdate = hasChanges;
      }

      if (shouldUpdate) {
        if (forceUpdate) {
          _logger.info(
            'Forcing timetable update (notification settings changed)...',
          );
        } else {
          _logger.info('Timetable changes detected, sending to backend...');
        }

        final userBellDelay = await _getUserBellDelay();
        final success = await _backendClient.updateTimetable(
          deviceToken: deviceToken,
          timetable: allLessons,
          bellDelay: userBellDelay,
        );

        if (success) {
          await _saveLastUpdate();
          _logger.info(
            'Timetable sent to backend successfully. Backend will update LiveActivity.',
          );
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
    _updateTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
      await checkAndUpdateTimetable(
        client: client,
        studentName: studentName,
        settingsStore: settingsStore,
      );
    });

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
    await checkAndUpdateTimetable(client: client, studentName: studentName);
  }

  /// Starts a minimal placeholder activity shell - backend will update with real data
  static Future<void> _startPlaceholderActivity(
    List<Lesson> allLessons,
    String studentName,
  ) async {
    // Always end existing activities to ensure fresh token (8-hour expiration)
    final activeActivities = await LiveActivityManager.getActiveActivities();
    if (activeActivities.isNotEmpty) {
      _logger.info(
        '_startPlaceholderActivity: Ending existing activities before creating new one',
      );
      await LiveActivityManager.endAllActivities();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _logger.info(
      '_startPlaceholderActivity: Creating minimal loading shell, backend will update.',
    );

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
      final emptyType = NameUidDesc(
        uid: 'placeholder',
        name: 'Placeholder',
        description: null,
      );
      final emptyState = NameUidDesc(
        uid: 'active',
        name: 'Active',
        description: null,
      );

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

    _logger.info(
      '_startPlaceholderActivity: Placeholder created, waiting for backend update.',
    );
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
  static Future<String?> _getOrWaitDeviceToken({
    Duration timeout = const Duration(seconds: 5),
  }) async {
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
  /// Waits 3 seconds after the last change before sending update to backend
  /// If value changes during the wait, reschedules the update with the new value
  /// Also saves the setting per-user immediately
  static void onBellDelayChanged(double newValue) {
    if (!Platform.isIOS || !_isInitialized) return;

    _logger.info(
      'BellDelay changed to $newValue minutes, scheduling debounced update',
    );

    _setUserBellDelay(newValue);

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
      _logger.info(
        'BellDelay $bellDelayToSend already sent to backend, skipping',
      );
      _pendingBellDelay = null;
      return;
    }

    try {
      final deviceToken = await _getOrWaitDeviceToken();
      if (deviceToken == null) {
        _logger.warning('No device token available to update bellDelay');
        return;
      }

      _logger.info(
        'Sending bellDelay update to backend: $bellDelayToSend minutes',
      );

      final success = await _backendClient.updateBellDelay(
        deviceToken: deviceToken,
        bellDelay: bellDelayToSend,
      );

      if (success) {
        _lastSentBellDelay = bellDelayToSend;
        _logger.info('BellDelay updated successfully in backend');

        if (_pendingBellDelay != bellDelayToSend) {
          _logger.info(
            'BellDelay changed to $_pendingBellDelay during update, scheduling another update',
          );
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

  /// Handle morning notification enabled change with debounce
  /// Waits 3 seconds after the last change before sending update to backend
  /// Also saves the setting per-user immediately
  static void onMorningNotificationEnabledChanged(bool newValue) {
    if (!Platform.isIOS || !_isInitialized) return;

    _logger.info(
      'Morning notification enabled changed to $newValue, scheduling debounced update',
    );

    _setUserMorningNotificationEnabled(newValue);

    _morningNotificationDebounceTimer?.cancel();

    _pendingMorningNotificationEnabled = newValue;

    _morningNotificationDebounceTimer = Timer(
      _morningNotificationDebounceInterval,
      () async {
        await _sendMorningNotificationUpdate();
      },
    );
  }

  /// Handle morning notification time change with debounce
  /// Waits 3 seconds after the last change before sending update to backend
  /// Also saves the setting per-user immediately
  static void onMorningNotificationTimeChanged(double newValue) {
    if (!Platform.isIOS || !_isInitialized) return;

    _logger.info(
      'Morning notification time changed to $newValue minutes, scheduling debounced update',
    );

    _setUserMorningNotificationTime(newValue.toInt());

    _morningNotificationDebounceTimer?.cancel();

    _pendingMorningNotificationTime = newValue;

    _morningNotificationDebounceTimer = Timer(
      _morningNotificationDebounceInterval,
      () async {
        await _sendMorningNotificationUpdate();
      },
    );
  }

  /// Internal function to send morning notification settings update to backend
  static Future<void> _sendMorningNotificationUpdate() async {
    final enabledToSend =
        _pendingMorningNotificationEnabled ??
        _getCurrentMorningNotificationEnabled();
    final timeToSend =
        _pendingMorningNotificationTime ?? _getCurrentMorningNotificationTime();

    if (_lastSentMorningNotificationEnabled == enabledToSend &&
        _lastSentMorningNotificationTime == timeToSend) {
      _logger.info(
        'Morning notification settings already sent to backend, skipping',
      );
      _pendingMorningNotificationEnabled = null;
      _pendingMorningNotificationTime = null;
      return;
    }

    try {
      final deviceToken = await _getOrWaitDeviceToken();
      if (deviceToken == null) {
        _logger.warning(
          'No device token available to update morning notification settings',
        );
        return;
      }

      _logger.info(
        'Sending morning notification settings update to backend: enabled=$enabledToSend, time=$timeToSend minutes',
      );

      final success = await _backendClient.updateMorningNotificationSettings(
        deviceToken: deviceToken,
        morningNotificationEnabled: enabledToSend,
        morningNotificationTime: timeToSend?.toInt(),
      );

      if (success) {
        final wasDisabled = _lastSentMorningNotificationEnabled == false;
        final isNowEnabled = enabledToSend == true;

        _lastSentMorningNotificationEnabled = enabledToSend;
        _lastSentMorningNotificationTime = timeToSend;
        _logger.info(
          'Morning notification settings updated successfully in backend',
        );

        if (wasDisabled && isNowEnabled) {
          _logger.info(
            'Morning notifications re-enabled, fetching timetable to recreate notifications',
          );
          try {
            final client = initData.client;
            final settingsStore = initData.settings;

            final studentResp = await client.getStudent();
            final studentName =
                studentResp.response?.name ??
                client.model.studentId ??
                'Student';

            await checkAndUpdateTimetable(
              client: client,
              studentName: studentName,
              settingsStore: settingsStore,
              forceUpdate: true,
            );
            _logger.info(
              'Timetable fetch completed after re-enabling notifications',
            );
          } catch (e) {
            _logger.severe(
              'Error fetching timetable after re-enabling notifications: $e',
            );
          }
        }

        final currentEnabled =
            _pendingMorningNotificationEnabled ??
            _getCurrentMorningNotificationEnabled();
        final currentTime =
            _pendingMorningNotificationTime ??
            _getCurrentMorningNotificationTime();

        if (_lastSentMorningNotificationEnabled != currentEnabled ||
            _lastSentMorningNotificationTime != currentTime) {
          _logger.info(
            'Morning notification settings changed during update, scheduling another update',
          );
          _morningNotificationDebounceTimer?.cancel();
          _morningNotificationDebounceTimer = Timer(
            _morningNotificationDebounceInterval,
            () async {
              await _sendMorningNotificationUpdate();
            },
          );
        } else {
          _pendingMorningNotificationEnabled = null;
          _pendingMorningNotificationTime = null;
        }
      } else {
        _logger.warning(
          'Failed to update morning notification settings in backend',
        );
      }
    } catch (e) {
      _logger.severe('Error updating morning notification settings: $e');
    }
  }

  /// Get current morning notification enabled value from settings
  static bool? _getCurrentMorningNotificationEnabled() {
    try {
      if (!initDone) {
        return null;
      }
      final setting =
          initData.settings
                  .group("settings")
                  .subGroup("notifications")["morning_notification_enabled"]
              as SettingsBoolean?;
      return setting?.value;
    } catch (e) {
      _logger.warning('Error getting current morning notification enabled: $e');
      return null;
    }
  }

  /// Get current morning notification time value from settings
  static double? _getCurrentMorningNotificationTime() {
    try {
      if (!initDone) {
        return null;
      }
      final setting =
          initData.settings
                  .group("settings")
                  .subGroup("notifications")["morning_notification_time"]
              as SettingsDouble?;
      return setting?.value;
    } catch (e) {
      _logger.warning('Error getting current morning notification time: $e');
      return null;
    }
  }

  /// Global break searcher result
  static Future<_GlobalSearchResult> _globalBreakSearcher({
    required KretaClient client,
    required DateTime searchStartDate,
  }) async {
    List<Lesson> allLessons = [];
    Lesson? lastBreakDay;
    Lesson? firstSchoolDayAfterBreak;
    bool tokenExpired = false;

    DateTime currentSearchDate = searchStartDate;
    int weeksSearched = 0;
    const maxWeeks = 26;

    _logger.info(
      '[GlobalBreakSearcher] Starting search from ${currentSearchDate.toString().split(' ')[0]}',
    );

    while (weeksSearched < maxWeeks) {
      final weekStart = currentSearchDate;
      final weekEnd = weekStart.add(const Duration(days: 6));

      _logger.info(
        '[GlobalBreakSearcher] Fetching week ${weeksSearched + 1}: ${weekStart.toString().split(' ')[0]} - ${weekEnd.toString().split(' ')[0]}',
      );

      try {
        final response = await client.getTimeTable(
          weekStart,
          weekEnd,
          forceCache: false,
        );

        if (response.response != null && response.response!.isNotEmpty) {
          final weekLessons = response.response!;

          final breakEvents = weekLessons.where((lesson) {
            final uid = lesson.uid.toLowerCase();
            final name = lesson.name.toLowerCase();
            return uid.contains('tanevrendjeesemeny') &&
                !name.contains('tanítási nap') &&
                (name.contains('pihenőnap') ||
                    name.contains('munkaszüneti') ||
                    name.contains('ünnepnap') ||
                    name.contains('tanítás nélküli') ||
                    name.contains('nem órarendi nap'));
          }).toList();

          final schoolLessons = weekLessons.where((lesson) {
            final uid = lesson.uid.toLowerCase();
            return uid.contains('orarendiora') ||
                uid.contains('tanitasiora') ||
                uid.contains('uresora');
          }).toList();

          allLessons.addAll(weekLessons);

          if (breakEvents.isNotEmpty) {
            breakEvents.sort((a, b) => a.start.compareTo(b.start));
            lastBreakDay = breakEvents.last;
            _logger.info(
              '[GlobalBreakSearcher] Found ${breakEvents.length} break event(s) in week ${weeksSearched + 1}, last: ${lastBreakDay.name} on ${lastBreakDay.date.split('T')[0]}',
            );
          } else if (schoolLessons.isNotEmpty) {
            schoolLessons.sort((a, b) => a.start.compareTo(b.start));
            firstSchoolDayAfterBreak = schoolLessons.first;
            _logger.info(
              '[GlobalBreakSearcher] Found first school day after break: ${firstSchoolDayAfterBreak.name} on ${firstSchoolDayAfterBreak.date.split('T')[0]}',
            );
            break;
          } else {
            _logger.info(
              '[GlobalBreakSearcher] Week ${weeksSearched + 1} is empty, continuing search...',
            );
          }
        } else {
          _logger.info(
            '[GlobalBreakSearcher] Week ${weeksSearched + 1} returned no data, continuing search...',
          );
        }
      } catch (e) {
        final isTokenError =
            e.toString().contains('TokenExpiredException') ||
            e.toString().contains('InvalidGrantException');

        if (isTokenError) {
          tokenExpired = true;
          _logger.warning(
            '[GlobalBreakSearcher] Token expired during week ${weeksSearched + 1}, falling back to cache',
          );
        } else {
          _logger.warning(
            '[GlobalBreakSearcher] Error fetching week ${weeksSearched + 1}: $e',
          );
        }

        try {
          final cachedResponse = await client.getTimeTable(
            weekStart,
            weekEnd,
            forceCache: true,
          );

          if (cachedResponse.response != null &&
              cachedResponse.response!.isNotEmpty) {
            final weekLessons = cachedResponse.response!;
            _logger.info(
              '[GlobalBreakSearcher] Loaded ${weekLessons.length} lessons from cache for week ${weeksSearched + 1}',
            );

            final breakEvents = weekLessons.where((lesson) {
              final uid = lesson.uid.toLowerCase();
              final name = lesson.name.toLowerCase();
              return uid.contains('tanevrendjeesemeny') &&
                  !name.contains('tanítási nap') &&
                  (name.contains('pihenőnap') ||
                      name.contains('munkaszüneti') ||
                      name.contains('ünnepnap') ||
                      name.contains('tanítás nélküli') ||
                      name.contains('nem órarendi nap'));
            }).toList();

            final schoolLessons = weekLessons.where((lesson) {
              final uid = lesson.uid.toLowerCase();
              return uid.contains('orarendiora') ||
                  uid.contains('tanitasiora') ||
                  uid.contains('uresora');
            }).toList();

            allLessons.addAll(weekLessons);

            if (breakEvents.isNotEmpty) {
              breakEvents.sort((a, b) => a.start.compareTo(b.start));
              lastBreakDay = breakEvents.last;
              _logger.info(
                '[GlobalBreakSearcher] Found ${breakEvents.length} break event(s) in cached week ${weeksSearched + 1}, last: ${lastBreakDay.name} on ${lastBreakDay.date.split('T')[0]}',
              );
            } else if (schoolLessons.isNotEmpty) {
              schoolLessons.sort((a, b) => a.start.compareTo(b.start));
              firstSchoolDayAfterBreak = schoolLessons.first;
              _logger.info(
                '[GlobalBreakSearcher] Found first school day after break in cache: ${firstSchoolDayAfterBreak.name} on ${firstSchoolDayAfterBreak.date.split('T')[0]}',
              );
              break;
            }
          } else {
            _logger.info(
              '[GlobalBreakSearcher] No cache available for week ${weeksSearched + 1}',
            );
          }
        } catch (cacheError) {
          _logger.warning(
            '[GlobalBreakSearcher] Cache fallback also failed for week ${weeksSearched + 1}: $cacheError',
          );
        }
      }

      currentSearchDate = currentSearchDate.add(const Duration(days: 7));
      weeksSearched++;

      if (lastBreakDay != null && firstSchoolDayAfterBreak != null) {
        break;
      }
    }

    if (weeksSearched >= maxWeeks) {
      _logger.warning(
        '[GlobalBreakSearcher] Reached maximum search limit ($maxWeeks weeks)',
      );
    }

    _logger.info(
      '[GlobalBreakSearcher] Search completed: ${allLessons.length} lessons found, last break: ${lastBreakDay?.date.split('T')[0] ?? 'none'}, first school day: ${firstSchoolDayAfterBreak?.date.split('T')[0] ?? 'none'}, tokenExpired: $tokenExpired',
    );

    return _GlobalSearchResult(
      allLessons: allLessons,
      lastBreakDay: lastBreakDay,
      firstSchoolDayAfterBreak: firstSchoolDayAfterBreak,
      tokenExpired: tokenExpired,
    );
  }
}

/// Result of global break searcher
class _GlobalSearchResult {
  final List<Lesson> allLessons;
  final Lesson? lastBreakDay;
  final Lesson? firstSchoolDayAfterBreak;
  final bool tokenExpired;

  _GlobalSearchResult({
    required this.allLessons,
    this.lastBreakDay,
    this.firstSchoolDayAfterBreak,
    this.tokenExpired = false,
  });
}
