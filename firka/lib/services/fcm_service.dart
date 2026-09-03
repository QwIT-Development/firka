import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/api/client/notification_backend_client.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/firebase_options.dart';
import 'package:firka/services/fcm_headless_bootstrap.dart';
import 'package:firka/services/local_notification_service.dart';
import 'package:firka/services/notification_diff_service.dart';

const _wakeupDataType = 'wakeup';
const _hourlyTopic = 'wakeup-hourly';
const _twoHourlyTopic = 'wakeup-2hourly';
const _topicPrefix = '/topics/';

// Fixed id (outside the hash-derived range used by NotificationDiffService)
// so the debug "message received" notification always updates in place.
const _debugMessageNotificationId = 900001;

/// Must be a top-level function: FirebaseMessaging invokes it in its own
/// background isolate, where none of firka's normal app state is set up.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.data['type'] == _wakeupDataType) {
    await NotificationDiffService.checkAll();
  } else {
    // checkAll() bootstraps Settings itself; other message types need it
    // bootstrapped explicitly before FcmService can read the debug toggle.
    await bootstrapHeadless();
  }

  await FcmService._maybeShowDebugMessageNotification(message);
}

/// Coordinates FCM push notification registration with firka's backend.
/// Android-only for now: `flutterfire configure` has only been run for
/// Android, so `DefaultFirebaseOptions.currentPlatform` throws on iOS. Once
/// iOS is configured (re-run `flutterfire configure` with both platforms
/// selected), drop the `Platform.isAndroid` guard in [initialize] to make
/// this cross-platform like the rest of the service already assumes.
/// Push is enabled by default; the master switch is SettingsRegistry.notifyAll,
/// toggleable from the notifications settings page.
class FcmService {
  static final Logger _logger = Logger('FcmService');
  static final NotificationBackendClient _backendClient =
      NotificationBackendClient();

  static bool _isInitialized = false;
  static String? _cachedToken;
  static DateTime? _lastTokenRefreshAt;

  /// Debug/status accessors for the developer settings screen.
  static bool get isInitialized => _isInitialized;
  static String? get cachedToken => _cachedToken;
  static DateTime? get lastTokenRefreshAt => _lastTokenRefreshAt;
  static String get subscribedTopic =>
      _topicFor(Settings.notifyWakeupInterval.value);

