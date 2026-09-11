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
import 'package:firka/services/notification_delivery_service.dart';
import 'package:firka/data/widget.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/core/settings/settings_effects.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/core/settings/title_font.dart';
import 'package:firka/l10n/app_localizations_de.dart';
import 'package:firka/l10n/app_localizations_en.dart';
import 'package:firka/l10n/app_localizations_hu.dart';
import 'package:firka/core/swear_generator.dart';
import 'package:firka/ui/phone/screens/themes/builtin_theme_id.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka_common/ui/theme/core_theme.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:isar_community/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initLang(AppInitialization data) async {
  switch (Settings.language.value) {
    case AppLanguage.hu:
      data.l10n = AppLocalizationsHu();
      break;
    case AppLanguage.en:
      data.l10n = AppLocalizationsEn();
      break;
    case AppLanguage.de:
      data.l10n = AppLocalizationsDe();
      break;
    case AppLanguage.auto:
      switch (ui.PlatformDispatcher.instance.locale.languageCode) {
        case 'hu':
          data.l10n = AppLocalizationsHu();
          break;
        case 'en':
          data.l10n = AppLocalizationsEn();
          break;
        case 'de':
          data.l10n = AppLocalizationsDe();
          break;
      }
      break;
  }
}

/// Builds a full style for an explicit brightness, applying all custom color
/// overrides — independent of the device's/app's actual current brightness.
/// Used by [initTheme] itself, and by screens (like the theme editor) that
/// need to preview a brightness other than the one currently on screen.
FirkaStyle buildStyleForBrightness(
  bool isLight, {
  bool? isCustomTheme,
  bool forceCustomColors = false,
}) {
  final titleFont = Settings.titleFont.value;
  final titleWeight = Settings.titleWeight.value;
  final fonts = buildAppFonts(
    headingFamily: titleFont.fontFamily,
    headingWeight: titleWeight,
    supportsWeight: titleFont.supportsWeight,
  );
  final coreId = Settings.selectedCoreThemeId.value;
  final gradeId = Settings.selectedGradeThemeId.value;

  final style = styleFor(
    coreId: coreId,
    gradeId: gradeId,
    isLight: isLight,
    fonts: fonts,
  );
  _applyCustomColors(
    style,
    isCustomTheme: isCustomTheme,
    force: forceCustomColors,
  );
  return style;
}

void initTheme(AppInitialization data) {
  final themeCubit = data.themeCubit;

  final brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;

  appHeadingTextCase = switch (Settings.titleCapitalization.value) {
    TitleCapitalization.lower => HeadingTextCase.lower,
    TitleCapitalization.upper => HeadingTextCase.upper,
    TitleCapitalization.normal => HeadingTextCase.normal,
  };

  final isLight = switch (Settings.themeBrightness.value) {
    ThemeBrightness.light => true,
    ThemeBrightness.dark => false,
    ThemeBrightness.auto => brightness != Brightness.dark,
  };
  themeCubit.setLightMode(isLight);
  appStyle = buildStyleForBrightness(isLight);
}

