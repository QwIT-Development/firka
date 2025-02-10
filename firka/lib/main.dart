import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/db/models/generic_cache_model.dart';
import 'package:firka/helpers/db/models/timetable_cache_model.dart';
import 'package:firka/helpers/db/models/token_model.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/ui/phone/pages/error/error_page.dart';
import 'package:firka/ui/phone/screens/debug/debug_screen.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:firka/ui/phone/screens/login/login_screen.dart';
import 'package:firka/ui/phone/screens/wear_login/wear_login_screen.dart';
import 'package:firka/wear_main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'helpers/api/consts.dart';
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
  AppSettingsModel settings;

  AppInitialization({
    required this.isar,
    required this.tokenCount,
    required this.settings,
  });

  bool _writing = false;

  Future<void> saveSettings() async {
    while (_writing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _writing = true;
    await isar.writeTxn(() async {
      await isar.appSettingsModels.put(settings);
    });
    _writing = false;
  }
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
  var settings = AppSettingsModel();
  settings.id = 0;

  if (kDebugMode) {
    print('Token count: $tokenCount');
  }

  if (await isar.appSettingsModels.count() != 0) {
    settings = (await isar.appSettingsModels.where().findFirst())!;
  }

  if (settings.useCustomHost != null && settings.useCustomHost!) {
    var host = settings.customHost!;

    KretaEndpoints.kretaBase = "https://$host";
    KretaEndpoints.kretaIdp = KretaEndpoints.kretaBase;
    KretaEndpoints.kretaLoginUrl =
        "${KretaEndpoints.kretaBase}/Account/Login?ReturnUrl=%2Fconnect%2Fauthorize%2Fcallback%3Fprompt%3Dlogin%26nonce%3DwylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU%26response_type%3Dcode%26code_challenge_method%3DS256%26scope%3Dopenid%2520email%2520offline_access%2520kreta-ellenorzo-webapi.public%2520kreta-eugyintezes-webapi.public%2520kreta-fileservice-webapi.public%2520kreta-mobile-global-webapi.public%2520kreta-dkt-webapi.public%2520kreta-ier-webapi.public%26code_challenge%3DHByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ%26redirect_uri%3Dhttps%253A%252F%252Fmobil.e-kreta.hu%252Fellenorzo-student%252Fprod%252Foauthredirect%26client_id%3Dkreta-ellenorzo-student-mobile-ios%26state%3Dkreta_student_mobile%26suppressed_prompt%3Dlogin";
    KretaEndpoints.tokenGrantUrl = "${KretaEndpoints.kretaBase}/connect/token";
  }

  var init = AppInitialization(
    isar: isar,
    tokenCount: tokenCount,
    settings: settings,
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

  WidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('firka.app/main');
  if (Platform.isAndroid) {
    var isWear = (await platform.invokeMethod("isWear")) as bool;

    if (isWear) {
      wearMain(platform);
      return;
    }
  }

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
