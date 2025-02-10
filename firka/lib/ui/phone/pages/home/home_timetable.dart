import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/widgets/bottom_tt_icon.dart';
import 'package:firka/ui/phone/widgets/lesson.dart';
import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../../main.dart';

class HomeTimetableScreen extends StatefulWidget {
  final AppInitialization data;
  const HomeTimetableScreen(this.data, {super.key});

  @override
  State<HomeTimetableScreen> createState() => _HomeTimetableScreen(data);
}

class _HomeTimetableScreen extends State<HomeTimetableScreen> {
  final AppInitialization data;
  List<Lesson>? lessons;
  List<DateTime>? dates;
  DateTime? active;
  _HomeTimetableScreen(this.data);

  @override
  void initState() {
    super.initState();

    var monday = timeNow().getMonday().getMidnight();
    var sunday = monday.add(Duration(days: 6));

    (() async {
      var lessonsResp = await data.client.getTimeTable(monday, sunday);
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

      setState(() {
        this.dates = dates;
        if (timeNow().isAfter(dates.last)) {
          active = dates.last;
        } else {
          active = timeNow().getMidnight();
        }
      });
    })();
  }

  @override
  Widget build(BuildContext context) {
    if (lessons != null && dates != null && active != null) {
      List<Widget> ttWidgets = List.empty(growable: true);
      var lessonsToday = lessons!
          .where((lesson) =>
              lesson.start.isAfter(active!) &&
              lesson.end.isBefore(active!.add(Duration(hours: 24))))
          .toList();

      for (final date in dates!) {
        ttWidgets.add(BottomTimeTableNavIconWidget(() {
          setState(() {
            active = date;
          });
        }, date.millisecondsSinceEpoch == active!.millisecondsSinceEpoch,
            date));
      }

      Widget noLessonsWidget = SizedBox();
      List<Widget> ttBody = List.empty(growable: true);

      if (lessonsToday.isEmpty) {
        noLessonsWidget = Positioned.fill(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/images/logos/dave.svg",
                    width: 48, height: 48),
                SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.tt_no_classes_l1),
                Text(AppLocalizations.of(context)!.tt_no_classes_l2)
              ]),
        );
      } else {
        for (var i = 0; i < lessonsToday.length; i++) {
          var lesson = lessonsToday[i];
          Lesson? nextLesson =
              lessonsToday.length > i + 1 ? lessonsToday[i + 1] : null;
          ttBody.add(LessonWidget(
              lessonsToday.getLessonNo(lesson), lesson, nextLesson));
        }
      }

      return Expanded(
          child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 16.0,
              left: 32.0,
              right: 16.0,
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.timetable,
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
                            FirkaIconType.Majesticons,
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
                            FirkaIconType.Majesticons,
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
                            FirkaIconType.Majesticons,
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
            ]),
          ),
          noLessonsWidget,
          SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                230,
            child: Padding(
              padding:
                  EdgeInsets.only(top: 70, left: 35, right: 35, bottom: 15),
              child: ListView(
                children: ttBody,
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height - 250),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ttWidgets,
            ),
          ),
        ],
      ));
    } else {
      return DelayedSpinnerWidget();
    }
  }
}
