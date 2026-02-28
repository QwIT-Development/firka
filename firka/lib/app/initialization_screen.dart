import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/services/watch_sync_helper.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/phone/screens/debug/debug_screen.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:firka/ui/phone/screens/login/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class InitializationScreen extends StatelessWidget {
  InitializationScreen({super.key});

  final Future<AppInitialization> _init = initializeApp().timeout(
    const Duration(seconds: 20),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitialization>(
      future: _init,
      builder: (context, snapshot) {
        // Check if initialization is complete
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            logger.shout(
              "Error in InitializationScreen",
              snapshot.error.toString(),
              snapshot.stackTrace,
            );

            FlutterNativeSplash.remove();

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
                ),
              ),
            );
          }

          // Initialization successful, determine which screen to show
          Widget screen;

          assert(snapshot.data != null);
          initData = snapshot.data!;
          initDone = true;

          FlutterNativeSplash.remove();

          WatchSyncHelper.initialize();
          if (Platform.isIOS) {
            unawaited(() async {
              try {
                await WatchSyncHelper.sendLanguageToWatch();
              } catch (e) {
                logger.warning(
                  '[Init] Failed to publish language to Watch after sync init: $e',
                );
              }
            }());
          }

          if (!initData.hasWatchListener) {
            initData.hasWatchListener = true;

            WatchSyncHelper.onWatchMessage = (msg) {
              logger.finest("WatchOS IPC [Watch -> Phone]: ${msg["id"]}");

              switch (msg["id"]) {
                case "ping":
                  if (initData.tokens.isNotEmpty) {
                    logger.finest("WatchOS IPC [Phone -> Watch]: pong");
                    const watchChannel = MethodChannel('app.firka/watch_sync');
                    watchChannel.invokeMethod('sendMessageToWatch', {
                      "id": "pong",
                    });
                    navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          initData,
                          true,
                          model: msg["model"] as String? ?? "unknown",
                        ),
                      ),
                    );
                  }
              }
            };
          }

          if (snapshot.data!.tokens.isEmpty) {
            screen = LoginScreen(initData, key: ValueKey('loginScreen'));
          } else {
            screen = HomeScreen(initData, false, key: ValueKey('homeScreen'));
          }

          return MaterialApp(
            title: 'Firka',
            key: ValueKey('firkaApp'),
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
            home: DefaultAssetBundle(
              bundle: FirkaBundle(),
              child: ValueListenableBuilder<bool>(
                valueListenable: isLightMode,
                builder: (context, isLight, _) {
                  final overlay = SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isLight
                        ? Brightness.dark
                        : Brightness.light,
                    statusBarBrightness: isLight
                        ? Brightness.light
                        : Brightness.dark,
                    systemStatusBarContrastEnforced: false,
                  );

                  SystemChrome.setSystemUIOverlayStyle(overlay);

                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: overlay,
                    child: screen,
                  );
                },
              ),
            ),
            routes: {
              '/login': (context) => DefaultAssetBundle(
                bundle: FirkaBundle(),
                child: LoginScreen(initData, key: ValueKey('loginScreen')),
              ),
              '/home': (context) => DefaultAssetBundle(
                bundle: FirkaBundle(),
                child: HomeScreen(initData, false, key: ValueKey('homeScreen')),
              ),
              '/debug': (context) => DefaultAssetBundle(
                bundle: FirkaBundle(),
                child: DebugScreen(initData, key: ValueKey('debugScreen')),
              ),
            },
          );
        }

        return MaterialApp(
          home: DefaultAssetBundle(
            bundle: FirkaBundle(),
            child: Scaffold(
              backgroundColor: const Color(0xFF7CA120),
              body: Container(),
            ),
          ),
        );
      },
    );
  }
}
