import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/api/client/kreta_stream.dart';
import 'package:firka/helpers/api/model/test.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/settings.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/screens/settings/settings_screen.dart';
import 'package:firka/ui/phone/widgets/bubble_test.dart';
import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

import '../../../../helpers/api/consts.dart';
import '../../../../helpers/firka_state.dart';
import '../../../../helpers/update_notifier.dart';
import '../../../../main.dart';
import '../../../widget/firka_icon.dart';
import '../../widgets/bottom_tt_icon.dart';
import '../../widgets/tt_day.dart';

class HomeTimetableScreen extends StatefulWidget {
  final AppInitialization data;
  final UpdateNotifier updateNotifier;
  final UpdateNotifier finishNotifier;
  final void Function(int) pageController;

  const HomeTimetableScreen(
      this.data, this.updateNotifier, this.finishNotifier, this.pageController,
      {super.key});

  @override
  State<HomeTimetableScreen> createState() => _HomeTimetableScreen();
}

class _HomeTimetableScreen extends FirkaState<HomeTimetableScreen>
    with TickerProviderStateMixin {
  List<Lesson>? lessons;
  List<Lesson>? events;
  List<Test>? tests;

  // Original dates list for display
  List<DateTime>? dates;

  // Dates list for carousel animation
  List<DateTime>? _animationDates;
  DateTime? now;
  int active = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  AnimationController? _cardAnimationController;
  Animation<Offset>? _cardOffsetAnimation;
  bool _showAnimatedCard = false;

  // Flag to track if we're using temporary order
  bool _isTemporaryOrder = false;

  _HomeTimetableScreen();

  @override
  void initState() {
    super.initState();

    widget.updateNotifier.addListener(updateListener);
    widget.data.settingsUpdateNotifier.addListener(settingsUpdateListener);

    now = timeNow();
    initForWeek(now!);

    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void setActiveToToday() {
    final todayMid = now!.getMidnight();
    int idx = dates!.indexWhere((d) =>
        d.year == todayMid.year &&
        d.month == todayMid.month &&
        d.day == todayMid.day);

    if (idx >= 0) {
      final todaysLessons = lessons?.where((lesson) =>
          lesson.start.isAfter(todayMid) &&
          lesson.end.isBefore(todayMid.add(Duration(hours: 23, minutes: 59))));

      if (todaysLessons != null && todaysLessons.isNotEmpty) {
        final lastLessonToday =
            todaysLessons.reduce((a, b) => a.end.isAfter(b.end) ? a : b);

        if (now!.isAfter(lastLessonToday.end)) {
          int nextIdx = idx + 1;
          if (nextIdx < dates!.length) {
            active = nextIdx;
          } else {
            active = idx;
          }
        } else {
          active = idx;
        }
      } else {
        active = idx;
      }
    } else if (now!.isAfter(dates!.last)) {
      active = dates!.length - 1;
    } else {
      idx = dates!.indexWhere((d) => d.isAfter(todayMid));
      active = idx >= 0 ? idx : 0;
    }
  }

  Future<void> maybeCacheNextWeek(int active) async {
    DateTime monday = now!.getMonday().getMidnight();
    if (active >= 3) {
      // thursday
      monday = monday.add(Duration(days: 14));
    } else {
      return;
    }
    if (timeNow().add(Duration(days: 31)).isBefore(monday)) return;
    logger.finest("caching next week for $monday");
    var sunday = monday.add(Duration(days: 6));
    await widget.data.client.getTimeTable(monday, sunday);
    await widget.data.client.getTests();
  }

  Future<void> maybeCachePreviousWeek(int active) async {
    DateTime monday = now!.getMonday().getMidnight();
    if (active <= 2) {
      // wednesday
      monday = monday.subtract(Duration(days: 7));
    } else {
      return;
    }
    if (timeNow().subtract(Duration(days: 120)).isAfter(monday)) return;
    logger.finest("caching previous week for $monday");
    var sunday = monday.add(Duration(days: 6));
    await widget.data.client.getTimeTable(monday, sunday);
    await widget.data.client.getTests();
  }

  Future<void> _updateState(DateTime now, ApiResponse<List<Lesson>> lessonsResp,
      ApiResponse<List<Test>> testsResp) async {
    var monday = now.getMonday().getMidnight();

    List<DateTime> dates = List.empty(growable: true);

    if (lessonsResp.response != null) {
      lessons = lessonsResp.response
          ?.where((lesson) => lesson.type.name != TimetableConsts.event)
          .toList();
      events = lessonsResp.response
          ?.where((lesson) => lesson.type.name == TimetableConsts.event)
          .toList();
      tests = testsResp.response;

      for (var i = 0; i < 7; i++) {
        var t = monday.add(Duration(days: i));

        var hasLessons = i < 5 ||
            lessons!.firstWhereOrNull((lesson) {
                  return lesson.start.getMidnight().millisecondsSinceEpoch ==
                      t.getMidnight().millisecondsSinceEpoch;
                }) !=
                null;

        if (hasLessons) {
          dates.add(t);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      this.dates = dates;
      _animationDates = List.from(dates);
      _isTemporaryOrder = false;

      if (now.getMonday().getMidnight().millisecondsSinceEpoch ==
          timeNow().getMonday().getMidnight().millisecondsSinceEpoch) {
        setActiveToToday();
      } else {
        active = 0;
      }
    });
  }

  Future<void> initForWeek(DateTime now, {bool forceCache = true}) async {
    var monday = now.getMonday().getMidnight();
    var sunday = monday.add(Duration(days: 6));

    ApiResponse<List<Lesson>>? lessonsResp;
    var lessonsFetched = 0;
    ApiResponse<List<Test>>? testsResp;
    var testsFetched = 0;

    widget.data.client
        .getTimeTableStream(monday, sunday, cacheOnly: forceCache)
        .forEach((lessons) {
      lessonsResp = lessons;
      lessonsFetched++;
    });

    widget.data.client.getTestsStream(cacheOnly: forceCache).forEach((tests) {
      testsResp = tests;
      testsFetched++;
    });

    while (lessonsFetched < 1 || testsFetched < 1) {
      await Future.delayed(Duration(milliseconds: 50));
    }
    await _updateState(now, lessonsResp!, testsResp!);
    while (lessonsFetched < 2 || testsFetched < 2) {
      await Future.delayed(Duration(milliseconds: 50));
    }
    await _updateState(now, lessonsResp!, testsResp!);
  }

  void updateListener() async {
    if (now != null) {
      await initForWeek(now!, forceCache: false);
      if (mounted) setState(() {});
    }
    widget.finishNotifier.update();
  }

  void settingsUpdateListener() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(HomeTimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.updateNotifier.removeListener(updateListener);
    widget.updateNotifier.addListener(updateListener);

    widget.data.settingsUpdateNotifier.removeListener(settingsUpdateListener);
    widget.data.settingsUpdateNotifier.addListener(settingsUpdateListener);
  }

  bool animating = false;

  void _handleNavTap(int oldIndex, int targetIndex) async {
    if (animating) return;
    HapticFeedback.mediumImpact();

    // Save the real target index
    final realTargetIndex = targetIndex;

    maybeCacheNextWeek(realTargetIndex);
    maybeCachePreviousWeek(realTargetIndex);

    // If the target is not adjacent, create temporary order
    if ((targetIndex - oldIndex).abs() > 1) {
      // Determine the temporary target position next to the current position
      int tempTargetIndex =
          oldIndex < targetIndex ? oldIndex + 1 : oldIndex - 1;

      // Create a new order where target day is next to current day
      List<DateTime> reorderedDates = List.from(_animationDates!);
      final targetDate = reorderedDates.removeAt(targetIndex);
      reorderedDates.insert(tempTargetIndex, targetDate);

      setState(() {
        _animationDates = reorderedDates;
        _isTemporaryOrder = true;
        targetIndex = tempTargetIndex; // Update target for animation
      });
    }

    active = -1;

    const double cardWidth = 40.0;
    const double spacing = 8.0;
    final double totalCardWidth = cardWidth + spacing;

    // Calculate animation positions based on real display indices
    final oldDisplayIndex = dates!.indexOf(_animationDates![oldIndex]);
    final targetDisplayIndex = dates!.indexOf(_animationDates![targetIndex]);

    final double start = oldDisplayIndex * totalCardWidth;
    final double end = targetDisplayIndex * totalCardWidth;

    _cardAnimationController!.reset();
    _cardOffsetAnimation = Tween<Offset>(
      begin: Offset(start, 0),
      end: Offset(end, 0),
    ).animate(CurvedAnimation(
      parent: _cardAnimationController!,
      curve: Curves.easeInOut,
    ));

    setState(() {
      _showAnimatedCard = true;
    });

    _cardAnimationController!.forward();

    animating = true;
    await _controller.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // After animation, restore the original order if necessary
    if (_isTemporaryOrder) {
      // Calculate the real display index for the target
      final displayIndex = dates!.indexOf(_animationDates![targetIndex]);

      setState(() {
        _animationDates = List.from(dates!); // Restore from original dates
        _isTemporaryOrder = false;
        active = displayIndex; // Use the display index
      });

      // Jump to the correct position without animation
      _controller.jumpToPage(displayIndex);
    } else {
      final displayIndex = dates!.indexOf(_animationDates![targetIndex]);
      setState(() {
        active = displayIndex; // Use the display index
      });
    }

    animating = false;
    setState(() {
      _showAnimatedCard = false;
    });

    _cardAnimationController!.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (lessons != null && tests != null && events != null && dates != null) {
      List<Widget> ttWidgets = [];
      List<Widget> ttDays = [];

      // Build navigation icons using original dates
      for (var i = 0; i < dates!.length; i++) {
        final date = dates![i];
        final realIndex = i; // Always use real index for nav icons

        final testsOnDate = tests!
            .where((test) =>
                test.date.isAfter(date.subtract(Duration(seconds: 1))) &&
                test.date.isBefore(date.add(Duration(hours: 23, minutes: 59))))
            .toList();

        if (testsOnDate.isNotEmpty) {
          ttWidgets.add(Stack(
            children: [
              BottomTimeTableNavIconWidget(widget.data.l10n, () {
                _handleNavTap(active, realIndex);
              }, active == i, date),
              Transform.translate(
                offset: Offset(38, -10),
                child: BubbleTest(),
              ),
            ],
          ));
        } else {
          ttWidgets.add(BottomTimeTableNavIconWidget(widget.data.l10n, () {
            _handleNavTap(active, realIndex);
          }, active == i, date));
        }
      }

      // Build carousel pages using animation dates
      for (var i = 0; i < _animationDates!.length; i++) {
        final date = _animationDates![i];

        final lessonsOnDate = lessons!
            .where((lesson) =>
                lesson.start.isAfter(date) &&
                lesson.end.isBefore(date.add(Duration(hours: 24))))
            .toList();
        final eventsOnDate = events!
            .where((lesson) =>
                lesson.start.isAfter(date.subtract(Duration(seconds: 1))) &&
                lesson.end.isBefore(date.add(Duration(hours: 23, minutes: 59))))
            .toList();
        final testsOnDate = tests!
            .where((test) =>
                test.date.isAfter(date.subtract(Duration(seconds: 1))) &&
                test.date.isBefore(date.add(Duration(hours: 23, minutes: 59))))
            .toList();

        ttDays.add(TimeTableDayWidget(widget.data, date, lessons!,
            lessonsOnDate, eventsOnDate, testsOnDate));
      }

      List<Widget> ttEmptyCards = List.empty(growable: true);

      if (animating || _showAnimatedCard) {
        for (var i = 0; i < ttDays.length; i++) {
          if (i == 0) {
            Widget cardWidget = Card(
              color: appStyle.colors.buttonSecondaryFill,
              shadowColor: Colors.transparent,
              child: SizedBox(width: 40, height: 54),
            );

            if (_showAnimatedCard && _cardOffsetAnimation != null) {
              ttEmptyCards.add(AnimatedBuilder(
                animation: _cardOffsetAnimation!,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _cardOffsetAnimation!.value,
                    child: cardWidget,
                  );
                },
              ));
            } else {
              ttEmptyCards.add(Transform.translate(
                offset: Offset(0, 0),
                child: cardWidget,
              ));
            }
          } else {
            ttEmptyCards.add(Card(
              color: Colors.transparent,
              shadowColor: Colors.transparent,
              child: SizedBox(width: 40, height: 54),
            ));
          }
        }
      } else {
        ttEmptyCards.clear();
      }

      return Stack(children: [
        Column(children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 74 + 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.data.l10n.timetable,
                        style: appStyle.fonts.H_H2
                            .apply(color: appStyle.colors.textPrimary),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            child: Card(
                              color: appStyle.colors.buttonSecondaryFill,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: FirkaIconWidget(
                                  FirkaIconType.majesticons,
                                  Majesticon.tableSolid,
                                  size: 26.0,
                                  color: appStyle.colors.accent,
                                ),
                              ),
                            ),
                            onTap: () {
                              widget.pageController(1);
                            },
                          ),
                          /* TODO: 1.1.0

                        Card(
                          color: appStyle.colors.buttonSecondaryFill,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: FirkaIconWidget(
                              FirkaIconType.majesticons,
                              Majesticon.plusLine,
                              size: 32.0,
                              color: appStyle.colors.accent,
                            ),
                          ),
                        ),
                        */
                          GestureDetector(
                            child: Card(
                              color: appStyle.colors.buttonSecondaryFill,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: FirkaIconWidget(
                                  FirkaIconType.majesticons,
                                  Majesticon.settingsCogSolid,
                                  size: 26.0,
                                  color: appStyle.colors.accent,
                                ),
                              ),
                            ),
                            onTap: () {
                              showSettingsSheet(
                                  context,
                                  MediaQuery.of(context).size.height * 0.4,
                                  widget.data,
                                  widget.data.settings
                                      .group("settings")
                                      .subGroup("timetable_toast"));
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: FirkaIconWidget(
                            FirkaIconType.icons,
                            "dropdownLeft",
                            size: 24,
                            color: appStyle.colors.accent,
                          ),
                        ),
                        onTap: () async {
                          var newNow = now!.subtract(Duration(days: 7));
                          if (!mounted) return;
                          setState(() {
                            now = newNow;
                            lessons = null;
                            dates = null;
                          });
                          await initForWeek(newNow);
                          setState(() {
                            now = newNow;
                          });
                        },
                      ),
                      GestureDetector(
                        child: Row(
                          children: [
                            Text(
                                now!.format(
                                    widget.data.l10n, FormatMode.yyyymmddwedd),
                                style: appStyle.fonts.B_16R
                                    .apply(color: appStyle.colors.textPrimary)),
                            SizedBox(width: 4),
                            Text("•",
                                style: appStyle.fonts.B_16R
                                    .apply(color: appStyle.colors.accent)),
                            SizedBox(width: 4),
                            Text(
                                now!.isAWeek()
                                    ? widget.data.l10n.a_week
                                    : widget.data.l10n.b_week,
                                style: appStyle.fonts.B_16R
                                    .apply(color: appStyle.colors.textPrimary)),
                          ],
                        ),
                        onTap: () {
                          now = timeNow();
                          setActiveToToday();
                          _controller.jumpToPage(active);
                        },
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: FirkaIconWidget(
                            FirkaIconType.icons,
                            "dropdownRight",
                            size: 24,
                            color: appStyle.colors.accent,
                          ),
                        ),
                        onTap: () async {
                          var newNow = now!.add(Duration(days: 7));
                          if (!mounted) return;
                          setState(() {
                            now = newNow;
                            lessons = null;
                            dates = null;
                          });
                          await initForWeek(newNow);
                          setState(() {
                            now = newNow;
                          });
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ]),
        Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Expanded(
              child: TransparentPointer(
                  child: CarouselSlider(
            items: ttDays,
            carouselController: _controller,
            options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1,
                enableInfiniteScroll: false,
                initialPage: active,
                onPageChanged: (i, _) {
                  if (animating || !mounted) return;

                  HapticFeedback.mediumImpact();

                  // Convert animation index to display index
                  final displayIndex = dates!.indexOf(_animationDates![i]);
                  maybeCacheNextWeek(displayIndex);
                  maybeCachePreviousWeek(displayIndex);
                  setState(() {
                    active = displayIndex;
                  });
                }),
          ))),
          Container(
              padding: EdgeInsets.only(bottom: 12),
              decoration: ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                shadows: [
                  BoxShadow(
                      color: appStyle.colors.background,
                      blurRadius: 30,
                      spreadRadius: 20,
                      offset: Offset(0, -25)),
                ],
              ),
              child: Stack(
                children: [
                  Wrap(
                    spacing: 10,
                    children: ttEmptyCards,
                  ),
                  Wrap(
                    spacing: 10,
                    children: ttWidgets,
                  ),
                ],
              )),
        ])
      ]);
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [DelayedSpinnerWidget()],
          )
        ],
      );
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.updateNotifier.removeListener(updateListener);
    widget.data.settingsUpdateNotifier.removeListener(settingsUpdateListener);
  }
}
