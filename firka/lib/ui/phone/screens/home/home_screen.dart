import 'dart:async';
import 'dart:io';
import 'package:firka/api/client/kreta_stream.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/services/active_account_helper.dart';
import 'package:firka/services/live_activity_service.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/services/watch_sync_helper.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/phone/pages/extras/reauth_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/data/widget.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/bloc/profile_picture_cubit.dart';
import 'package:firka/core/bloc/reauth_cubit.dart';
import 'package:firka/core/bloc/settings_cubit.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/core/image_preloader.dart';
import 'package:firka/ui/shared/delayed_spinner.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import '../../pages/extras/main_error.dart';

enum ActiveToastType { fetching, error, reauth, none }

bool _fetching = true;
bool _prefetched = false;

class HomeScreen extends StatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends FirkaState<HomeScreen>
    with WidgetsBindingObserver {
  Widget? toast;
  bool _disposed = false;
  bool _preloadDone = false;
  bool _didRunSecondaryICloudRecovery = false;
  bool _prefetchInProgress = false;
  bool _didRunLiveActivityLogin = false;
  bool _hasCompletedFirstPrefetch = false;

  ActiveToastType activeToast = ActiveToastType.none;

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

  Future<void> _runSecondaryICloudRecoveryIfNeeded() async {
    if (!Platform.isIOS || _didRunSecondaryICloudRecovery) return;
    _didRunSecondaryICloudRecovery = true;

    final activeToken = pickActiveToken(
      tokens: initData.tokens,
      settings: initData.settings,
      preferredStudentIdNorm: initData.client.model.studentIdNorm,
    );

    final now = DateTime.now();
    final shouldRunRecovery =
        initData.client.needsReauth ||
        activeToken == null ||
        activeToken.expiryDate == null ||
        activeToken.expiryDate!.isBefore(now.add(const Duration(seconds: 60)));

    if (!shouldRunRecovery) return;

    logger.info(
      '[Home] Secondary iCloud recovery scheduled (5s delay, startup safety pass)',
    );
    await Future.delayed(const Duration(seconds: 5));
    if (_disposed) return;

    try {
      final recovered = await WatchSyncHelper.checkAndRecoverFromiCloud(
        isar: initData.isar,
        tokens: initData.tokens,
        client: initData.client,
      );
      if (!recovered) {
        logger.info('[Home] Secondary iCloud recovery found no fresher token');
        return;
      }

      final refreshedTokens = initDone ? initData.tokens : initData.tokens;
      initData.tokens = refreshedTokens;

      final selectedToken = pickActiveToken(
        tokens: refreshedTokens,
        settings: initData.settings,
        preferredStudentIdNorm: initData.client.model.studentIdNorm,
      );
      if (selectedToken != null) {
        initData.client.model = selectedToken;
      }
      initData.reauthCubit?.clear();
      logger.info('[Home] Secondary iCloud recovery applied a fresher token');
    } catch (e) {
      logger.warning('[Home] Secondary iCloud recovery failed: $e');
    }
  }

  void prefetch() async {
    if (_prefetched) return;
    if (_prefetchInProgress) return;

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      logger.info(
        '[Home] prefetch: App is in background, deferring to foreground',
      );
      return;
    }

    _prefetchInProgress = true;
    try {
      _prefetched = true;

      await _runSecondaryICloudRecoveryIfNeeded();

      try {
        await initData.client.refreshTokenProactively().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            logger.warning('[Home] Token refresh/recovery timed out after 60s');
            return false;
          },
        );
      } catch (e) {
        logger.warning('[Home] Token refresh/recovery failed: $e');
      }

      await fetchData();

      if (Platform.isAndroid) {
        await WidgetCacheHelper.updateWidgetCache(appStyle, initData.client);
        await HomeWidget.updateWidget(
          qualifiedAndroidName:
              "app.firka.naplo.glance.TimetableWidgetReceiver",
        );
      }

      if (Platform.isIOS) {
        await WidgetCacheHelper.refreshIOSWidgets(
          initData.client,
          initData.settings,
        );

        if (!_didRunLiveActivityLogin) {
          _didRunLiveActivityLogin = true;
          final token = pickActiveToken(
            tokens: initData.tokens,
            settings: initData.settings,
          );
          final studentName = token?.studentId ?? "Student";
          LiveActivityService.onUserLogin(
            client: initData.client,
            studentName: studentName,
            settingsStore: initData.settings,
          ).catchError((e, st) {
            logger.severe('LiveActivity registration failed: $e', e, st);
          });
        }
      }

      if (!_disposed &&
          (LiveActivityService.isTokenExpired || initData.client.needsReauth)) {
        activeToast = ActiveToastType.reauth;
        setState(() {
          toast = buildReauthToast(context, initData, () {
            if (!_disposed) {
              setState(() {
                activeToast = ActiveToastType.none;
                toast = null;
              });
            }
          });
        });
        return;
      }
    } catch (e) {
      if (e is TokenExpiredException || e is InvalidGrantException) {
        activeToast = ActiveToastType.reauth;
        if (_disposed) return;
        setState(() {
          toast = buildReauthToast(context, initData, () {
            if (!_disposed) {
              setState(() {
                activeToast = ActiveToastType.none;
                toast = null;
              });
            }
          });
        });
        return;
      }

      activeToast = ActiveToastType.error;
      var dismissDelay = 120;
      if (kDebugMode) dismissDelay = 2;
      Timer(Duration(seconds: dismissDelay), () {
        if (_disposed) return;
        setState(() {
          activeToast = ActiveToastType.none;
          toast = null;
        });
      });

      if (_disposed) return;
      setState(() {
        toast = Positioned(
          top: MediaQuery.of(context).size.height / 1.6,
          left: 0.0,
          right: 0.0,
          bottom: 0,
          child: Center(
            child: Card(
              color: appStyle.colors.errorCard,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(200)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      initData.l10n.api_error,
                      style: appStyle.fonts.B_16SB.copyWith(
                        color: appStyle.colors.errorText,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      child: FirkaIconWidget(
                        FirkaIconType.majesticons,
                        Majesticon.questionCircleSolid,
                        color: appStyle.colors.errorAccent,
                        size: 24,
                      ),
                      onTap: () {
                        var stackTrace = "";
                        if (e is Error && e.stackTrace != null) {
                          stackTrace = e.stackTrace.toString();
                        }
                        showErrorBottomSheet(context, "$e\n$stackTrace");
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    } finally {
      _prefetchInProgress = false;
      _hasCompletedFirstPrefetch = true;
      if (!_disposed) {
        setState(() {
          _fetching = false;
          if (activeToast == ActiveToastType.fetching) toast = null;
        });
      }
    }
  }

  Future<void> fetchData() async {
    var lessonsFetched = 0;
    var noticeBoardFetched = 0;
    var infoBoardFetched = 0;
    var studentFetched = 0;
    var testsFetched = 0;
    var gradesFetched = 0;
    var homeworkFetched = 0;

    final midnight = timeNow().getMidnight();

    initData.client
        .getTimeTableStream(
          midnight,
          midnight.add(Duration(hours: 23, minutes: 59)),
          cacheOnly: false,
        )
        .forEach((lessons) {
          lessonsFetched++;
        });

    initData.client.getNoticeBoardStream(cacheOnly: false).forEach((items) {
      noticeBoardFetched++;
    });

    initData.client.getInfoBoardStream(cacheOnly: false).forEach((items) {
      infoBoardFetched++;
    });

    initData.client.getStudentStream(cacheOnly: false).forEach((student) {
      studentFetched++;
    });

    initData.client.getTestsStream(cacheOnly: false).forEach((tests) {
      testsFetched++;
    });

    initData.client.getGradesStream(cacheOnly: false).forEach((grades) {
      gradesFetched++;
    });

    initData.client.getHomeworkStream(cacheOnly: false).forEach((homework) {
      homeworkFetched++;
    });

    final startTime = DateTime.now();
    const maxWaitTime = Duration(seconds: 30);

    while (lessonsFetched < 2 ||
        noticeBoardFetched < 2 ||
        infoBoardFetched < 2 ||
        studentFetched < 2 ||
        testsFetched < 2 ||
        gradesFetched < 2 ||
        homeworkFetched < 2) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        logger.warning('[Home] fetchData timed out after 30s');
        break;
      }
      await Future.delayed(Duration(milliseconds: 50));
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

    if (Platform.isIOS &&
        initData.settings.group("settings").boolean("beta_warning")) {
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

  Future<void> _preloadImages() async {
    final imagePaths = initData.settings.appIcons.keys
        .map((icon) => "assets/images/icons/$icon.webp")
        .toList();
    imagePaths.add("assets/images/background.webp");

    try {
      await ImagePreloader.preloadMultipleAssets(FirkaBundle(), imagePaths);
      if (!mounted) return;
      setState(() => _preloadDone = true);
    } catch (e) {
      logger.severe('Home: error preloading images: $e');
      if (!mounted) return;
      setState(() => _preloadDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_preloadDone) {
      return Scaffold(
        backgroundColor: appStyle.colors.background,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [SizedBox(), DelayedSpinnerWidget(), SizedBox()],
            ),
            SizedBox(),
          ],
        ),
      );
    }

    if (_fetching) {
      if (_disposed) return const SizedBox.shrink();
      setState(() {
        activeToast = ActiveToastType.fetching;
        toast = Positioned(
          top: MediaQuery.of(context).size.height / 1.6,
          left: 0.0,
          right: 0.0,
          bottom: 0,
          child: Center(
            child: Card(
              color: appStyle.colors.card,
              shadowColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: appStyle.colors.accent,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      initData.l10n.refreshing,
                      style: appStyle.fonts.B_16SB.copyWith(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (mounted) setState(() {});
      },
      child: BlocListener<ProfilePictureCubit, ProfilePictureState>(
        listener: (context, state) {
          if (mounted) setState(() {});
        },
        child: BlocListener<ReauthCubit, ReauthState>(
          listener: (context, state) {
            if (!mounted || _disposed) return;
            if (!state.needsReauth && activeToast == ActiveToastType.reauth) {
              setState(() {
                activeToast = ActiveToastType.none;
                toast = null;
              });
            }
          },
          child: Scaffold(
            backgroundColor: appStyle.colors.background,
            body: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [widget.child, toast ?? SizedBox.shrink()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_disposed) {
      logger.info('[Home] App resumed to foreground, re-running prefetch');
      _prefetched = false;
      _didRunSecondaryICloudRecovery = false;
      prefetch();

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
      final token = pickActiveToken(
        tokens: initData.tokens,
        settings: initData.settings,
        preferredStudentIdNorm: initData.client.model.studentIdNorm,
      );
      final studentName = token?.studentId ?? 'Student';
      LiveActivityService.onUserLogin(
        client: initData.client,
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
      final token = pickActiveToken(
        tokens: initData.tokens,
        settings: initData.settings,
      );
      final studentName = token?.studentId ?? "Student";
      await LiveActivityService.checkAndUpdateTimetable(
        client: initData.client,
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
    activeToast = ActiveToastType.none;
    super.dispose();
  }
}
