import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wear_plus/wear_plus.dart';

import 'package:firka_wear/app/app_state.dart';
import 'package:firka_wear/app/initialization.dart';
import 'package:firka_wear/core/bloc/wear_sync_cubit.dart';
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

          assert(snapshot.data != null);
          initData = snapshot.data!;
          initDone = true;

          final data = initData;
          final screen = data.tokenCount == 0
              ? WearLoginScreen(data, key: ValueKey('wearLoginScreen'))
              : WearHomeScreen(data, key: ValueKey('wearHomeScreen'));

          return BlocProvider(
            create: (_) => WearSyncCubit(),
            child: MaterialApp(
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
            ),
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
