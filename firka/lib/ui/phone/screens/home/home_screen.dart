import 'dart:io';
import 'package:firka/core/bloc/toast_cubit.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/core/settings.dart';
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

    prefetch();
    _preloadImages();
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
