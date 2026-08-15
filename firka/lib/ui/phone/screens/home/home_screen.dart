import 'dart:async';
import 'dart:io';
import 'package:firka/core/bloc/toast_cubit.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/services/live_activity_service.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'package:firka/core/bloc/profile_picture_cubit.dart';
import 'package:firka/core/bloc/settings_cubit.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/core/image_preloader.dart';

bool _fetching = false;
bool _prefetched = false;

class HomeScreen extends StatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends FirkaState<HomeScreen>
    with WidgetsBindingObserver {
  bool _disposed = false;
  bool _didRunLiveActivityLogin = false;
  bool _hasCompletedFirstPrefetch = false;

  void _setupNotificationListener() {
    final notificationChannel = MethodChannel('firka.app/notifications');

    notificationChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationTapped') {
        logger.info('Notification tapped: ${call.arguments}');
        final args = call.arguments as Map<Object?, Object?>?;
        if (args == null) return;
        final action = args['action'] as String?;
        final route = args['route'] as String?;
        if (action != null || route != null) {
          logger.info('Navigating to timetable from notification');
          appRouter?.go('/timetable');
        }
      }
    });
  }

  void _setupWidgetDeepLinkListener() {
    if (!Platform.isIOS) return;

    final widgetChannel = MethodChannel('firka.app/widget_deep_link');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widgetChannel.invokeMethod<String>('getPendingDeepLink').then((link) {
        if (link != null) _handleWidgetDeepLink(link);
      });
    });

    widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetDeepLink') {
        final link = call.arguments as String?;
        if (link != null) _handleWidgetDeepLink(link);
      }
    });
  }

  void _handleWidgetDeepLink(String link) {
    logger.info('Widget deep link received: $link');
    switch (link) {
      case 'home':
        appRouter?.go('/home');
        break;
      case 'timetable':
        appRouter?.go('/timetable');
        break;
      case 'grades':
        appRouter?.go('/grades');
        break;
      default:
        logger.warning('Unknown widget deep link: $link');
    }
  }

  void prefetch() async {
    if (_prefetched || _fetching) return;

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      logger.info(
        '[Home] prefetch: App is in background, deferring to foreground',
      );
      return;
    }

    setState(() {
      _fetching = true;
    });
    try {
      await initData.client!.renewCache(reInit: true);

      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(
          qualifiedAndroidName:
              "app.firka.naplo.glance.TimetableWidgetReceiver",
        );
      }

      if (Platform.isIOS) {
        if (!_didRunLiveActivityLogin) {
          _didRunLiveActivityLogin = true;
          final token = initData.client!.cache.token;
          final studentName = token.username;
          LiveActivityService.onUserLogin(
            client: initData.client!,
            studentName: studentName,
            settingsStore: initData.settings,
          ).catchError((e, st) {
            logger.severe('LiveActivity registration failed: $e', e, st);
          });
        }
      }
    } catch (e) {
      if (_disposed) return;
      (context);
    } finally {
      _hasCompletedFirstPrefetch = true;
      if (!_disposed) {
        setState(() {
          _prefetched = true;
          _fetching = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _setupNotificationListener();
    _setupWidgetDeepLinkListener();

    prefetch();
    _preloadImages();

    if (Platform.isIOS && Settings.betaWarning.value) {
      Future.delayed(Duration(seconds: 3), () async {
        await LiveActivityService.showConsentScreenIfNeeded();
      });
    }
    if (Platform.isIOS) {
      Future.delayed(const Duration(seconds: 4), () {
        if (!_disposed) _runLiveActivityLoginIfNeeded();
      });
    }
  }

  void _preloadImages() async {
    final imagePaths = appIconLabels(
      initData.l10n,
    ).keys.map((icon) => "assets/images/icons/$icon.webp").toList();
    imagePaths.add("assets/images/background.webp");

    try {
      await ImagePreloader.preloadMultipleAssets(FirkaBundle(), imagePaths);
    } catch (e) {
      logger.severe('Home: error preloading images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (mounted) setState(() {});
      },
      child: BlocListener<ProfilePictureCubit, ProfilePictureState>(
        listener: (context, state) {
          if (mounted) setState(() {});
        },
        child: BlocListener<ToastCubit, ToastState>(
          listener: (context, state) {
            if (mounted) setState(() {});
            if (state.type == .none) {
              initData.homeRefreshCubit.requestRefresh();
            }
          },
          child: Scaffold(
            backgroundColor: appStyle.colors.background,
            body: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    widget.child,
                    ?(_toastOverlay(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _toastOverlay(BuildContext context) {
    final toast = context.watch<ToastCubit>().state;
    if (toast.type == .fetching && !_hasCompletedFirstPrefetch) {
      return null;
    }
    return toast.buildWidget(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_disposed) {
      logger.info('[Home] App resumed to foreground, re-running prefetch');
      _prefetched = false;
      prefetch();
      setState(() {});

      if (Platform.isIOS) {
        _refreshLiveActivityOnResume();
        _runLiveActivityLoginIfNeeded();
      }
    }
  }

  /// Fallback: if Live Activity login never ran (e.g. prefetch bailed on lifecycle
  /// or fetchData didn't complete), run it once when app is resumed.
  void _runLiveActivityLoginIfNeeded() {
    if (_didRunLiveActivityLogin || _disposed) return;
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_disposed || _didRunLiveActivityLogin) return;
      _didRunLiveActivityLogin = true;
      final studentName = initData.client!.cache.token.username;
      LiveActivityService.onUserLogin(
        client: initData.client!,
        studentName: studentName,
        settingsStore: initData.settings,
      ).catchError((e, st) {
        _didRunLiveActivityLogin = false;
        logger.severe('LiveActivity registration failed: $e', e, st);
      });
    });
  }

  void _refreshLiveActivityOnResume() async {
    if (!_hasCompletedFirstPrefetch) return;
    try {
      final studentName = initData.client!.cache.token.username;
      await LiveActivityService.checkAndUpdateTimetable(
        client: initData.client!,
        studentName: studentName,
        settingsStore: initData.settings,
      );
    } catch (e) {
      logger.warning(
        '[Home] LiveActivity timetable update on resume failed: $e',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _disposed = true;
    _fetching = false;
    _prefetched = false;
    super.dispose();
  }
}
