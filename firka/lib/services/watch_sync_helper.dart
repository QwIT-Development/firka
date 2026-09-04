import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/services/wear_sync_cache.dart';
import 'package:firka/api/client/kreta_client.dart';

/// Helper class for Wear OS sync (Android).
class WatchSyncHelper {
  static const _wearSyncChannel = MethodChannel('app.firka/wear_sync');
  static WatchConnectivity? _androidWatchConnectivity;
  static WatchConnectivity get _watchConnectivityAndroid {
    _androidWatchConnectivity ??= WatchConnectivity();
    return _androidWatchConnectivity!;
  }

  /// Callback for Watch pairing message events (Android Wear OS pairing flow).
  /// Set by initialization_screen.dart to handle "ping" messages for Watch pairing.
  static void Function(Map<String, dynamic> message)? onWatchMessage;

  /// Send a fire-and-forget message to Watch via watch_connectivity (Android).
  /// The payload is sent as a JSON string for reliable transport.
  static Future<void> sendMessageToWatch(Map<String, dynamic> message) async {
    if (!Platform.isAndroid) return;
    await _watchConnectivityAndroid.sendMessage(<String, dynamic>{
      'data': jsonEncode(message),
    });
  }

  /// Starts the Wear sync foreground service (Android only). Call after writing initial cache.
  /// [appDirPath] is the application documents directory path (for the background isolate).
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
  /// Use when enabling Wear OS support or on app launch when support is already enabled.
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
  /// Used when app is in foreground and watch sends request_sync (Android) or equivalent.
  static Future<void> runWearSyncInForeground(KretaClient client) async {
    final payload = await buildWearSyncPayload(client);
    if (payload == null) return;
    final path = await getWearSyncCachePath();
    await writeWearSyncCache(path, payload);
    await sendMessageToWatch(<String, dynamic>{'id': 'sync_data', ...payload});
  }

  /// Stream of messages from the watch (Android: watch_connectivity). Use for request_sync etc.
  static Stream<Map<String, dynamic>> get watchMessageStream {
    if (!Platform.isAndroid) return const Stream.empty();
    return _watchConnectivityAndroid.messageStream.map((m) {
      final map = Map<String, dynamic>.from(m);
      final data = map['data'];
      if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return map;
    });
  }
}