void _applyCustomColors(
  FirkaStyle style, {
  bool? isCustomTheme,
  bool force = false,
}) {
  final colors = style.colors;

  colors.grade5 = Settings.customGradeColor5.value.toColorFromHexSetting();
  colors.grade4 = Settings.customGradeColor4.value.toColorFromHexSetting();
  colors.grade3 = Settings.customGradeColor3.value.toColorFromHexSetting();
  colors.grade2 = Settings.customGradeColor2.value.toColorFromHexSetting();
  colors.grade1 = Settings.customGradeColor1.value.toColorFromHexSetting();

  final customActive =
      isCustomTheme ?? !isBuiltinThemeId(Settings.selectedThemeId.value);
  if (!force && !customActive) {
    return;
  }

  final isLight = style.isLight;

  colors.accent =
      (isLight
              ? Settings.customAccentColorLight
              : Settings.customAccentColorDark)
          .value
          .toColorFromHexSetting();
  colors.a10p = colors.accent.withAlpha(0x1a);
  colors.a15p = colors.accent.withAlpha(0x26);

  final bgGrad = (isLight
          ? Settings.customBackgroundGradientLight
          : Settings.customBackgroundGradientDark)
      .value
      .toColorListFromHexSetting();

  if (bgGrad.isNotEmpty) {
    colors.backgroundGradient = bgGrad;
    colors.background = bgGrad.first;
  } else {
    colors.background =
        (isLight
                ? Settings.customBackgroundColorLight
                : Settings.customBackgroundColorDark)
            .value
            .toColorFromHexSetting();
    colors.backgroundGradient = null;
  }
  colors.background0p = colors.background.withAlpha(0);

  colors.card =
      (isLight
              ? Settings.customCardColorLight
              : Settings.customCardColorDark)
          .value
          .toColorFromHexSetting();
  colors.cardTranslucent = colors.card.withAlpha(0x80);

  colors.buttonSecondaryFill =
      (isLight
              ? Settings.customButtonColorLight
              : Settings.customButtonColorDark)
          .value
          .toColorFromHexSetting();

  colors.secondary =
      (isLight
              ? Settings.customSecondaryColorLight
              : Settings.customSecondaryColorDark)
          .value
          .toColorFromHexSetting();
  colors.buttonDisabledIcon = colors.secondary.withAlpha(0x80);

  final customTextLight = Settings.customTextColorLight.value;
  final customTextDark = Settings.customTextColorDark.value;
  final isCustomTextLight =
      customTextLight != SettingsRegistry.customTextColorLight.defaultValue;
  final isCustomTextDark =
      customTextDark != SettingsRegistry.customTextColorDark.defaultValue;

  final textLight = customTextLight.toColorFromHexSetting();
  final textDark = customTextDark.toColorFromHexSetting();
  colors.textPrimary = isLight ? textLight : textDark;

  final customSecLight = Settings.customTextSecondaryColorLight.value;
  final customSecDark = Settings.customTextSecondaryColorDark.value;
  final isCustomSecLight = customSecLight !=
      SettingsRegistry.customTextSecondaryColorLight.defaultValue;
  final isCustomSecDark = customSecDark !=
      SettingsRegistry.customTextSecondaryColorDark.defaultValue;

  colors.textSecondary = isLight
      ? (isCustomSecLight
          ? customSecLight.toColorFromHexSetting()
          : (isCustomTextLight
              ? textLight.withAlpha(0xCC)
              : customSecLight.toColorFromHexSetting()))
      : (isCustomSecDark
          ? customSecDark.toColorFromHexSetting()
          : (isCustomTextDark
              ? textDark.withAlpha(0xB3)
              : customSecDark.toColorFromHexSetting()));

  final customTertLight = Settings.customTextTertiaryColorLight.value;
  final customTertDark = Settings.customTextTertiaryColorDark.value;
  final isCustomTertLight = customTertLight !=
      SettingsRegistry.customTextTertiaryColorLight.defaultValue;
  final isCustomTertDark = customTertDark !=
      SettingsRegistry.customTextTertiaryColorDark.defaultValue;

  colors.textTertiary = isLight
      ? (isCustomTertLight
          ? customTertLight.toColorFromHexSetting()
          : (isCustomTextLight
              ? textLight.withAlpha(0x80)
              : customTertLight.toColorFromHexSetting()))
      : (isCustomTertDark
          ? customTertDark.toColorFromHexSetting()
          : (isCustomTextDark
              ? textDark.withAlpha(0x80)
              : customTertDark.toColorFromHexSetting()));
  colors.textTeritary = colors.textTertiary;

  colors.textPrimaryLight = textLight;
  colors.textSecondaryLight = isCustomSecLight
      ? customSecLight.toColorFromHexSetting()
      : (isCustomTextLight
          ? textLight.withAlpha(0xCC)
          : customSecLight.toColorFromHexSetting());
  colors.textTertiaryLight = isCustomTertLight
      ? customTertLight.toColorFromHexSetting()
      : (isCustomTextLight
          ? textLight.withAlpha(0x80)
          : customTertLight.toColorFromHexSetting());

  colors.shadowColor =
      (isLight
              ? Settings.customShadowColorLight
              : Settings.customShadowColorDark)
          .value
          .toColorFromHexSetting();

  colors.success =
      (isLight
              ? Settings.customSuccessColorLight
              : Settings.customSuccessColorDark)
          .value
          .toColorFromHexSetting();

  colors.warningAccent =
      (isLight
              ? Settings.customWarningAccentColorLight
              : Settings.customWarningAccentColorDark)
          .value
          .toColorFromHexSetting();
  colors.warning15p = colors.warningAccent.withAlpha(0x26);

  colors.warningText =
      (isLight
              ? Settings.customWarningTextColorLight
              : Settings.customWarningTextColorDark)
          .value
          .toColorFromHexSetting();

  colors.warningCard =
      (isLight
              ? Settings.customWarningCardColorLight
              : Settings.customWarningCardColorDark)
          .value
          .toColorFromHexSetting();

  colors.errorAccent =
      (isLight
              ? Settings.customErrorAccentColorLight
              : Settings.customErrorAccentColorDark)
          .value
          .toColorFromHexSetting();
  colors.error15p = colors.errorAccent.withAlpha(0x26);

  colors.errorText =
      (isLight
              ? Settings.customErrorTextColorLight
              : Settings.customErrorTextColorDark)
          .value
          .toColorFromHexSetting();

  colors.errorCard =
      (isLight
              ? Settings.customErrorCardColorLight
              : Settings.customErrorCardColorDark)
          .value
          .toColorFromHexSetting();
}

