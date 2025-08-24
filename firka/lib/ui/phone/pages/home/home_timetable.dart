import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../../main.dart';
import '../../../widget/firka_icon.dart';
import '../../widgets/bottom_tt_icon.dart';
import '../../widgets/tt_day.dart';

class HomeTimetableScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeTimetableScreen(this.data, {super.key});

  @override
  State<HomeTimetableScreen> createState() => _HomeTimetableScreen();
}

class _HomeTimetableScreen extends State<HomeTimetableScreen> {
  List<Lesson>? lessons;
  List<DateTime>? dates;
  int active = 0;
  bool disposed = false;
  final CarouselSliderController _controller = CarouselSliderController();

  _HomeTimetableScreen();

  @override
  void dispose() {
    super.dispose();

    disposed = true;
  }

  @override
  void initState() {
    super.initState();

    var monday = timeNow().getMonday().getMidnight();
    var sunday = monday.add(Duration(days: 6));

    (() async {
      var lessonsResp = await widget.data.client.getTimeTable(monday, sunday);
      List<DateTime> dates = List.empty(growable: true);

      if (lessonsResp.response != null) {
        lessons = lessonsResp.response;

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

      if (disposed) return;
      setState(() {
        this.dates = dates;
        if (timeNow().isAfter(dates.last)) {
          active = dates.length - 1;
        } else {
          active = dates.indexWhere((d) =>
              d.isAfter(timeNow().getMidnight()) &&
              d.isBefore(timeNow()
                  .getMidnight()
                  .add(Duration(hours: 23, minutes: 59))));
        }
      });
    })();
  }

  @override
  Widget build(BuildContext context) {
    if (lessons != null && dates != null) {
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

        var lessonsOnDate = lessons!
            .where((lesson) =>
                lesson.start.isAfter(date) &&
                lesson.end.isBefore(date.add(Duration(hours: 24))))
            .toList();

        ttDays.add(TimeTableDayWidget(
            widget.data.l10n, date, lessonsOnDate, active == i));
      }

      return Stack(children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 50,
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
                        Card(
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
              ],
            ),
          ),
        ),
        Column(
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 1.4,
                child: CarouselSlider(
                  items: ttDays,
                  carouselController: _controller,
                  options: CarouselOptions(
                      height: MediaQuery.of(context).size.height / 1.36,
                      enableInfiniteScroll: false,
                      initialPage: active,
                      onPageChanged: (i, _) {
                        setState(() {
                          active = i;
                        });
                      }),
                )),
            Row(
              children: ttWidgets,
            ),
          ],
        )
      ]);
    } else {
      return DelayedSpinnerWidget();
    }
  }
}
