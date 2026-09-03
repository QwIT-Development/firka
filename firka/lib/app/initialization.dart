import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firka_common/data/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/api/client/kreta_client.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:firka/services/fcm_service.dart';
import 'package:firka/services/live_activity_service.dart';
import 'package:firka/core/settings/settings_effects.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/core/settings/title_font.dart';
import 'package:firka/services/watch_sync_helper.dart';
import 'package:firka/l10n/app_localizations_de.dart';
import 'package:firka/l10n/app_localizations_en.dart';
import 'package:firka/l10n/app_localizations_hu.dart';
import 'package:firka/core/swear_generator.dart';
import 'package:firka/ui/phone/screens/themes/builtin_theme_id.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:isar_community/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initLang(AppInitialization data) async {
  String? languageCode;

  switch (Settings.language.value) {
    case AppLanguage.hu:
      data.l10n = AppLocalizationsHu();
      languageCode = 'hu';
      break;
    case AppLanguage.en:
      data.l10n = AppLocalizationsEn();
      languageCode = 'en';
      break;
    case AppLanguage.de:
      data.l10n = AppLocalizationsDe();
      languageCode = 'de';
      break;
    case AppLanguage.auto:
      switch (ui.PlatformDispatcher.instance.locale.languageCode) {
        case 'hu':
          data.l10n = AppLocalizationsHu();
          languageCode = 'hu';
          break;
        case 'en':
          data.l10n = AppLocalizationsEn();
          languageCode = 'en';
          break;
        case 'de':
          data.l10n = AppLocalizationsDe();
          languageCode = 'de';
          break;
      }
      break;
  }

  if (languageCode != null && Platform.isIOS) {
    try {
      await LiveActivityService.updateLanguagePreference(languageCode);
    } catch (e) {
      logger.warning('Failed to update language preference on backend: $e');
    }

    try {
      await WatchSyncHelper.sendLanguageToWatch();
    } catch (e) {
      logger.warning('Failed to send language to Watch: $e');
    }
  }
}

