import "dart:io";

import "package:permission_handler/permission_handler.dart";

import "package:firka/app/app_state.dart";
import "package:firka/app/initialization.dart";
import "package:firka/services/live_activity_service.dart";
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

  repo.onChange(SettingsRegistry.morningNotificationEnabled, (enabled) async {
    LiveActivityService.onMorningNotificationEnabledChanged(enabled);
  });

  repo.onChange(SettingsRegistry.liveActivityEnabled, (enabled) async {
    await LiveActivityService.handleEnabledChange(enabled, isManual: true);
    await LiveActivityService.syncGlobalSettingWithCurrentUser();
  });

  // These two mirror LiveActivity widgets on iOS only, matching the original
  // postUpdate wiring that was only attached inside an `if (Platform.isIOS)` block.
  if (Platform.isIOS) {
    repo.onChange(SettingsRegistry.bellDelay, (value) async {
      LiveActivityService.onBellDelayChanged(value);
    });

    repo.onChange(SettingsRegistry.morningNotificationTime, (value) async {
      LiveActivityService.onMorningNotificationTimeChanged(value);
    });
  }
}
