import "dart:io";

import "package:permission_handler/permission_handler.dart";

import "package:firka/app/app_state.dart";
import "package:firka/app/initialization.dart";
import "package:firka/services/fcm_service.dart";
import "package:firka/services/notification_delivery_service.dart";
import "package:firka/services/watch_sync_helper.dart";
import "package:firka/ui/phone/screens/themes/builtin_theme_id.dart";

import "settings_repository.dart";
import "settings_schema.dart";

/// Registers the side effects that used to live as `postUpdate` closures on
/// each SettingsItem. Called once after the repository is loaded at startup.
void registerSettingsEffects(
  SettingsRepository repo,
  AppInitialization initData,
) {
  repo.onChange(SettingsRegistry.language, (_) async {
    await initLang(initData);
    initData.homeRefreshCubit.requestRefresh();
  });

  repo.onChange(SettingsRegistry.themeBrightness, (_) async {
    initTheme(initData);
    initData.themeCubit.refresh();
    initData.homeRefreshCubit.requestRefresh();
  });

  Future<void> refreshTitleStyle(_) async {
    initTheme(initData);
    initData.themeCubit.refresh();
    initData.homeRefreshCubit.requestRefresh();
  }

  repo.onChange(SettingsRegistry.titleFont, refreshTitleStyle);
  repo.onChange(SettingsRegistry.titleWeight, refreshTitleStyle);
  repo.onChange(SettingsRegistry.titleCapitalization, refreshTitleStyle);

  Future<void> refreshPresetTheme(_) async {
    if (isBuiltinThemeId(Settings.selectedThemeId.value)) {
      final next = composeBuiltinThemeId(
        Settings.selectedCoreThemeId.value,
        Settings.selectedGradeThemeId.value,
      );
      if (next != Settings.selectedThemeId.value) {
        await Settings.selectedThemeId.setSilently(next);
      }
    }
    initTheme(initData);
    initData.themeCubit.refresh();
    initData.homeRefreshCubit.requestRefresh();
  }

  repo.onChange(SettingsRegistry.selectedCoreThemeId, refreshPresetTheme);
  repo.onChange(SettingsRegistry.selectedGradeThemeId, refreshPresetTheme);
  repo.onChange(SettingsRegistry.selectedThemeId, refreshPresetTheme);

  Future<void> refreshCustomColors(_) async {
    initTheme(initData);
    initData.themeCubit.refresh();
    initData.homeRefreshCubit.requestRefresh();
  }

  for (final setting in [
    SettingsRegistry.customGradeColor5,
    SettingsRegistry.customGradeColor4,
    SettingsRegistry.customGradeColor3,
    SettingsRegistry.customGradeColor2,
    SettingsRegistry.customGradeColor1,
    SettingsRegistry.customAccentColorLight,
    SettingsRegistry.customAccentColorDark,
    SettingsRegistry.customBackgroundColorLight,
    SettingsRegistry.customBackgroundColorDark,
    SettingsRegistry.customCardColorLight,
    SettingsRegistry.customCardColorDark,
    SettingsRegistry.customButtonColorLight,
    SettingsRegistry.customButtonColorDark,
    SettingsRegistry.customSecondaryColorLight,
    SettingsRegistry.customSecondaryColorDark,
    SettingsRegistry.customTextColorLight,
    SettingsRegistry.customTextColorDark,
    SettingsRegistry.customTextSecondaryColorLight,
    SettingsRegistry.customTextSecondaryColorDark,
    SettingsRegistry.customTextTertiaryColorLight,
    SettingsRegistry.customTextTertiaryColorDark,
    SettingsRegistry.customShadowColorLight,
    SettingsRegistry.customShadowColorDark,
    SettingsRegistry.customSuccessColorLight,
    SettingsRegistry.customSuccessColorDark,
    SettingsRegistry.customWarningAccentColorLight,
    SettingsRegistry.customWarningAccentColorDark,
    SettingsRegistry.customWarningTextColorLight,
    SettingsRegistry.customWarningTextColorDark,
    SettingsRegistry.customWarningCardColorLight,
    SettingsRegistry.customWarningCardColorDark,
    SettingsRegistry.customErrorAccentColorLight,
    SettingsRegistry.customErrorAccentColorDark,
    SettingsRegistry.customErrorTextColorLight,
    SettingsRegistry.customErrorTextColorDark,
    SettingsRegistry.customErrorCardColorLight,
    SettingsRegistry.customErrorCardColorDark,
    SettingsRegistry.customBackgroundGradientLight,
    SettingsRegistry.customBackgroundGradientDark,
  ]) {
    repo.onChange(setting, refreshCustomColors);
  }

  repo.onChange(SettingsRegistry.wearOsSupport, (enabled) async {
    if (!Platform.isAndroid) return;
    if (enabled && initDone) {
      final notifStatus = await Permission.notification.status;
      if (notifStatus.isDenied || notifStatus.isPermanentlyDenied) {
        await Permission.notification.request();
      }
      await WatchSyncHelper.startWearSyncServiceWithFreshCache(
        initData.client!,
        initData.appDir.path,
      );
    } else {
      await WatchSyncHelper.stopWearSyncService();
    }
  });

  repo.onChange(SettingsRegistry.notifyAll, (_) async {
    await NotificationDeliveryService.syncDeliveryBackend();
  });

  repo.onChange(SettingsRegistry.notificationDeliveryMethod, (_) async {
    await NotificationDeliveryService.syncDeliveryBackend();
  });

  repo.onChange(SettingsRegistry.notifyWakeupInterval, (_) async {
    await NotificationDeliveryService.handleWakeupIntervalChange();
  });

  for (final setting in [
    SettingsRegistry.notifyGrades,
    SettingsRegistry.notifyHomeworkTests,
    SettingsRegistry.notifyAbsences,
    SettingsRegistry.notifyLessons,
    SettingsRegistry.notifyMessages,
  ]) {
    repo.onChange(setting, (_) async {
      await FcmService.updatePreferences();
    });
  }
}
