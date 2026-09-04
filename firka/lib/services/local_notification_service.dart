import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications for showing the
/// notifications posted by [NotificationDiffService] after a background FCM
/// wakeup. Usable from both the main isolate and the headless background
/// isolate (each needs its own [init] call — plugin state isn't shared
/// across isolates).
class LocalNotificationService {
  static const _channelId = 'firka_updates';
  static const _channelName = 'Firka frissítések';
  static const _channelDescription =
      'Új jegyek, házi feladatok, hiányzások és üzenetek értesítései.';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('ic_notification');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Shows a single notification. [id] should be stable per logical
  /// notification (e.g. derived from account key + category) so a repeat
  /// wakeup that finds the same new items updates rather than duplicates it.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
