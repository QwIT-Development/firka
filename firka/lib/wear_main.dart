import 'dart:async';
import 'dart:io';

import 'package:firka/helpers/db/models/generic_cache_model.dart';
import 'package:firka/helpers/db/models/homework_cache_model.dart';
import 'package:firka/helpers/db/models/timetable_cache_model.dart';
import 'package:firka/helpers/db/models/token_model.dart';
import 'package:firka/ui/wear/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zear_plus/wear_plus.dart';

import 'helpers/api/client/kreta_client.dart';
import 'l10n/app_localizations.dart';
import 'ui/wear/screens/home/home_screen.dart';

Isar? isarInit;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WearAppInitialization {
  final Isar isar;
  late KretaClient client;
  final int tokenCount;

  WearAppInitialization({required this.isar, required this.tokenCount});
}

Future<Isar> initDB() async {
  if (isarInit != null) return isarInit!;
  final dir = await getApplicationDocumentsDirectory();

  isarInit = await Isar.open(
    [
      TokenModelSchema,
      GenericCacheModelSchema,
      TimetableCacheModelSchema,
      HomeworkCacheModelSchema
    ],
    inspector: true,
    directory: dir.path,
  );

  return isarInit!;
}

Future<WearAppInitialization> initializeApp() async {
  final isar = await initDB();

  var init = WearAppInitialization(
      isar: isar, tokenCount: await isar.tokenModels.count());

  resetOldTimeTableCache(isar);
  resetOldHomeworkCache(isar);

  // TODO: Account selection
  if (init.tokenCount > 0) {
    init.client =
        KretaClient((await isar.tokenModels.where().findFirst())!, isar);
  }

  return init;
}

void wearMain(MethodChannel platform) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await Permission.notification.isDenied) {
    var status = await Permission.notification.request();

    if (status.isDenied) {
      exit(-1);
    }
  }

  await ScreenUtil.ensureScreenSize();

  // Run App Initialization
  runApp(WearInitializationScreen());
}

class WearInitializationScreen extends StatelessWidget {
  WearInitializationScreen({super.key});

  // Place to store the initialization future
  final Future<WearAppInitialization> _initialization = initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WearAppInitialization>(
      future: _initialization,
      builder: (context, snapshot) {
        // Check if initialization is complete
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // Handle initialization error

            return MaterialApp(
              key: ValueKey('firkaErrorPage'),
              home: Scaffold(
                body: Center(
                  child: WatchShape(
                    builder: (context, shape, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Error initializing app: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: SizedBox(),
                  ),
                ),
              ),
            );
          }

          // Initialization successful, determine which screen to show
          Widget screen;

          assert(snapshot.data != null);
          var data = snapshot.data!;

          if (snapshot.data!.tokenCount == 0) {
            screen = WearLoginScreen(data, key: ValueKey('wearLoginScreen'));
          } else {
            screen = WearHomeScreen(data, key: ValueKey('wearHomeScreen'));
          }

          return MaterialApp(
            key: ValueKey('firkaWearApp'),
            title: 'Firka',
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
              '/login': (context) =>
                  WearLoginScreen(data, key: ValueKey('wearLoginScreen')),
              '/home': (context) =>
                  WearHomeScreen(data, key: ValueKey('wearHomeScreen'))
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
