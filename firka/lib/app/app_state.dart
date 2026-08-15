import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firka_common/core/consts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/bloc/profile_picture_cubit.dart';
import 'package:firka/core/bloc/toast_cubit.dart';
import 'package:firka/core/bloc/settings_cubit.dart';
import 'package:firka/core/bloc/theme_cubit.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:isar_community/isar.dart';
import 'dart:io';

late final Logger logger;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late AppInitialization initData;
bool initDone = false;

/// Set when app router is created; used for deep links and notifications.
GoRouter? appRouter;

final dio = Dio();
final isBeta = true;

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
  KretaClient? client;
  bool hasWatchListener = false;

  /// Set by the wear pairing modal; called when watch sends init_done or sync_done to dismiss the sheet.
  void Function()? dismissWearPairingSheet;
  Uint8List? profilePicture;
  SettingsRepository settings;
  final ThemeCubit themeCubit = ThemeCubit();
  final SettingsCubit settingsCubit = SettingsCubit();
  final ProfilePictureCubit profilePictureCubit = ProfilePictureCubit();
  final ToastCubit toastCubit = ToastCubit();
  final HomeRefreshCubit homeRefreshCubit = HomeRefreshCubit();
  AppLocalizations l10n;
  String userAgent;
  final GlobalKey<NavigatorState> navigatorKey;

  AppInitialization({
    required this.isar,
    required this.appDir,
    required this.devInfo,
    required this.packageInfo,
    required this.settings,
    required this.l10n,
    required this.navigatorKey,
  }) : userAgent = Platform.isAndroid
           ? "${Constants.applicationId}/${Constants.applicationVersion}"
                 "/${devInfo.model}"
                 "/${devInfo.versionRelease}"
                 "/${devInfo.versionSdkInt}"
           : "eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0";
}
