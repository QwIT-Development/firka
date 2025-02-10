import 'dart:async';
import 'dart:math';

import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/ui/widget/class_icon.dart';
import 'package:firka/wear_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zear_plus/wear_plus.dart';

import '../../../../helpers/debug_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../model/style.dart';
import '../../widgets/circular_progress_indicator.dart';

class WearHomeScreen extends StatefulWidget {
  final WearAppInitialization data;

  const WearHomeScreen(this.data, {super.key});

  @override
  State<WearHomeScreen> createState() => _WearHomeScreenState(data);
}

class _WearHomeScreenState extends State<WearHomeScreen> {
  final WearAppInitialization data;

  _WearHomeScreenState(this.data);

  int? currentLessonNo;
  List<Lesson> today = List.empty(growable: true);
  String apiError = "";
  DateTime now = timeNow();
  Timer? timer;
  bool init = false;
  WearMode mode = WearMode.active;
  final platform = MethodChannel('firka.app/main');

  bool disposed = false;

  @override
  void initState() {
    super.initState();
    now = timeNow();

    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      setState(() {
        now = timeNow();
      });
    });
    initStateAsync();
  }

  Future<void> initStateAsync() async {
    var kreta = data.client;

    now = timeNow();
    var todayStart = now.getMidnight();
    var todayEnd = todayStart.add(Duration(hours: 23, minutes: 59));
    var classes = await kreta.getTimeTable(todayStart, todayEnd);

    if (disposed) return;
    setState(() {
      if (classes.response != null) today = classes.response!;
      if (classes.statusCode != 200) {
        apiError = "Unexpected status : ${classes.statusCode}";
      }
      if (classes.err != null) apiError = classes.err!;

      init = true;
    });
  }

  (List<Widget>, double) buildBody(BuildContext context, WearMode mode) {
    ScreenUtil.init(context);

    var body = List<Widget>.empty(growable: true);
    if (!init) {
      return (body, 255.h);
    }

    if (today.isEmpty && apiError != "") {
      body.add(Text(
        apiError,
        style:
            wearStyle.fonts.H_18px.apply(color: wearStyle.colors.textPrimary),
        textAlign: TextAlign.center,
      ));

      return (body, 255.h);
    }
    if (today.isEmpty) {
      body.add(Text(
        AppLocalizations.of(context)!.noClasses,
        style:
            wearStyle.fonts.H_18px.apply(color: wearStyle.colors.textPrimary),
        textAlign: TextAlign.center,
      ));

      platform.invokeMethod('activity_cancel');
      return (body, 255.h);
    }
    if (now.isAfter(today.last.end)) {
      body.add(Text(
        AppLocalizations.of(context)!.noMoreClasses,
        style:
            wearStyle.fonts.H_18px.apply(color: wearStyle.colors.textPrimary),
        textAlign: TextAlign.center,
      ));

      platform.invokeMethod('activity_cancel');
      return (body, 300.h);
    }
    if (now.isBefore(today.first.start)) {
      var untilFirst = today.first.start.difference(now);

      body.add(Text(
        AppLocalizations.of(context)!.firstIn(untilFirst.formatDuration()),
        style:
            wearStyle.fonts.H_18px.apply(color: wearStyle.colors.textPrimary),
        textAlign: TextAlign.center,
      ));

      platform.invokeMethod('activity_update');
      return (body, 255.h);
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

        body.add(CustomPaint(
            painter: CircularProgressPainter(
                progress: currentBreakProgress.inMilliseconds /
                    currentBreak.inMilliseconds,
                // progress: 5 / 10,
                screenSize: MediaQuery.of(context).size,
                strokeWidth: 4,
                color: wearStyle.colors.accent),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 55.h),
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.breakTxt,
                    style: TextStyle(
                      color: wearStyle.colors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontVariations: [
                        FontVariation('wght', 600),
                      ],
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
                      fontVariations: [
                        FontVariation('wght', 400),
                      ],
                    ),
                  ),
                )
              ],
            )));

        platform.invokeMethod('activity_update');
        return (body, 200.h);
      } else {
        var duration = currentLesson.start.difference(currentLesson.end);
        var elapsed = currentLesson.start.difference(now);
        var timeLeft = currentLesson.end.difference(now);

        var minutes = timeLeft.inMinutes + 1;

        Widget nextLessonWidget = SizedBox();

        if (nextLesson != null) {
          nextLessonWidget = Center(
            child: Text(
              "→ ${nextLesson.name}, ${nextLesson.roomName}",
              style: TextStyle(
                color: wearStyle.colors.textPrimary,
                fontSize: 12,
                fontFamily: 'Montserrat',
                fontVariations: [
                  FontVariation('wght', 400),
                ],
              ),
            ),
          );
        }

        body.add(CustomPaint(
            painter: CircularProgressPainter(
                progress: elapsed.inMilliseconds / duration.inMilliseconds,
                screenSize: MediaQuery.of(context).size,
                strokeWidth: 4,
                color: wearStyle.colors.accent),
            child: Column(children: [
              SizedBox(height: nextLesson == null ? 20.h : 0),
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
                  "${currentLesson.name}, ${currentLesson.roomName}",
                  style: TextStyle(
                    color: wearStyle.colors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
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
                    fontVariations: [
                      FontVariation('wght', 400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              nextLessonWidget,
            ])));

        platform.invokeMethod('activity_update');
        return (body, 200.h);
      }
    }

    platform.invokeMethod('activity_cancel');
    throw Exception("unexpected state");
  }

  @override
  Widget build(BuildContext context) {
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
          fontVariations: [
            FontVariation('wght', 500),
          ],
        ),
        placement: Placement.inside,
      );
    }

    return Scaffold(
      backgroundColor: mode == WearMode.active
          ? wearStyle.colors.background
          : wearStyle.colors.backgroundAmoled,
      body: Stack(
        children: [
          Center(
            child: titleBar,
          ),
          Center(
            child: Column(
              children: [
                WatchShape(
                  builder: (context, shape, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        child!,
                      ],
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

                      var (body, padding) = buildBody(context, mode);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(top: padding),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [...body],
                              )),
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    disposed = true;
  }
}
