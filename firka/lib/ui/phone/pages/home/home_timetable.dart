import 'dart:collection';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/ui/phone/widgets/bottom_tt_icon.dart';
import 'package:firka/ui/phone/widgets/tt_day.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/phone/screens/settings/settings_screen.dart';
import 'package:firka/ui/phone/widgets/bubble_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

import 'package:firka_common/core/consts.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/bloc/settings_cubit.dart';
import 'package:firka/ui/shared/firka_icon.dart';

class HomeTimetableScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeTimetableScreen(this.data, {super.key});

  @override
  State<HomeTimetableScreen> createState() => _HomeTimetableScreen();
}

class _HomeTimetableScreen extends FirkaState<HomeTimetableScreen>
    with TickerProviderStateMixin {
  // Original dates list for display
  LinkedHashMap<DateTime, List<LessonCacheModel>> dates =
      LinkedHashMap.identity();

  // Dates list for carousel animation
  List<DateTime> _animationDates = [];
  late DateTime currentMonday;
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

    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    updateWeek(timeNow());
  }

  bool animating = false;

  void _handleNavTap(int oldIndex, int targetIndex) async {
    if (animating) return;
    HapticFeedback.mediumImpact();

    final original = _animationDates;

    // If the target is not adjacent, create temporary order
    int tempTargetIndex = targetIndex;
    if ((targetIndex - oldIndex).abs() > 1) {
      // Determine the temporary target position next to the current position
      tempTargetIndex = oldIndex < targetIndex ? oldIndex + 1 : oldIndex - 1;

      // Create a new order where target day is next to current day
      List<DateTime> reorderedDates = List.from(_animationDates!);
      final targetDate = reorderedDates.removeAt(targetIndex);
      reorderedDates.insert(tempTargetIndex, targetDate);

      setState(() {
        _animationDates = reorderedDates;
        _isTemporaryOrder = true;
      });
    }

    active = -1;

    const double cardWidth = 40.0;
    const double spacing = 16.0;
    final double totalCardWidth = cardWidth + spacing;

    final double start = oldIndex * totalCardWidth;
    final double end = targetIndex * totalCardWidth;

    _cardAnimationController!.reset();
    _cardOffsetAnimation =
        Tween<Offset>(begin: Offset(start, 0), end: Offset(end, 0)).animate(
          CurvedAnimation(
            parent: _cardAnimationController!,
            curve: Curves.easeInOut,
          ),
        );

    setState(() {
      _showAnimatedCard = true;
    });

    _cardAnimationController!.forward();

    animating = true;
    await _controller.animateToPage(
      tempTargetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // After animation, restore the original order if necessary
    if (_isTemporaryOrder) {
      setState(() {
        _animationDates = original; // Restore from original dates
        _isTemporaryOrder = false;
      });

      // Jump to the correct position without animation
      _controller.jumpToPage(targetIndex);
    }

    animating = false;
    setState(() {
      active = targetIndex;
      _showAnimatedCard = false;
    });

    _cardAnimationController!.reset();
  }

  void updateWeek(DateTime monday) {
    currentMonday = monday.getMonday().getMidnight();

    dates.clear();
    for (int i = 0; i < 7; i++) {
      final day = currentMonday.add(Duration(days: i));

      dates[day] = widget.data.client!.cache
          .getTimeTable()
          .on(day)
          .sortByStart()
          .findAllSync();

      if (day.weekday > 5 &&
          dates[day]!.every((l) => l.type == TimetableConsts.event)) {
        dates.remove(day);
      }
    }
    _animationDates = List.from(dates.keys);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (mounted) setState(() {});
      },
      child: BlocListener<HomeRefreshCubit, HomeRefreshState>(
        listenWhen: (previous, current) =>
            current.refreshTrigger != previous.refreshTrigger,
        listener: (context, state) {
          setState(() {});
        },
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    List<Widget> ttWidgets = [];
    List<Widget> ttDays = [];
    final showABTimetable = Settings.ttToastABTimetable.value;
    // Build navigation icons using original dates
    var i = 0;
    for (MapEntry<DateTime, List<LessonCacheModel>> e in dates.entries) {
      var realIndex = i;
      Widget ttWidget = BottomTimeTableNavIconWidget(
        widget.data.l10n,
        () {
          _handleNavTap(active, realIndex);
        },
        active == i,
        e.key,
      );

      if (e.value.any((l) => l.test.loadAndGet() != null)) {
        ttWidgets.add(
          Stack(
            children: [
              ttWidget,
              Transform.translate(offset: Offset(34, -9), child: BubbleTest()),
            ],
          ),
        );
      } else {
        ttWidgets.add(ttWidget);
      }

      i++;
    }

    bool isEvent(LessonCacheModel model) {
      return model.type == TimetableConsts.event;
    }

    // Build carousel pages using animation dates
    for (DateTime date in _animationDates) {
      final lessons = List<LessonCacheModel>.from(dates[date]!)
        ..removeWhere(isEvent);
      final events = List<LessonCacheModel>.from(dates[date]!)
        ..retainWhere(isEvent);
      ttDays.add(TimeTableDayWidget(lessons, events));
    }

    Widget ttAnimatedCard = BottomTimeTableNavIconWidget(
      widget.data.l10n,
      () => {},
      false,
      null,
    );

    if (_cardOffsetAnimation != null && _showAnimatedCard) {
      ttAnimatedCard = AnimatedBuilder(
        animation: _cardOffsetAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: _cardOffsetAnimation!.value,
            child: BottomTimeTableNavIconWidget(
              widget.data.l10n,
              () => {},
              true,
              null,
            ),
          );
        },
      );
    }

    return Stack(
      children: [
        Column(
          children: [
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
                          style: appStyle.fonts.H_H2.apply(
                            color: appStyle.colors.textPrimary,
                          ),
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
                                context.push('/timetable/monthly');
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
                                  timetableToastTree(widget.data.l10n),
                                );
                              },
                            ),
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
                          onTap: () {
                            setState(() {
                              updateWeek(
                                currentMonday.subtract(Duration(days: 7)),
                              );
                            });
                          },
                        ),
                        GestureDetector(
                          child: Row(
                            spacing: 4,
                            children: [
                              Text(
                                currentMonday.format(
                                  widget.data.l10n,
                                  FormatMode.yyyymmddwedd,
                                ),
                                style: appStyle.fonts.B_16R.apply(
                                  color: appStyle.colors.textPrimary,
                                ),
                              ),
                              if (showABTimetable) ...[
                                Text(
                                  "•",
                                  style: appStyle.fonts.B_16R.apply(
                                    color: appStyle.colors.accent,
                                  ),
                                ),
                                Text(
                                  currentMonday.isAWeek()
                                      ? widget.data.l10n.a_week
                                      : widget.data.l10n.b_week,
                                  style: appStyle.fonts.B_16R.apply(
                                    color: appStyle.colors.textPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              updateWeek(timeNow());
                              _controller.jumpToPage(active);
                            });
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
                          onTap: () {
                            setState(() {
                              updateWeek(currentMonday.add(Duration(days: 7)));
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

                      setState(() {
                        active = i;
                      });
                    },
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 2),
              decoration: ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                shadows: [
                  BoxShadow(
                    color: appStyle.colors.background,
                    blurRadius: 36,
                    offset: Offset(0, -27),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  children: [
                    ttAnimatedCard,
                    Wrap(spacing: 16, children: ttWidgets),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
