import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/l10n/app_localizations_hu.dart';
import 'package:firka_common/data/database.dart';

/// Minimal, isolate-local stand-in for `initializeApp()` (see
/// `lib/app/initialization.dart`), used only by the FCM background message
/// isolate. That isolate has none of the running app's in-memory state (it's
/// a fresh Dart isolate, possibly a fresh process) — but `KretaClient` reads
/// the global `initData` (for `userAgent`/`toastCubit`) unconditionally, so
/// something has to populate it before a background wakeup can fetch data.
///
/// Deliberately skips everything UI/theming/watch-sync/live-activity
/// related: those either don't apply headlessly or actively assume a
/// running app (native platform channels registered on the main
/// FlutterEngine, iCloud sync, etc). Idempotent per isolate — a warm
/// background isolate handling multiple wakeups only bootstraps once.
Future<void> bootstrapHeadless() async {
  if (initDone) return;

  final isar = await initDB();
  final settings = SettingsRepository(isar);
  await settings.loadAll();

  initData = AppInitialization(
    isar: isar,
    appDir: await getApplicationDocumentsDirectory(),
    // Real device info requires a MethodChannel handler that's only
    // registered on the main FlutterEngine; a placeholder is fine here,
    // it only affects the User-Agent header string.
    devInfo: DeviceInfo('background', '0', '0'),
    packageInfo: await PackageInfo.fromPlatform(),
    settings: settings,
    l10n: AppLocalizationsHu(),
    navigatorKey: GlobalKey<NavigatorState>(),
  );
  Settings = settings;
  initDone = true;
}
