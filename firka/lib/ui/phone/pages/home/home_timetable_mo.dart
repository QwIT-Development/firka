import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:transparent_pointer/transparent_pointer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../main.dart';
import '../../../widget/firka_icon.dart';
import '../../screens/home/home_screen.dart';

class HomeTimetableMonthlyScreen extends StatefulWidget {
  final AppInitialization data;
  final void Function(ActiveHomePage, bool) cb;

  const HomeTimetableMonthlyScreen(this.data, this.cb, {super.key});

  @override
  State<HomeTimetableMonthlyScreen> createState() =>
      _HomeTimetableMonthlyScreen();
}

class _HomeTimetableMonthlyScreen extends State<HomeTimetableMonthlyScreen> {
  List<Lesson>? lessons;
  List<DateTime>? dates;
  DateTime? now;
  int active = 0;
  bool disposed = false;

  _HomeTimetableMonthlyScreen();

  @override
  void dispose() {
    super.dispose();

    disposed = true;
  }

  Future<void> initForMonth(DateTime now) async {
    final monthStart = DateTime.utc(now.year, now.month, 1);
    final monthEnd =
        DateTime.utc(now.year, now.month + 1).subtract(Duration(days: 1));

    final start = monthStart.subtract(Duration(days: 7)).getMonday();
    var end =
        monthEnd.add(Duration(days: 7)).getMonday().add(Duration(days: 7));

    var days = end.difference(start).inDays;

    var lessonsResp =
        await widget.data.client.getTimeTable(monthStart, monthEnd);
    List<DateTime> dates = List.empty(growable: true);

    for (var i = 0; i < days; i++) {
      dates.add(start.add(Duration(days: i)));
    }

    if (lessonsResp.response != null) {
      lessons = lessonsResp.response;
    }

    if (disposed) return;
    setState(() {
      this.dates = dates;
    });
  }

  @override
  void initState() {
    super.initState();

    now = timeNow();
    initForMonth(now!);
  }

  @override
  Widget build(BuildContext context) {
    if (lessons != null && dates != null) {
      List<Widget> ttDays = [];

      final meow = dates![20];
      final currentMonthStart = DateTime.utc(meow.year, meow.month, 1);
      final currentMonthEnd =
          DateTime.utc(meow.year, meow.month + 1).subtract(Duration(days: 1));

      for (var d in dates!) {
        if (d.isBefore(currentMonthStart) || d.isAfter(currentMonthEnd)) {
          ttDays.add(Column(
            children: [
              Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: appStyle.colors.cardTranslucent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  )),
              SizedBox(height: 4),
              Text(d.format(widget.data.l10n, FormatMode.dd),
                  style: appStyle.fonts.B_14R.apply(
                      color: (d.weekday == DateTime.saturday ||
                              d.weekday == DateTime.sunday)
                          ? appStyle.colors.errorText
                          : appStyle.colors.textTertiary)),
              SizedBox(height: 12),
            ],
          ));
        } else {
          Widget body = SizedBox();

          var lessonsToday = lessons!.where((lesson) =>
              lesson.start.isAfter(d.getMidnight()) &&
              lesson.end.isBefore(
                  d.getMidnight().add(Duration(hours: 23, minutes: 59))));

          if (lessonsToday.isNotEmpty) {
            body = Center(
              child: Text(lessonsToday.length.toString(),
                  style: appStyle.fonts.H_16px
                      .apply(color: appStyle.colors.secondary)),
            );
          }
          ttDays.add(Column(
            children: [
              Container(
                width: 40,
                height: 40,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: appStyle.colors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: body,
              ),
              SizedBox(height: 4),
              Text(d.format(widget.data.l10n, FormatMode.dd),
                  style: appStyle.fonts.B_14R.apply(
                      color: (d.weekday == DateTime.saturday ||
                                  d.weekday == DateTime.sunday) &&
                              lessonsToday.isEmpty
                          ? appStyle.colors.errorText
                          : appStyle.colors.textSecondary)),
              SizedBox(height: 12),
            ],
          ));
        }
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
                                ActiveHomePage(HomePages.timetable), false);
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
                        Card(
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
                        var newNow = now!.subtract(Duration(days: 30));
                        setState(() {
                          now = newNow;
                          lessons = null;
                          dates = null;
                        });
                        await initForMonth(newNow);
                        setState(() {
                          now = newNow;
                        });
                      },
                    ),
                    Text(
                        now!
                            .format(widget.data.l10n, FormatMode.yyyymmmm)
                            .toLowerCase(),
                        style: appStyle.fonts.B_14R),
                    GestureDetector(
                      child: FirkaIconWidget(
                        FirkaIconType.icons,
                        "dropdownRight",
                        size: 24,
                        color: appStyle.colors.accent,
                      ),
                      onTap: () async {
                        var newNow = now!.add(Duration(days: 30));
                        setState(() {
                          now = newNow;
                          lessons = null;
                          dates = null;
                        });
                        await initForMonth(newNow);
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
        TransparentPointer(
            child: Padding(
          padding: const EdgeInsets.only(top: 74 + 16 + 12),
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 1.45,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StaggeredGrid.count(
                  crossAxisCount: 7,
                  children: ttDays,
                ),
              )),
        )),
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
