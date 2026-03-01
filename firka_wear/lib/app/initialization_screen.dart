import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wear_plus/wear_plus.dart';

import 'package:firka_wear/app/initialization.dart';
import 'package:firka_wear/l10n/app_localizations.dart';
import 'package:firka_wear/ui/theme/style.dart';
import 'package:firka_wear/ui/wear/screens/home/home_screen.dart';
import 'package:firka_wear/ui/wear/screens/login/login_screen.dart';

class WearInitializationScreen extends StatelessWidget {
  WearInitializationScreen({super.key});

  final Future<WearAppInitialization> _initialization = initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WearAppInitialization>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
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
                  WearHomeScreen(data, key: ValueKey('wearHomeScreen')),
            },
          );
        }

        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Container(color: wearStyle.colors.secondary)],
              ),
            ),
          ),
        );
      },
    );
  }
}
