import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/bloc/profile_picture_cubit.dart';
import 'package:firka/core/bloc/reauth_cubit.dart';
import 'package:firka/core/bloc/settings_cubit.dart';
import 'package:firka/core/bloc/theme_cubit.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/routing/app_router.dart';
import 'package:firka/services/watch_sync_helper.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  GoRouter? _router;
  final Future<AppInitialization> _init = initializeApp().timeout(
    const Duration(seconds: 20),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitialization>(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            logger.shout(
              "Error in InitializationScreen",
              snapshot.error.toString(),
              snapshot.stackTrace,
            );

            FlutterNativeSplash.remove();

            return MaterialApp(
              key: const ValueKey('errorPage'),
              home: DefaultAssetBundle(
                bundle: FirkaBundle(),
                child: Scaffold(
                  body: Center(
                    child: Text(
                      'Error initializing app: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            );
          }

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
                    _router?.go('/home');
                  }
              }
            };
          }

          if (_router == null) {
            _router = createAppRouter();
            appRouter = _router;
          }

          final themeCubit = initData.themeCubit!;
          final settingsCubit = initData.settingsCubit!;
          final profilePictureCubit = initData.profilePictureCubit!;
          final reauthCubit = initData.reauthCubit!;
          final homeRefreshCubit = initData.homeRefreshCubit!;
          return MultiBlocProvider(
            providers: [
              BlocProvider<ThemeCubit>.value(value: themeCubit),
              BlocProvider<SettingsCubit>.value(value: settingsCubit),
              BlocProvider<ProfilePictureCubit>.value(value: profilePictureCubit),
              BlocProvider<ReauthCubit>.value(value: reauthCubit),
              BlocProvider<HomeRefreshCubit>.value(value: homeRefreshCubit),
            ],
            child: MaterialApp.router(
              title: 'Firka',
              key: const ValueKey('firkaApp'),
              routerConfig: _router!,
              theme: ThemeData(
                primarySwatch: Colors.lightGreen,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) {
                return BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, themeState) {
                    final isLight = themeState.isLightMode;
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
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                );
              },
            ),
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