void initTheme(AppInitialization data) {
  final themeCubit = data.themeCubit;

  final brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;

  final titleFont = Settings.titleFont.value;
  final titleWeight = Settings.titleWeight.value;
  final fonts = buildAppFonts(
    headingFamily: titleFont.fontFamily,
    headingWeight: titleWeight,
    supportsWeight: titleFont.supportsWeight,
  );

  appHeadingTextCase = switch (Settings.titleCapitalization.value) {
    TitleCapitalization.lower => HeadingTextCase.lower,
    TitleCapitalization.upper => HeadingTextCase.upper,
    TitleCapitalization.normal => HeadingTextCase.normal,
  };

  FirkaStyle baseStyle;
  final coreId = Settings.selectedCoreThemeId.value;
  final gradeId = Settings.selectedGradeThemeId.value;
  switch (Settings.themeBrightness.value) {
    case ThemeBrightness.light:
      baseStyle = styleFor(
        coreId: coreId,
        gradeId: gradeId,
        isLight: true,
        fonts: fonts,
      );
      themeCubit.setLightMode(true);
      break;
    case ThemeBrightness.dark:
      baseStyle = styleFor(
        coreId: coreId,
        gradeId: gradeId,
        isLight: false,
        fonts: fonts,
      );
      themeCubit.setLightMode(false);
      break;
    case ThemeBrightness.auto:
      if (brightness == Brightness.dark) {
        baseStyle = styleFor(
          coreId: coreId,
          gradeId: gradeId,
          isLight: false,
          fonts: fonts,
        );
        themeCubit.setLightMode(false);
      } else {
        baseStyle = styleFor(
          coreId: coreId,
          gradeId: gradeId,
          isLight: true,
          fonts: fonts,
        );
        themeCubit.setLightMode(true);
      }
  }

  appStyle = baseStyle;
}
Future<void> _initData(AppInitialization init) async {
  await init.settings.loadAll();
  final selectedThemeId = Settings.selectedThemeId.value;
  final normalized = normalizeSelectedThemeId(selectedThemeId);
  if (normalized != selectedThemeId) {
    await Settings.selectedThemeId.set(normalized);
  }
  await initLang(init);
  initTheme(init);

  var dispatcher = SchedulerBinding.instance.platformDispatcher;

  dispatcher.onPlatformBrightnessChanged = () {
    initTheme(init);
  };

  dispatcher.onLocaleChanged = () {
    final isAutoLanguage = Settings.language.value == AppLanguage.auto;
    if (!isAutoLanguage) {
      return;
    }

    final previousLocale = init.l10n.localeName;
    unawaited(() async {
      await initLang(init);
      final nextLocale = init.l10n.localeName;
      if (previousLocale != nextLocale) {
        logger.info(
          "[Init] System locale changed in auto mode: $previousLocale -> $nextLocale",
        );
      }
      init.themeCubit.refresh();
    }());
  };

  var didRunFreshInstallCleanup = false;
  if (Platform.isIOS) {
    try {
      didRunFreshInstallCleanup =
          await WatchSyncHelper.runFreshInstallCleanupIfNeeded(isar: init.isar);
      if (didRunFreshInstallCleanup) {
        logger.info(
          '[Init] Fresh-install cleanup completed; skipping startup iCloud recovery on this launch',
        );
      } else {
        await WatchSyncHelper.checkAndRecoverFromiCloud(isar: init.isar);
      }
    } catch (e) {
      logger.warning('[Init] iCloud bootstrap/recovery failed: $e');
    }
  }

  final token = init.settings.getSelectedToken();
  if (token == null) {
    logger.warning("[Init] No token available!");
    init.client = null;
    return;
  }
  logger.fine("Initializing kréta client as: ${token.username}");
  init.client = KretaClient(token);

  // Don't block first paint on the network: render whatever is already
  // cached, then stream in student/timetable/grades/etc. as they arrive.
  unawaited(() async {
    try {
      await init.client!.init();
    } catch (e) {
      logger.warning("[Init] Failed to initialize KretaClient: $e");
      if (!isTokenExpired(e)) {
        init.toastCubit.setActiveToast(.error, e);
      }
    }
    init.homeRefreshCubit.requestRefresh();

    await init.client!.renewCache(reInit: false);
    init.homeRefreshCubit.requestRefresh();
  }());

  if (Platform.isIOS) {
    final expiryDate = token.expiryDate;
    if (expiryDate.isAfter(DateTime.now())) {
      init.toastCubit.clear();
    }

    unawaited(() async {
      try {
        await WatchSyncHelper.saveTokenToiCloud(token);
      } catch (e) {
        logger.warning('[Init] Failed to sync active token to iCloud: $e');
      }

      try {
        await WatchSyncHelper.sendTokenModelToWatch(token);
      } catch (e) {
        logger.warning('[Init] Failed to sync active token to Watch: $e');
      }
    }());
  }

  final dataDir = await getApplicationDocumentsDirectory();
  var pfpFile = File(p.join(dataDir.path, "profile.webp"));

  if (await pfpFile.exists()) {
    init.profilePicture = await pfpFile.readAsBytes();
  }

  init.homeRefreshCubit.requestRefresh();
}

Future<void> initializeApp() async {
  if (initDone) {
    await _initData(initData);
    return;
  }
  final isar = await initDB();
  final tokens = await isar.tokenModels.where().findAll();

  logger.finest('Token count: ${tokens.length}');

  var devInfoFetched = false;
  var devInfo = DeviceInfo("SM-A705FN", "11", "30");

  try {
    if (Platform.isAndroid) {
      const channel = MethodChannel("firka.app/main");
      final rawInfo = ((await channel.invokeMethod("get_info")) as String)
          .split(";");

      devInfo = DeviceInfo(rawInfo[0], rawInfo[1], rawInfo[2]);
      devInfoFetched = true;
    }
  } catch (e) {
    if (e is Error) {
      logger.shout("Error in initializeApp()", e.toString(), e.stackTrace);
    } else {
      logger.shout("Error in initializeApp()", e.toString());
    }
  }

  logger.fine("Fetched device info: ${devInfoFetched ? "yes" : "no"}");
  logger.fine("Using device info: ${devInfo.toString()}");

  initData = AppInitialization(
    isar: isar,
    appDir: await getApplicationDocumentsDirectory(),
    devInfo: devInfo,
    packageInfo: await PackageInfo.fromPlatform(),
    settings: SettingsRepository(isar),
    l10n: AppLocalizationsHu(),
    navigatorKey: navigatorKey,
  );
  initData.settings.cubit = initData.settingsCubit;
  Settings = initData.settings;
  registerSettingsEffects(initData.settings, initData);

  if (Platform.isIOS) {
    try {
      await LiveActivityService.initialize().timeout(
        const Duration(seconds: 8),
      );
    } on TimeoutException catch (e, st) {
      logger.warning('LiveActivity init timed out: $e', e, st);
    } catch (e, st) {
      logger.severe('Failed to initialize LiveActivity: $e', e, st);
    }
  }

  try {
    await FcmService.initialize().timeout(const Duration(seconds: 8));
  } on TimeoutException catch (e, st) {
    logger.warning('FcmService init timed out: $e', e, st);
  } catch (e, st) {
    logger.severe('Failed to initialize FcmService: $e', e, st);
  }

  await _initData(initData);

  initDone = true;
}

