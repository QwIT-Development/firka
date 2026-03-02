import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wear_plus/wear_plus.dart';

import 'package:firka_wear/app/app_state.dart';
import 'package:firka_wear/core/bloc/wear_sync_cubit.dart';
import 'package:firka_wear/core/debug_helper.dart';
import 'package:firka_wear/core/extensions.dart';
import 'package:firka_wear/l10n/app_localizations.dart';
import 'package:firka_wear/ui/theme/style.dart';
import 'package:firka_wear/ui/shared/class_icon.dart';
import 'package:firka_wear/ui/wear/widgets/circular_progress_indicator.dart';

part 'home_screen_body.dart';

class WearHomeScreen extends StatefulWidget {
  final WearAppInitialization data;

  const WearHomeScreen(this.data, {super.key});

  @override
  State<WearHomeScreen> createState() => _WearHomeScreenState();
}

class _WearHomeScreenState extends State<WearHomeScreen> {
  WearAppInitialization get data => widget.data;

  int? currentLessonNo;
  List<Lesson> today = List.empty(growable: true);
  String apiError = "";
  DateTime now = timeNow();
  Timer? timer;
  bool init = false;
  WearMode mode = WearMode.active;
  final platform = MethodChannel('firka.app/main');
  final watch = WatchConnectivity();
  StreamSubscription? _messageSub;
  WearSyncCubit? _syncCubit;
  late final PageController _pageController;

