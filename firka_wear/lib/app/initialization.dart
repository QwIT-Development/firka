import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:firka_wear/data/models/generic_cache_model.dart';
import 'package:firka_wear/data/models/homework_cache_model.dart';
import 'package:firka_wear/data/models/timetable_cache_model.dart';
import 'package:firka_wear/data/models/token_model.dart';
import 'package:firka_wear/l10n/app_localizations.dart';
import 'package:firka_wear/l10n/app_localizations_de.dart';
import 'package:firka_wear/l10n/app_localizations_en.dart';
import 'package:firka_wear/l10n/app_localizations_hu.dart';
import 'package:flutter/material.dart';

import 'package:firka_wear/services/wear_sync_store.dart';

Isar? isarInit;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DeviceInfo {
  String model;
  String versionRelease;
  String versionSdkInt;

  DeviceInfo(this.model, this.versionRelease, this.versionSdkInt);

  @override
  String toString() {
    return "DeviceInfo(model = \"$model\", versionRelease = \"$versionRelease\""
        ", versionSdkInt = \"$versionSdkInt\"";
  }
}

class WearAppInitialization {
  final Isar isar;
  final WearSyncStore syncStore;
  final int tokenCount;
  final AppLocalizations l10n;
  final DeviceInfo devInfo;

  WearAppInitialization({
    required this.isar,
    required this.syncStore,
    required this.tokenCount,
    required this.l10n,
    required this.devInfo,
  });
}

Future<Isar> initDB() async {
  if (isarInit != null) return isarInit!;
  final dir = await getApplicationDocumentsDirectory();

  isarInit = await Isar.open(
    [
      TokenModelSchema,
      GenericCacheModelSchema,
      TimetableCacheModelSchema,
      HomeworkCacheModelSchema,
    ],
    inspector: true,
    directory: dir.path,
  );

  return isarInit!;
}

AppLocalizations getLang() {
  switch (ui.PlatformDispatcher.instance.locale.languageCode) {
    case 'hu':
      return AppLocalizationsHu();
    case 'de':
      return AppLocalizationsDe();
    default:
      return AppLocalizationsEn();
  }
}

Future<WearAppInitialization> initializeApp() async {
  final isar = await initDB();
  final syncStore = WearSyncStore();
  await syncStore.load();

  const channel = MethodChannel("firka.app/main");
  final rawInfo = ((await channel.invokeMethod("get_info")) as String).split(
    ";",
  );

  return WearAppInitialization(
    isar: isar,
    syncStore: syncStore,
    tokenCount: await isar.tokenModels.count(),
    l10n: getLang(),
    devInfo: DeviceInfo(rawInfo[0], rawInfo[1], rawInfo[2]),
  );
}
