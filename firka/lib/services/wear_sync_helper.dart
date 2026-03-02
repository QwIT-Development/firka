import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/services/wear_sync_cache.dart';

/// Helper for Wear OS ↔ phone communication (Android only).
/// Handles sync service, watch_connectivity messages, and sending data to the watch.
class WearSyncHelper {
  WearSyncHelper._();

  static const _wearSyncChannel = MethodChannel('app.firka/wear_sync');
  static WatchConnectivity? _watchConnectivity;
  static WatchConnectivity get _watchConnectivityInstance {
    _watchConnectivity ??= WatchConnectivity();
    return _watchConnectivity!;
  }

  /// Sends a fire-and-forget message to the Wear OS watch (payload sent as JSON string).
  static Future<void> sendMessageToWatch(Map<String, dynamic> message) async {
    if (!Platform.isAndroid) return;
    await _watchConnectivityInstance.sendMessage(<String, dynamic>{
      'data': jsonEncode(message),
    });
  }

  /// Starts the Wear sync foreground service (Android only).
  static Future<void> startWearSyncService(
    String cachePath,
    String appDirPath,
  ) async {
    if (!Platform.isAndroid) return;
    await _wearSyncChannel.invokeMethod<void>(
      'startWearSyncService',
      <String, dynamic>{'cachePath': cachePath, 'appDirPath': appDirPath},
    );
  }

  /// Builds fresh sync payload, writes cache, and starts the Wear sync service (Android only).
  static Future<void> startWearSyncServiceWithFreshCache(
    KretaClient client,
    String appDirPath,
  ) async {
    if (!Platform.isAndroid) return;
    final payload = await buildWearSyncPayload(client);
    if (payload == null) return;
    final path = await getWearSyncCachePath();
    await writeWearSyncCache(path, payload);
    await startWearSyncService(path, appDirPath);
  }

  /// Sets the method call handler for getLocalizedString (Android). Call once when initData is ready.
  static void setWearSyncMethodCallHandler() {
    if (!Platform.isAndroid) return;
    _wearSyncChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'getLocalizedString') {
        final key = call.arguments as String?;
        return getLocalizedString(key);
      }
      return null;
    });
  }

  /// Returns the localized string for [key] from l10n. Used by Kotlin for notification title/text.
  static String? getLocalizedString(String? key) {
    if (key == null || !initDone) return null;
    switch (key) {
      case 'wearSyncNotificationTitle':
        return initData.l10n.wearSyncNotificationTitle;
      case 'wearSyncNotificationText':
        return initData.l10n.wearSyncNotificationText;
      default:
        return null;
    }
  }

  /// Stops the Wear sync foreground service (Android only).
  static Future<void> stopWearSyncService() async {
    if (!Platform.isAndroid) return;
    await _wearSyncChannel.invokeMethod<void>('stopWearSyncService');
  }

  /// Runs sync in foreground: fetches timetable + grades, writes cache, sends sync_data to watch.
  static Future<void> runWearSyncInForeground(KretaClient client) async {
    if (!Platform.isAndroid) return;
    final payload = await buildWearSyncPayload(client);
    if (payload == null) return;
    final path = await getWearSyncCachePath();
    await writeWearSyncCache(path, payload);
    await sendMessageToWatch(<String, dynamic>{'id': 'sync_data', ...payload});
  }

  /// Stream of messages from the Wear OS watch. Empty when not on Android.
  static Stream<Map<String, dynamic>> get watchMessageStream {
    if (!Platform.isAndroid) return const Stream.empty();
    return _watchConnectivityInstance.messageStream.map((m) {
      final map = Map<String, dynamic>.from(m);
      final data = map['data'];
      if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return map;
    });
  }
}