Future<void> setupLogging() async {
  final jwtPattern = RegExp(
    r'([A-Za-z0-9-_]+)\.([A-Za-z0-9-_]+)\.([A-Za-z0-9-_]+)',
  );
  final omPattern = RegExp(r'(\d{3})(\d{6})([A-Za-z0-9]?)');
  final refreshTokenPattern = RegExp(
    r'"(?=.{21,}$)([A-Z0-9]+-[A-Z0-9_\-.~+]*)"',
  );

  final docs = await getApplicationDocumentsDirectory();

  Future<void> deleteOldLogFiles() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(docs.path);
    if (!dir.existsSync()) return;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: 30));

    final logFileRegex = RegExp(r'^(\d{4})_(\d{2})_(\d{2})\.log$');

    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final m = logFileRegex.firstMatch(name);
      if (m == null) continue;

      try {
        final y = int.parse(m.group(1)!);
        final mo = int.parse(m.group(2)!);
        final d = int.parse(m.group(3)!);
        final fileDate = DateTime(y, mo, d);
        if (fileDate.isBefore(
          DateTime(cutoff.year, cutoff.month, cutoff.day),
        )) {
          logger.info("Removing old log file: $name");
          await entity.delete();
        }
      } catch (_) {
        // ignore parse/delete errors
      }
    }
  }

  String logFilePathForDate(DateTime dt) {
    final fileName = "${DateFormat("yyyy_MM_dd").format(dt)}.log";
    return Directory(docs.path).uri.resolve(fileName).toFilePath();
  }

  File fileForDate(DateTime dt) {
    final path = logFilePathForDate(dt);
    final file = File(path);
    if (!file.existsSync()) file.createSync(recursive: true);
    return file;
  }

  String censorLog(String msg) {
    return msg
        .replaceAll(jwtPattern, '***')
        .replaceAllMapped(omPattern, (match) {
          return "${match.group(1)}******${match.group(3)}";
        })
        .replaceAll(refreshTokenPattern, '"***"');
  }

  hierarchicalLoggingEnabled = true;
  logger.level = Level.ALL;

  DateTime currentDate = DateTime.now();
  IOSink sink = fileForDate(currentDate).openWrite(mode: FileMode.append);

  logger.onRecord.listen((record) {
    final now = DateTime.now();
    if (now.year != currentDate.year ||
        now.month != currentDate.month ||
        now.day != currentDate.day) {
      sink.flush();
      sink.close();
      currentDate = now;
      sink = fileForDate(currentDate).openWrite(mode: FileMode.append);
    }

    final censored = censorLog(record.message);
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(now);
    final level = record.level.name;
    final line = '[$timestamp] [$level] [$censored]';
    sink.writeln(line);

    debugPrint(
      "[Firka] [${record.level.name}] ${kDebugMode ? record.message : censored}",
    );
  });

  unawaited(deleteOldLogFiles());

  try {
    logger.finest('loading dirty words');
    await loadDirtyWords();
    logger.finest('loaded dirty words');
  } catch (e, st) {
    logger.severe('Failed to load dirty words: $e', e, st);
  }
}
