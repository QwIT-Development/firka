import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/db/models/generic_cache_model.dart';
import 'package:firka/helpers/db/models/timetable_cache_model.dart';
import 'package:firka/helpers/db/models/token_model.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/settings/setting.dart';
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

  AppInitialization({
    required this.isar,
    required this.tokenCount,
    required this.settings,
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

  var settings = SettingsStore();

  var init = AppInitialization(
    isar: isar,
    tokenCount: tokenCount,
    settings: SettingsStore(),
  );

  resetOldTimeTableCache(isar);
  resetOldHomeworkCache(isar);

  // TODO: Account selection
  if (tokenCount > 0) {
    init.client =
        KretaClient((await isar.tokenModels.where().findFirst())!, isar);
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

  // Place to store the initialization future
  final Future<AppInitialization> _initialization = initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitialization>(
      future: _initialization,
      builder: (context, snapshot) {
        // Check if initialization is complete
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            debugPrintStack(label: snapshot.error.toString());

            // Handle initialization error
            return MaterialApp(
              key: ValueKey('errorPage'),
              home: Scaffold(
                body: Center(
                  child: Text(
                    'Error initializing app: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
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
            home: screen,
            routes: {
              '/login': (context) => LoginScreen(
                    initData,
                    key: ValueKey('loginScreen'),
                  ),
              '/debug': (context) => DebugScreen(
                    initData,
                    key: ValueKey('debugScreen'),
                  ),
            },
          );
        }

        return MaterialApp(
          home: Scaffold(
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
        );
      },
    );
  }
}
