import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/data/models/token_model.dart';
import 'package:firka/core/state/update_notifier.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:isar_community/isar.dart';
import 'dart:io';

late final Logger logger;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late AppInitialization initData;
bool initDone = false;

final dio = Dio();
final isBeta = true;

final ValueNotifier<bool> isLightMode = ValueNotifier<bool>(true);
final UpdateNotifier globalUpdate = UpdateNotifier();

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

class AppInitialization {
  final Isar isar;
  final Directory appDir;
  final PackageInfo packageInfo;
  final DeviceInfo devInfo;
  late KretaClient client;
  List<TokenModel> tokens;
  bool hasWatchListener = false;
  Uint8List? profilePicture;
  SettingsStore settings;
  UpdateNotifier settingsUpdateNotifier = UpdateNotifier();
  UpdateNotifier profilePictureUpdateNotifier = UpdateNotifier();
  AppLocalizations l10n;
  final GlobalKey<NavigatorState> navigatorKey;

  AppInitialization({
    required this.isar,
    required this.appDir,
    required this.devInfo,
    required this.packageInfo,
    required this.tokens,
    required this.settings,
    required this.l10n,
    required this.navigatorKey,
  });
}
