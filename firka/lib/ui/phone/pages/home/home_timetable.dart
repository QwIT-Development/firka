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
  static const int _originIndex = 100000;

  final Map<DateTime, List<LessonCacheModel>> _lessonsCache = {};
  final Map<int, DateTime> _indexToDate = {};

  final PageController _pageController = PageController(
    initialPage: _originIndex,
  );

  int _activePageIndex = _originIndex;
  late DateTime _currentTabWeekMonday;
  late List<DateTime> _tabDays;

  bool animating = false;

  _HomeTimetableScreen();

  @override
  void initState() {
    super.initState();

    var today = timeNow().getMidnight();
    var anchor = today;
    while (!_isDayVisible(anchor)) {
      anchor = anchor.add(Duration(days: 1));
    }
    _indexToDate[_originIndex] = anchor;

    _currentTabWeekMonday = _activeWeekMonday;
    _tabDays = _visibleDaysOfWeek(_currentTabWeekMonday);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime get _activeDay => _dateForIndex(_activePageIndex);

  DateTime get _activeWeekMonday => _activeDay.getMonday().getMidnight();

  List<LessonCacheModel> _lessonsFor(DateTime day) {
    return _lessonsCache.putIfAbsent(
      day,
      () => widget.data.client!.cache
          .getTimeTable()
          .on(day)
          .sortByStart()
          .findAllSync(),
    );
  }

  bool _isDayVisible(DateTime day) {
    if (day.weekday <= 5) return true;
    return _lessonsFor(day).any((l) => l.type != TimetableConsts.event);
  }

  List<DateTime> _visibleDaysOfWeek(DateTime monday) {
    return [
      for (int i = 0; i < 7; i++)
        if (_isDayVisible(monday.add(Duration(days: i))))
          monday.add(Duration(days: i)),
    ];
  }

  DateTime _dateForIndex(int index) {
    final cached = _indexToDate[index];
    if (cached != null) return cached;

    var nearest = _indexToDate.keys.reduce(
      (a, b) => (a - index).abs() < (b - index).abs() ? a : b,
    );
    var date = _indexToDate[nearest]!;
    final dir = index > nearest ? 1 : -1;
    var i = nearest;
    while (i != index) {
      date = date.add(Duration(days: dir));
      if (_isDayVisible(date)) i += dir;
    }

    _indexToDate[index] = date;
    return date;
  }

  int _indexForDate(DateTime day) {
    day = day.getMidnight();

    var nearest = _indexToDate.entries.reduce(
      (a, b) =>
          (a.value.difference(day)).abs() < (b.value.difference(day)).abs()
          ? a
          : b,
    );
    var index = nearest.key;
    var date = nearest.value;
    final dir = day.isAfter(date) ? 1 : -1;
    while (!date.isAtSameMomentAs(day)) {
      date = date.add(Duration(days: dir));
      if (_isDayVisible(date)) index += dir;
    }

    _indexToDate[index] = date;
    return index;
  }

  void _goToDay(DateTime day, {bool animate = true}) async {
    if (animating) return;
    HapticFeedback.mediumImpact();

    final targetIndex = _indexForDate(day);
    if (targetIndex == _activePageIndex) return;

    if (!animate) {
      _pageController.jumpToPage(targetIndex);
      return;
    }

    animating = true;
    await _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    animating = false;
  }

  void _onPageChanged(int index) {
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _activePageIndex = index;
      final weekMonday = _activeWeekMonday;
      if (!weekMonday.isAtSameMomentAs(_currentTabWeekMonday)) {
        _currentTabWeekMonday = weekMonday;
        _tabDays = _visibleDaysOfWeek(weekMonday);
      }
    });
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
          _lessonsCache.clear();
          setState(() {});
        },
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    List<Widget> ttWidgets = [];
    final showABTimetable = Settings.ttToastABTimetable.value;
    final activeDay = _activeDay;

    for (DateTime day in _tabDays) {
      Widget ttWidget = BottomTimeTableNavIconWidget(
        widget.data.l10n,
        () {
          _goToDay(day);
        },
        day.isAtSameMomentAs(activeDay),
        day,
      );

      if (_lessonsFor(day).any((l) => l.test.loadAndGet() != null)) {
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
    }

    bool isEvent(LessonCacheModel model) {
      return model.type == TimetableConsts.event;
    }

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final day = _dateForIndex(index);
                  final lessons = List<LessonCacheModel>.from(
                    _lessonsFor(day),
                  )..removeWhere(isEvent);
                  final events = List<LessonCacheModel>.from(_lessonsFor(day))
                    ..retainWhere(isEvent);
                  return TimeTableDayWidget(
                    lessons,
                    events,
                    onRefresh: () => widget.data.client!.pullRefresh(
                      () => widget.data.client!.getLessonsCovering(
                        _currentTabWeekMonday,
                        _currentTabWeekMonday.add(const Duration(days: 7)),
                      ),
                    ),
                  );
                },
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
                child: Wrap(spacing: 16, children: ttWidgets),
              ),
            ),
          ],
        ),
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
                            final targetMonday = _currentTabWeekMonday
                                .subtract(Duration(days: 7));
                            final offset = _activeDay
                                .difference(_currentTabWeekMonday)
                                .inDays;
                            var target = targetMonday.add(
                              Duration(days: offset),
                            );
                            if (!_isDayVisible(target)) {
                              target = _visibleDaysOfWeek(targetMonday).first;
                            }
                            _goToDay(target, animate: false);
                          },
                        ),
                        GestureDetector(
                          child: Row(
                            spacing: 4,
                            children: [
                              Text(
                                _currentTabWeekMonday.format(
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
                                  _currentTabWeekMonday.isAWeek()
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
                            var today = timeNow().getMidnight();
                            while (!_isDayVisible(today)) {
                              today = today.add(Duration(days: 1));
                            }
                            _goToDay(today, animate: false);
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
                            final targetMonday = _currentTabWeekMonday.add(
                              Duration(days: 7),
                            );
                            final offset = _activeDay
                                .difference(_currentTabWeekMonday)
                                .inDays;
                            var target = targetMonday.add(
                              Duration(days: offset),
                            );
                            if (!_isDayVisible(target)) {
                              target = _visibleDaysOfWeek(targetMonday).first;
                            }
                            _goToDay(target, animate: false);
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
      ],
    );
  }
}
