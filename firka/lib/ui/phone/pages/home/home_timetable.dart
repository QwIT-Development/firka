import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/settings/setting.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/screens/settings/settings_screen.dart';
import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

import '../../../../helpers/api/consts.dart';
import '../../../../helpers/update_notifier.dart';
import '../../../../main.dart';
import '../../../widget/firka_icon.dart';
import '../../screens/home/home_screen.dart';
import '../../widgets/bottom_tt_icon.dart';
import '../../widgets/tt_day.dart';

class HomeTimetableScreen extends StatefulWidget {
  final AppInitialization data;
  final UpdateNotifier updateNotifier;
  final UpdateNotifier finishNotifier;

  final void Function(ActiveHomePage, bool) cb;

  const HomeTimetableScreen(
      this.data, this.updateNotifier, this.finishNotifier, this.cb,
      {super.key});

  @override
  State<HomeTimetableScreen> createState() => _HomeTimetableScreen();
}

class _HomeTimetableScreen extends State<HomeTimetableScreen> {
  List<Lesson>? lessons;
  List<Lesson>? events;
  List<DateTime>? dates;
  DateTime? now;
  int active = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  _HomeTimetableScreen();

  Future<void> initForWeek(DateTime now, {bool forceCache = true}) async {
    var monday = now.getMonday().getMidnight();
    var sunday = monday.add(Duration(days: 6));

    var lessonsResp = await widget.data.client
        .getTimeTable(monday, sunday, forceCache: forceCache);
    List<DateTime> dates = List.empty(growable: true);

    if (lessonsResp.response != null) {
      lessons = lessonsResp.response
          ?.where((lesson) => lesson.type.name != TimetableConsts.event)
          .toList();
      events = lessonsResp.response
          ?.where((lesson) => lesson.type.name == TimetableConsts.event)
          .toList();

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
      if (now.isAfter(dates.last)) {
        active = dates.length - 1;
      } else {
        active = dates.indexWhere((d) =>
            d.isAfter(now.getMidnight()) &&
            d.isBefore(
                now.getMidnight().add(Duration(hours: 23, minutes: 59))));
      }
    });
  }

  void updateListener() async {
    if (now != null) {
      await initForWeek(now!, forceCache: false);
      setState(() {});
    }
    widget.finishNotifier.update();
  }

  void settingsUpdateListener() {
    setState(() {});
  }

  @override
  void didUpdateWidget(HomeTimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.updateNotifier.removeListener(updateListener);
    widget.updateNotifier.addListener(updateListener);

    widget.data.settingsUpdateNotifier.removeListener(settingsUpdateListener);
    widget.data.settingsUpdateNotifier.addListener(settingsUpdateListener);
  }

  @override
  void initState() {
    super.initState();

    widget.updateNotifier.addListener(updateListener);
    widget.data.settingsUpdateNotifier.addListener(settingsUpdateListener);

    now = timeNow();
    initForWeek(now!);
  }

  @override
  void dispose() {
    super.dispose();

    widget.updateNotifier.removeListener(updateListener);
    widget.data.settingsUpdateNotifier.removeListener(settingsUpdateListener);
  }

  @override
  Widget build(BuildContext context) {
    if (lessons != null && events != null && dates != null) {
      List<Widget> ttWidgets = [];
      List<Widget> ttDays = [];

      for (var i = 0; i < dates!.length; i++) {
        final date = dates![i];

        ttWidgets.add(BottomTimeTableNavIconWidget(widget.data.l10n, () {
          setState(() {
            _controller.jumpToPage(i);
            active = i;
          });
        }, active == i, date));

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

        ttDays.add(
            TimeTableDayWidget(widget.data, date, lessonsOnDate, eventsOnDate));
      }

      return Stack(children: [
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
                            widget.cb(
                                ActiveHomePage(HomePages.timetableMo), false);
                          },
                        ),
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
                    Row(
                      children: [
                        Text(
                            now!.format(
                                widget.data.l10n, FormatMode.yyyymmddwedd),
                            style: appStyle.fonts.B_14R),
                        SizedBox(width: 4),
                        Text("•",
                            style: appStyle.fonts.B_16R
                                .apply(color: appStyle.colors.accent)),
                        SizedBox(width: 4),
                        Text(
                            now!.isAWeek()
                                ? widget.data.l10n.a_week
                                : widget.data.l10n.b_week,
                            style: appStyle.fonts.B_14R),
                      ],
                    ),
                    GestureDetector(
                      child: FirkaIconWidget(
                        FirkaIconType.icons,
                        "dropdownRight",
                        size: 24,
                        color: appStyle.colors.accent,
                      ),
                      onTap: () async {
                        var newNow = now!.add(Duration(days: 7));
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
        Column(
          children: [
            TransparentPointer(
                child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 1.4,
                    child: CarouselSlider(
                      items: ttDays,
                      carouselController: _controller,
                      options: CarouselOptions(
                          height: MediaQuery.of(context).size.height / 1.36,
                          viewportFraction: 1,
                          enableInfiniteScroll: false,
                          initialPage: active,
                          onPageChanged: (i, _) {
                            setState(() {
                              active = i;
                            });
                          }),
                    ))),
            TransparentPointer(
                child: Row(
              children: ttWidgets,
            )),
          ],
        )
      ]);
    } else {
      return SizedBox(
        height: MediaQuery.of(context).size.height / 1.35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            DelayedSpinnerWidget(),
            SizedBox(),
          ],
        ),
      );
    }
  }
}
