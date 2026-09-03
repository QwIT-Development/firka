import "dart:io";

import "package:firka/app/app_state.dart";
import "package:firka/app/initialization.dart";
import "package:firka/services/fcm_service.dart";
import "package:firka/services/watch_sync_helper.dart";
import "package:firka_common/data/models/token_model.dart";
import "package:kreta_api/kreta_api.dart";

Future<void> completeLogin(
  AppInitialization data,
  TokenGrantResponse resp,
) async {
  var tokenModel = TokenModel.fromResp(resp);

  await data.isar.writeTxn(() async {
    await data.isar.tokenModels.put(tokenModel);
  });

  await data.settings.setSelectedAccountKey(tokenModel.key);
  await initializeApp();

  if (data.client != null) {
    await FcmService.onUserLogin(
      client: data.client!,
      settingsStore: data.settings,
    );
  }

  if (Platform.isIOS) {
    final watchInstalled = await WatchSyncHelper.isWatchAppInstalled();
    if (watchInstalled) {
      try {
        await WatchSyncHelper.saveTokenToiCloud(tokenModel);
      } catch (_) {}

      try {
        await WatchSyncHelper.sendTokenToWatch();
      } catch (_) {}
    }
  }
}
