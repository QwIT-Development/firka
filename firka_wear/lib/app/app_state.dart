import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:logging/logging.dart';

import 'package:firka_wear/l10n/app_localizations.dart';
import 'package:firka_wear/services/wear_sync_store.dart';

late final Logger logger;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late WearAppInitialization initData;
bool initDone = false;

final dio = Dio();

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