  /// Current notification permission status, without prompting for it.
  /// Returns null if Firebase hasn't been initialized yet.
  static Future<AuthorizationStatus?> permissionStatus() async {
    if (!_isInitialized) return null;
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      _logger.warning('Error reading notification permission status: $e');
      return null;
    }
  }

  /// Sets up Firebase + the background handler and starts listening for
  /// token refreshes. Safe to call once at app startup, before login.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _cachedToken = token;
        _lastTokenRefreshAt = DateTime.now();
        _logger.info('FCM token refreshed');
        unawaited(_registerIfLoggedIn());
      });

      // Data-only wakeups don't display anything on their own; if the app
      // happens to be foregrounded when one arrives, run the same
      // fetch+diff+notify pipeline as the background isolate does.
      FirebaseMessaging.onMessage.listen((message) {
        if (message.data['type'] == _wakeupDataType) {
          unawaited(NotificationDiffService.checkAll());
        }
        unawaited(_maybeShowDebugMessageNotification(message));
      });

      _isInitialized = true;
      _logger.info('FcmService initialized');
    } catch (e, st) {
      _logger.severe('Failed to initialize FcmService: $e', e, st);
    }
  }

  /// Best-effort label for which channel a message arrived on: the topic
  /// name for topic-targeted messages (FCM sets `from` to
  /// `/topics/<name>`), the `type` data field otherwise, or the raw
  /// sender id as a last resort.
  static String _channelLabel(RemoteMessage message) {
    final from = message.from;
    if (from != null && from.startsWith(_topicPrefix)) {
      return from.substring(_topicPrefix.length);
    }
    final type = message.data['type'];
    if (type != null) return type.toString();
    return from ?? 'unknown';
  }

  static Future<void> _maybeShowDebugMessageNotification(
    RemoteMessage message,
  ) async {
    if (!Settings.fcmDebugNotifyOnMessage.value) return;
    try {
      await LocalNotificationService.show(
        id: _debugMessageNotificationId,
        title: 'FCM message received',
        body: '${DateTime.now().toIso8601String()} - ${_channelLabel(message)}',
      );
    } catch (e, st) {
      _logger.warning('Failed to show debug FCM message notification: $e', e, st);
    }
  }

  static Future<bool> _requestPermission() async {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }

    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  static String? _currentStudentId(KretaClient? client) {
    try {
      final effectiveClient = client ?? (initDone ? initData.client : null);
      return effectiveClient?.cache.token.username;
    } catch (e) {
      _logger.warning('Error reading current studentId: $e');
      return null;
    }
  }

  static Future<void> _registerIfLoggedIn() async {
    final studentId = _currentStudentId(null);
    if (studentId == null) return;
    await _register(studentId: studentId);
  }

  static String _topicFor(NotifyWakeupInterval interval) =>
      interval == NotifyWakeupInterval.hourly ? _hourlyTopic : _twoHourlyTopic;

  /// Subscribes to the wakeup topic matching the user's chosen interval and
  /// unsubscribes from the other one, so only one cadence of pushes arrives.
  static Future<void> _subscribeToWakeupTopic() async {
    final topic = _topicFor(Settings.notifyWakeupInterval.value);
    final other = topic == _hourlyTopic ? _twoHourlyTopic : _hourlyTopic;
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    await FirebaseMessaging.instance.unsubscribeFromTopic(other);
  }

  static Future<void> _unsubscribeFromWakeupTopics() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(_hourlyTopic);
    await FirebaseMessaging.instance.unsubscribeFromTopic(_twoHourlyTopic);
  }

  /// Called from the notifyWakeupInterval settings effect when the user
  /// switches between hourly/2-hourly.
  static Future<void> handleWakeupIntervalChange() async {
    if (!_isInitialized || !Settings.notifyAll.value) return;
    await _subscribeToWakeupTopic();
  }

  static Future<void> _register({required String studentId}) async {
    try {
      final token = _cachedToken ??= await FirebaseMessaging.instance.getToken();
      if (token == null) {
        _logger.warning('No FCM token available to register');
        return;
      }

      await _backendClient.registerToken(
        fcmToken: token,
        studentId: studentId,
        notifyAll: Settings.notifyAll.value,
        notifyGrades: Settings.notifyGrades.value,
        notifyHomeworkTests: Settings.notifyHomeworkTests.value,
        notifyAbsences: Settings.notifyAbsences.value,
        notifyLessons: Settings.notifyLessons.value,
        notifyMessages: Settings.notifyMessages.value,
      );
    } catch (e, st) {
      _logger.severe('Failed to register FCM token: $e', e, st);
    }
  }

  /// Called after a successful login (push is on by default, per
  /// SettingsRegistry.notifyAll's default value of true).
  static Future<void> onUserLogin({
    required KretaClient client,
    SettingsRepository? settingsStore,
  }) async {
    if (!_isInitialized) return;
    if (!Settings.notifyAll.value) {
      _logger.info('onUserLogin: push notifications disabled, skipping');
      return;
    }

    final studentId = _currentStudentId(client);
    if (studentId == null) {
      _logger.warning('onUserLogin: no current user, skipping');
      return;
    }

    final granted = await _requestPermission();
    if (!granted) {
      _logger.info('onUserLogin: notification permission not granted');
      return;
    }

    await _register(studentId: studentId);
    await _subscribeToWakeupTopic();
  }

  /// Called on logout: unregisters the current token from the backend.
  static Future<void> onUserLogout() async {
    await _unsubscribeFromWakeupTopics();

    final token = _cachedToken;
    if (token == null) return;

    try {
      await _backendClient.unregisterToken(fcmToken: token);
    } catch (e, st) {
      _logger.severe('Failed to unregister FCM token: $e', e, st);
    }
    _cachedToken = null;
  }

  /// Called from the notifyAll settings effect when the master toggle changes.
  static Future<void> handleEnabledChange(bool enabled) async {
    if (!_isInitialized) return;

    if (!enabled) {
      await _unsubscribeFromWakeupTopics();
      final token = _cachedToken;
      if (token != null) {
        try {
          await _backendClient.unregisterToken(fcmToken: token);
        } catch (e, st) {
          _logger.severe('Failed to unregister FCM token: $e', e, st);
        }
      }
      return;
    }

    final granted = await _requestPermission();
    if (!granted) {
      _logger.info('handleEnabledChange: notification permission not granted');
      return;
    }

    final studentId = _currentStudentId(null);
    if (studentId == null) return;
    await _register(studentId: studentId);
    await _subscribeToWakeupTopic();
  }

  /// Called when a category toggle (grades/homework/etc.) changes, to push
  /// the updated preferences to the backend for the already-registered token.
  static Future<void> updatePreferences() async {
    if (!_isInitialized || !Settings.notifyAll.value) return;
    final token = _cachedToken;
    if (token == null) return;

    try {
      await _backendClient.updatePreferences(
        fcmToken: token,
        notifyAll: Settings.notifyAll.value,
        notifyGrades: Settings.notifyGrades.value,
        notifyHomeworkTests: Settings.notifyHomeworkTests.value,
        notifyAbsences: Settings.notifyAbsences.value,
        notifyLessons: Settings.notifyLessons.value,
        notifyMessages: Settings.notifyMessages.value,
      );
    } catch (e, st) {
      _logger.severe('Failed to update FCM notification preferences: $e', e, st);
    }
  }
}