  bool disposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCubit ??= context.read<WearSyncCubit>();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2);
    now = timeNow();
    today = data.syncStore.getLessonsForDate(now);
    init = data.syncStore.timetable.isNotEmpty;
    _messageSub = watch.messageStream.listen((e) {
      final raw = Map<String, dynamic>.from(e);
      final data = raw['data'];
      final msg = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : raw;
      if (msg['id'] == 'sync_data') _onSyncData(msg);
    });
    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      setState(() {
        now = timeNow();
      });
    });
    initStateAsync();
  }

  void _onSyncData(Map<String, dynamic> msg) async {
    if (disposed) return;
    _syncCubit?.setSyncing(true);
    try {
      final lastSyncAt = msg['lastSyncAt'] != null
          ? DateTime.parse(msg['lastSyncAt'] as String)
          : null;
      final rawTimetable = msg['timetable'] as List<dynamic>? ?? [];
      final timetable = rawTimetable
          .map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final rawGrades = msg['grades'] as List<dynamic>? ?? [];
      final grades = rawGrades
          .map((e) => Grade.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      await data.syncStore.save(
        lastSyncAt: lastSyncAt,
        timetable: timetable,
        grades: grades,
      );
      watch.sendMessage(<String, dynamic>{
        'data': jsonEncode(<String, dynamic>{'id': 'sync_done'}),
      });
      if (disposed) return;
      setState(() {
        now = timeNow();
        today = data.syncStore.getLessonsForDate(now);
      });
    } finally {
      if (!disposed) _syncCubit?.setSyncing(false);
    }
  }

  Future<void> initStateAsync() async {
    now = timeNow();
    if (data.syncStore.needsSync) {
      watch.sendMessage(<String, dynamic>{
        'data': jsonEncode(<String, dynamic>{'id': 'request_sync'}),
      });
    }
    await data.syncStore.load();
    if (disposed) return;
    setState(() {
      now = timeNow();
      today = data.syncStore.getLessonsForDate(now);
      init = true;
    });
  }

  (List<Widget>, double, double?) buildBody(
    BuildContext context,
    WearMode mode,
  ) {
    var body = List<Widget>.empty(growable: true);
    if (!init) {
      return (body, 255.h, null);
    }

    if (today.isEmpty &&
        data.syncStore.needsSync &&
        data.syncStore.timetable.isEmpty) {
      body.add(
        Text(
          AppLocalizations.of(context)!.wear_sync_with_phone,
          style: wearStyle.fonts.H_18px.apply(
            color: wearStyle.colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      );
      return (body, 255.h, null);
    }
    if (today.isEmpty) {
      body.add(
        Text(
          AppLocalizations.of(context)!.noClasses,
          style: wearStyle.fonts.H_18px.apply(
            color: wearStyle.colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      );

      platform.invokeMethod('activity_cancel');
      return (body, 255.h, null);
    }
    if (now.isAfter(today.last.end)) {
      body.add(
        Text(
          AppLocalizations.of(context)!.noMoreClasses,
          style: wearStyle.fonts.H_18px.apply(
            color: wearStyle.colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      );

      platform.invokeMethod('activity_cancel');
      return (body, 300.h, null);
    }
    if (now.isBefore(today.first.start)) {
      var untilFirst = today.first.start.difference(now);

      body.add(
        Text(
          AppLocalizations.of(context)!.firstIn(untilFirst.formatDuration()),
          style: wearStyle.fonts.H_18px.apply(
            color: wearStyle.colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      );

      platform.invokeMethod('activity_update');
      return (body, 255.h, null);
    }
    currentLessonNo = null;
    if (now.isAfter(today.first.start) && now.isBefore(today.last.end)) {
      Lesson? currentLesson = today.getCurrentLesson(now);
      Lesson? lastLesson = today.getPrevLesson(now);
      Lesson? nextLesson = today.getNextLesson(now);

      if (currentLesson != null) {
        currentLessonNo = today.getLessonNo(currentLesson);
      }

      Duration? currentBreak;
      Duration? currentBreakProgress;

      if (lastLesson != null && nextLesson != null) {
        currentBreak = nextLesson.start.difference(lastLesson.end);
        currentBreakProgress = nextLesson.start.difference(now);
      }

      if (currentLesson == null) {
        if (currentBreak == null) {
          throw Exception("currentBreak == null");
        }
        if (currentBreakProgress == null) {
          throw Exception("currentBreakProgress == null");
        }

        var minutes = currentBreakProgress.inMinutes + 1;
        final progress =
            currentBreakProgress.inMilliseconds / currentBreak.inMilliseconds;

        body.add(
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  AppLocalizations.of(context)!.breakTxt,
                  style: TextStyle(
                    color: wearStyle.colors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
              ),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.timeLeft(minutes),
                  style: TextStyle(
                    color: wearStyle.colors.textPrimary,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontVariations: [FontVariation('wght', 400)],
                  ),
                ),
              ),
            ],
          ),
        );

        platform.invokeMethod('activity_update');
        return (body, 20.h, progress);
      } else {
        var duration = currentLesson.start.difference(currentLesson.end);
        var elapsed = currentLesson.start.difference(now);
        var timeLeft = currentLesson.end.difference(now);

        var minutes = timeLeft.inMinutes + 1;
        final progress = elapsed.inMilliseconds / duration.inMilliseconds;

        Widget nextLessonWidget = SizedBox();

        if (nextLesson != null) {
          nextLessonWidget = Center(
            child: Text(
              "→ ${nextLesson.name}, ${nextLesson.roomName}",
              style: TextStyle(
                color: wearStyle.colors.textPrimary,
                fontSize: 12,
                fontFamily: 'Montserrat',
                fontVariations: [FontVariation('wght', 400)],
              ),
            ),
          );
        }

        var currentLessonText =
            "${currentLesson.name}, ${currentLesson.roomName}";
        if (currentLessonText.length > 10) {
          if (currentLesson.roomName!.length > 10) {
            currentLessonText =
                "${currentLesson.name}, ${currentLesson.roomName?.substring(0, 6) ?? ''}...";
          } else {
            currentLessonText =
                "${currentLesson.name.substring(0, 10)}, ${currentLesson.roomName}...";
          }
        }

        body.add(
          Column(
            children: [
              Center(
                child: ClassIconWidget(
                  color: wearStyle.colors.accent,
                  size: 16,
                  uid: currentLesson.uid,
                  className: currentLesson.name,
                  category: currentLesson.subject?.name ?? '',
                ).build(context),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  currentLessonText,
                  style: TextStyle(
                    color: wearStyle.colors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
              ),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.timeLeft(minutes),
                  style: TextStyle(
                    color: wearStyle.colors.textPrimary,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontVariations: [FontVariation('wght', 400)],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              nextLessonWidget,
            ],
          ),
        );

        platform.invokeMethod('activity_update');
        return (body, 0.h, progress);
      }
    }

    platform.invokeMethod('activity_cancel');
    throw Exception("unexpected state");
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    Widget titleBar = SizedBox();

    if (currentLessonNo != null) {
      titleBar = ArcText(
        radius: 99,
        startAngle: pi / 180,
        startAngleAlignment: StartAngleAlignment.center,
        text: AppLocalizations.of(context)!.wearTitle(currentLessonNo!),
        textStyle: TextStyle(
          fontSize: 12,
          color: wearStyle.colors.secondary,
          fontFamily: 'Montserrat',
          fontVariations: [FontVariation('wght', 500)],
        ),
        placement: Placement.inside,
      );
    }

    return BlocBuilder<WearSyncCubit, WearSyncState>(
      builder: (context, syncState) {
        var (body, padding, progress) = buildBody(context, mode);
        final viewportHeight = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: mode == WearMode.active
              ? wearStyle.colors.background
              : wearStyle.colors.backgroundAmoled,
          body: Stack(
            children: [
              Center(child: titleBar),
              Transform.translate(
                offset: Offset(0, 200.h),
                child: CustomPaint(
                  painter: CircularProgressPainter(
                    progress: progress ?? 0.0,
                    screenSize: MediaQuery.of(context).size,
                    strokeWidth: 4,
                    color: wearStyle.colors.accent,
                  ),
                  child: SizedBox.expand(),
                ),
              ),
              Center(
                child: Column(
                  children: [
                    WatchShape(
                      builder: (context, shape, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[child!],
                        );
                      },
                      child: AmbientMode(
                        builder: (context, mode, child) {
                          if (this.mode != mode) {
                            Timer(Duration(milliseconds: 100), () {
                              setState(() {
                                this.mode = mode;
                              });
                            });
                          }

                          return SizedBox(
                            height: viewportHeight,
                            child: PageView(
                              controller: _pageController,
                              scrollDirection: Axis.vertical,
                              children: [
                                _PlaceholderPage(
                                  index: 1,
                                  viewportHeight: viewportHeight,
                                ),
                                _PlaceholderPage(
                                  index: 2,
                                  viewportHeight: viewportHeight,
                                ),
                                _HomeScreenBodyPage(
                                  body: body,
                                  padding: padding,
                                  viewportHeight: viewportHeight,
                                ),
                                _PlaceholderPage(
                                  index: 3,
                                  viewportHeight: viewportHeight,
                                ),
                                _PlaceholderPage(
                                  index: 4,
                                  viewportHeight: viewportHeight,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (syncState.isSyncing)
                Positioned.fill(
                  child: Container(
                    color: wearStyle.colors.background.withValues(alpha: 0.8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            AppLocalizations.of(context)!.wear_syncing,
                            style: wearStyle.fonts.B_16R.apply(
                              color: wearStyle.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    timer?.cancel();
    _pageController.dispose();
    disposed = true;
    super.dispose();
  }
}