Future<void> _initData(AppInitialization init) async {
  await init.settings.loadAll();
  final selectedThemeId = Settings.selectedThemeId.value;
  final normalized = normalizeSelectedThemeId(selectedThemeId);
  if (normalized != selectedThemeId) {
    await Settings.selectedThemeId.set(normalized);
  }
  await initLang(init);
  await regenerateM3eTheme();
  initTheme(init);

  var dispatcher = SchedulerBinding.instance.platformDispatcher;

  dispatcher.onPlatformBrightnessChanged = () async {
    await regenerateM3eTheme();
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

  final token = init.settings.getSelectedToken();
  if (token == null) {
    logger.warning("[Init] No token available!");
    init.client = null;
    return;
  }
  logger.fine("Initializing kréta client as: ${token.username}");
  init.client = KretaClient(token);

  // A resumed session (app reopened with an already-logged-in account)
  // never goes through login_finish.dart's onUserLogin call, so without
  // this the FCM token would only ever get (re-)registered for a user who
  // explicitly logs out and back in. Safe to call on every startup:
  // onUserLogin() itself no-ops if notifyAll is off or permission is denied.
  unawaited(NotificationDeliveryService.onUserLogin(client: init.client!));

  // Immediately refresh widget state from cached Isar lessons so widget is up to date
  unawaited(WidgetCacheHelper.updateWidgetCacheFromIsar());

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
    await WidgetCacheHelper.updateWidgetCacheFromIsar();
    init.homeRefreshCubit.requestRefresh();
  }());

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
  await Settings.loadAll();
  registerSettingsEffects(initData.settings, initData);

  try {
    await NotificationDeliveryService.initialize().timeout(
      const Duration(seconds: 8),
    );
  } on TimeoutException catch (e, st) {
    logger.warning('NotificationDeliveryService init timed out: $e', e, st);
  } catch (e, st) {
    logger.severe(
      'Failed to initialize NotificationDeliveryService: $e',
      e,
      st,
    );
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
