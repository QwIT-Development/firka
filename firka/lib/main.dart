import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/db/models/generic_cache_model.dart';
import 'package:firka/helpers/db/models/timetable_cache_model.dart';
import 'package:firka/helpers/db/models/token_model.dart';
import 'package:firka/helpers/db/widget.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/firka_bundle.dart';
import 'package:firka/helpers/settings/setting.dart';
import 'package:firka/l10n/app_localizations_hu.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/pages/error/error_page.dart';
import 'package:firka/ui/phone/screens/debug/debug_screen.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:firka/ui/phone/screens/login/login_screen.dart';
import 'package:firka/ui/phone/screens/wear_login/wear_login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'helpers/db/models/homework_cache_model.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_de.dart';
import 'l10n/app_localizations_en.dart';

Isar? isarInit;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late AppInitialization initData;

final dio = Dio();

class AppInitialization {
  final Isar isar;
  late KretaClient client;
  int tokenCount;
  bool hasWatchListener = false;
  Uint8List? profilePicture;
  SettingsStore settings;
  AppLocalizations l10n;

  AppInitialization({
    required this.isar,
    required this.tokenCount,
    required this.settings,
    required this.l10n,
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
      AppSettingsModelSchema,
    ],
    inspector: true,
    directory: dir.path,
  );

  return isarInit!;
}

Future<AppInitialization> initializeApp() async {
  final isar = await initDB();
  final tokenCount = await isar.tokenModels.count();

  if (kDebugMode) {
    print('Token count: $tokenCount');
  }

  var init = AppInitialization(
    isar: isar,
    tokenCount: tokenCount,
    settings: SettingsStore(),
    l10n: AppLocalizationsHu(),
  );

  await init.settings.load(init.isar.appSettingsModels);
  switch ((init.settings.group("settings").subGroup("application")["language"]
          as SettingsItemsRadio)
      .activeIndex) {
    case 1: // hu
      init.l10n = AppLocalizationsHu();
      break;
    case 2: // en
      init.l10n = AppLocalizationsEn();
      break;
    case 3: // de
      init.l10n = AppLocalizationsDe();
      break;
    default: // auto
      switch (ui.window.locale.languageCode) {
        case 'hu':
          init.l10n = AppLocalizationsHu();
          break;
        case 'en':
          init.l10n = AppLocalizationsEn();
          break;
        case 'de':
          init.l10n = AppLocalizationsDe();
          break;
      }
      break;
  }

  resetOldTimeTableCache(isar);
  resetOldHomeworkCache(isar);

  // TODO: Account selection
  if (tokenCount > 0) {
    init.client =
        KretaClient((await isar.tokenModels.where().findFirst())!, isar);

    await WidgetCacheHelper.updateWidgetCache(appStyle, init.client);
  }

  final dataDir = await getApplicationDocumentsDirectory();
  var pfpFile = File(p.join(dataDir.path, "profile.png"));

  if (await pfpFile.exists()) {
    init.profilePicture = await pfpFile.readAsBytes();
  }

  return init;
}

void main() async {
  dio.options.connectTimeout = Duration(seconds: 5);
  dio.options.receiveTimeout = Duration(seconds: 3);

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Run App Initialization
    runApp(InitializationScreen());
  }, (error, stackTrace) {
    debugPrint('Caught error: $error');
    debugPrint('Stack trace: $stackTrace');

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) =>
            ErrorPage(key: ValueKey('errorPage'), exception: error.toString()),
      ),
    );
  });
}

class InitializationScreen extends StatelessWidget {
  InitializationScreen({super.key});

  final Future<AppInitialization> _init = initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitialization>(
      future: _init,
      builder: (context, snapshot) {
        // Check if initialization is complete
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            debugPrintStack(
                stackTrace: snapshot.stackTrace,
                label: snapshot.error.toString());

            // Handle initialization error
            return MaterialApp(
              key: ValueKey('errorPage'),
              home: DefaultAssetBundle(
                  bundle: FirkaBundle(),
                  child: Scaffold(
                    body: Center(
                      child: Text(
                        'Error initializing app: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  )),
            );
          }

          // Initialization successful, determine which screen to show
          Widget screen;

          assert(snapshot.data != null);
          initData = snapshot.data!;
          var watch = WatchConnectivity();

          if (!initData.hasWatchListener) {
            initData.hasWatchListener = true;

            watch.messageStream.listen((e) {
              var msg = e.entries.toMap();

              debugPrint("[Watch -> Phone]: ${msg["id"]}");

              switch (msg["id"]) {
                case "ping":
                  debugPrint("[Phone -> Watch]: pong");
                  watch.sendMessage({"id": "pong"});
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (context) => WearLoginScreen(initData),
                    ),
                  );
              }
            });
          }

          if (snapshot.data!.tokenCount == 0) {
            screen = LoginScreen(
              initData,
              key: ValueKey('loginScreen'),
            );
          } else {
            screen = HomeScreen(
              initData,
              key: ValueKey('homeScreen'),
            );
          }

          return MaterialApp(
            title: 'Firka',
            key: ValueKey('firkaApp'),
            navigatorKey: navigatorKey,
            // Use the global navigator key
            theme: ThemeData(
              primarySwatch: Colors.lightGreen,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: DefaultAssetBundle(bundle: FirkaBundle(), child: screen),
            routes: {
              '/login': (context) => DefaultAssetBundle(
                    bundle: FirkaBundle(),
                    child: LoginScreen(
                      initData,
                      key: ValueKey('loginScreen'),
                    ),
                  ),
              '/debug': (context) => DefaultAssetBundle(
                    bundle: FirkaBundle(),
                    child: DebugScreen(
                      initData,
                      key: ValueKey('debugScreen'),
                    ),
                  ),
            },
          );
        }

        return MaterialApp(
          home: DefaultAssetBundle(
            bundle: FirkaBundle(),
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      color: const Color(0xFF7CA021),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
