import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:isar_community/isar.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/core/bloc/reauth_cubit.dart';
import 'package:firka/data/models/app_settings_model.dart';
import 'package:firka/data/models/generic_cache_model.dart';
import 'package:firka/data/models/homework_cache_model.dart';
import 'package:firka/data/models/timetable_cache_model.dart';
import 'package:firka/data/models/token_model.dart';
import 'package:firka/services/wear_sync_cache.dart';

/// Background isolate entrypoint for Wear sync (Android).
/// Native invokes with MethodCall 'request_sync' and arguments: {cachePath, appDirPath}.
@pragma('vm:entry-point')
void wearSyncBackgroundEntrypoint() {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.firka/wear_sync_background');
  channel.setMethodCallHandler((MethodCall call) async {
    if (call.method != 'request_sync') return null;
    if (!Platform.isAndroid) return null;
    final args = call.arguments as Map<dynamic, dynamic>?;
    final cachePath = args?['cachePath'] as String?;
    final appDirPath = args?['appDirPath'] as String?;
    if (cachePath == null || appDirPath == null) return null;
    try {
      final isar = await Isar.open([
        TokenModelSchema,
        GenericCacheModelSchema,
        TimetableCacheModelSchema,
        HomeworkCacheModelSchema,
        AppSettingsModelSchema,
        HomeworkDoneModelSchema,
      ], directory: appDirPath);
      final tokens = await isar.tokenModels.where().findAll();
      await isar.close();
      if (tokens.isEmpty) return null;
      final token = tokens.first;
      final isar2 = await Isar.open([
        TokenModelSchema,
        GenericCacheModelSchema,
        TimetableCacheModelSchema,
        HomeworkCacheModelSchema,
        AppSettingsModelSchema,
        HomeworkDoneModelSchema,
      ], directory: appDirPath);
      final reauthCubit = ReauthCubit();
      final client = KretaClient(token, isar2, reauthCubit);
      final payload = await buildWearSyncPayload(client);
      await isar2.close();
      if (payload == null) return null;
      await writeWearSyncCache(cachePath, payload);
      final wc = WatchConnectivity();
      await wc.sendMessage(<String, dynamic>{
        'data': jsonEncode(<String, dynamic>{'id': 'sync_data', ...payload}),
      });
      return true;
    } catch (e, st) {
      debugPrint('[WearSyncBackground] Error: $e $st');
      return null;
    }
  });
}
