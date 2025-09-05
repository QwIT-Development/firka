import 'package:firka/helpers/api/consts.dart';
import 'package:firka/helpers/api/model/omission.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/settings/setting.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

import '../../../../helpers/api/model/test.dart';
import '../../../../helpers/update_notifier.dart';
import '../../../../main.dart';
import '../../../widget/firka_icon.dart';
import '../../screens/settings/settings_screen.dart';

class HomeTimetableMonthlyScreen extends StatefulWidget {
  final AppInitialization data;
  final UpdateNotifier updateNotifier;
  final UpdateNotifier finishNotifier;
  final void Function(int) pageController;

  const HomeTimetableMonthlyScreen(
      this.data, this.updateNotifier, this.finishNotifier, this.pageController,
      {super.key});

  @override
  State<HomeTimetableMonthlyScreen> createState() =>
      _HomeTimetableMonthlyScreen();
}

enum ActiveFilter { lessonNo, tests, omissions }

class _HomeTimetableMonthlyScreen extends State<HomeTimetableMonthlyScreen> {
  List<Lesson>? lessons;
  List<Test>? tests;
  List<DateTime>? dates;
  List<Omission>? omissions;
  DateTime? now;
  int active = 0;
  ActiveFilter activeFilter = ActiveFilter.lessonNo;

  _HomeTimetableMonthlyScreen();

  Future<void> initForMonth(DateTime now, {bool forceCache = true}) async {
    final monthStart = DateTime.utc(now.year, now.month, 1);
    final monthEnd =
        DateTime.utc(now.year, now.month + 1).subtract(Duration(days: 1));

    final start = monthStart.subtract(Duration(days: 7)).getMonday();
    var end =
        monthEnd.add(Duration(days: 7)).getMonday().add(Duration(days: 7));

    var days = end.difference(start).inDays;

    var lessonsResp = await widget.data.client
        .getTimeTable(monthStart, monthEnd, forceCache: forceCache);
    var testsResp = await widget.data.client.getTests(forceCache: forceCache);
    var omissionsResp =
        await widget.data.client.getOmissions(forceCache: forceCache);
    List<DateTime> dates = List.empty(growable: true);

    for (var i = 0; i < days; i++) {
      dates.add(start.add(Duration(days: i)));
    }

    if (lessonsResp.response != null) {
      lessons = lessonsResp.response
          ?.where((lesson) => lesson.type.name != TimetableConsts.event)
          .toList();
    }
    tests = testsResp.response;
    omissions = omissionsResp.response;

    if (mounted) {
      setState(() {
        this.dates = dates;
      });
    }
  }

  @override
  void didUpdateWidget(HomeTimetableMonthlyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.updateNotifier.removeListener(updateListener);
    widget.updateNotifier.addListener(updateListener);
  }

  void updateListener() async {
    if (now != null) {
      await initForMonth(now!, forceCache: false);
      setState(() {});
    }
    widget.finishNotifier.update();
  }

  @override
  void initState() {
    super.initState();

    widget.updateNotifier.addListener(updateListener);

    now = timeNow();
    initForMonth(now!);
  }

  @override
  void dispose() {
    super.dispose();

    widget.updateNotifier.removeListener(updateListener);
  }

  @override
  Widget build(BuildContext context) {
    if (lessons != null &&
        omissions != null &&
        tests != null &&
        dates != null) {
      List<Widget> ttDays = [];

      final meow = dates![20];
      final currentMonthStart = DateTime.utc(meow.year, meow.month, 1);
      final currentMonthEnd =
          DateTime.utc(meow.year, meow.month + 1).subtract(Duration(days: 1));

      // column-major -> row-major
      for (var day = 0; day < 7; day++) {
        for (var week = 0; week < 7; week++) {
          final d = dates![week * 7 + day];

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
                          borderRadius: BorderRadius.circular(12)),
                    )),
                SizedBox(height: 4),
                Text(d.format(widget.data.l10n, FormatMode.d),
                    style: appStyle.fonts.B_14R.apply(
                        color: (d.weekday == DateTime.saturday ||
                                d.weekday == DateTime.sunday)
                            ? appStyle.colors.errorText
                            : appStyle.colors.textTertiary)),
              ],
            ));
          } else {
            Widget body = SizedBox();
            Color bodyBgColor = appStyle.colors.a15p;

            var lessonsToday = lessons!.where((lesson) =>
                lesson.start.isAfter(d.getMidnight()) &&
                lesson.end.isBefore(
                    d.getMidnight().add(Duration(hours: 23, minutes: 59))));

            var omissionType = lessonsToday.firstWhereOrNull((lesson) =>
                lesson.studentPresence != null &&
                lesson.studentPresence?.name != OmissionConsts.na &&
                lesson.studentPresence?.name != OmissionConsts.present);

            switch (activeFilter) {
              case ActiveFilter.lessonNo:
                if (lessonsToday.isNotEmpty) {
                  body = Center(
                    child: Text(lessonsToday.length.toString(),
                        style: appStyle.fonts.H_16px.apply(
                            color: omissionType != null &&
                                    (omissionType.studentPresence!.name ==
                                            OmissionConsts.absence ||
                                        omissionType.studentPresence!.name ==
                                            OmissionConsts.na)
                                ? appStyle.colors.errorText
                                : timeNow().day == d.day &&
                                        timeNow().month == d.month
                                    ? appStyle.colors.accent
                                    : appStyle.colors.secondary)),
                  );

                  if (omissionType != null &&
                      (omissionType.studentPresence!.name ==
                              OmissionConsts.absence ||
                          omissionType.studentPresence!.name ==
                              OmissionConsts.na)) {
                    bodyBgColor = appStyle.colors.error15p;
                  }
                }
                break;
              case ActiveFilter.tests:
                if (lessonsToday.firstWhereOrNull((lesson) => tests!.any(
                        (test) =>
                            test.lessonNumber == lesson.lessonNumber &&
                            lesson.start.isAfter(test.date.getMidnight()) &&
                            lesson.end.isBefore(test.date
                                .getMidnight()
                                .add(Duration(hours: 23, minutes: 59))))) !=
                    null) {
                  body = Center(
                    child: FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.editPen4Solid,
                      size: 20.0,
                      color: appStyle.colors.accent,
                    ),
                  );
                }
                break;
              case ActiveFilter.omissions:
                if (omissionType != null) {
                  switch (omissionType.studentPresence!.name) {
                    case OmissionConsts.absence:
                      final omission = omissions!.firstWhereOrNull((omission) {
                        return omission.date
                                    .getMidnight()
                                    .millisecondsSinceEpoch ==
                                omissionType.start
                                    .getMidnight()
                                    .millisecondsSinceEpoch &&
                            omission.subject.uid == omissionType.subject?.uid;
                      });
                      if (omission != null) {
                        switch (omission.state) {
                          case "Igazolando":
                            body = Center(
                              child: FirkaIconWidget(
                                FirkaIconType.majesticons,
                                Majesticon.restrictedSolid,
                                size: 20.0,
                                color: appStyle.colors.warningAccent,
                              ),
                            );
                            bodyBgColor = appStyle.colors.warning15p;
                            break;
                          default:
                            body = Center(
                              child: FirkaIconWidget(
                                FirkaIconType.majesticons,
                                Majesticon.multiplySolid,
                                size: 20.0,
                                color: appStyle.colors.accent,
                              ),
                            );
                        }
                      } else {
                        body = Center(
                          child: FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.multiplySolid,
                            size: 20.0,
                            color: appStyle.colors.accent,
                          ),
                        );
                      }
                      break;
                    default:
                      debugPrint(omissionType.studentPresence!.name);
                      body = Center(
                        child: FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.timerLine,
                          size: 20.0,
                          color: appStyle.colors.accent,
                        ),
                      );
                  }
                }
                break;
            }

            ttDays.add(Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: bodyBgColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: body,
                ),
                SizedBox(height: 4),
                Text(d.format(widget.data.l10n, FormatMode.d),
                    style: appStyle.fonts.B_14R.apply(
                        color: (d.weekday == DateTime.saturday ||
                                    d.weekday == DateTime.sunday) &&
                                lessonsToday.isEmpty
                            ? appStyle.colors.errorText
                            : appStyle.colors.textSecondary)),
                SizedBox(height: 12),
              ],
            ));

            if (timeNow().getMidnight().millisecondsSinceEpoch ==
                d.toLocal().getMidnight().millisecondsSinceEpoch) {
              bodyBgColor = appStyle.colors.buttonSecondaryFill;
            }
          }
        }
      }

      return Scaffold(
          backgroundColor: appStyle.colors.background,
          body: Stack(children: [
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
                                widget.pageController(0);
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
                          onTap: () async {
                            var newNow = DateTime(now!.year, now!.month - 1);
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
                            style: appStyle.fonts.B_14R
                                .apply(color: appStyle.colors.textPrimary)),
                        GestureDetector(
                          child: FirkaIconWidget(
                            FirkaIconType.icons,
                            "dropdownRight",
                            size: 24,
                            color: appStyle.colors.accent,
                          ),
                          onTap: () async {
                            var newNow = DateTime(now!.year, now!.month + 1);
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StaggeredGrid.count(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    children: ttDays,
                  )
                ],
              ),
            )),
            TransparentPointer(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 1.3,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(),
                        Row(
                          children: [
                            _StatusToast(
                                FirkaIconWidget(FirkaIconType.majesticons,
                                    Majesticon.clockSolid,
                                    color: appStyle.colors.accent, size: 16),
                                lessons!
                                    .where((lesson) =>
                                        lesson.start
                                            .isAfter(currentMonthStart) &&
                                        lesson.end.isBefore(currentMonthEnd))
                                    .length,
                                activeFilter == ActiveFilter.lessonNo, () {
                              setState(() {
                                activeFilter = ActiveFilter.lessonNo;
                              });
                            }),
                            _StatusToast(
                                FirkaIconWidget(FirkaIconType.majesticons,
                                    Majesticon.editPen4Solid,
                                    color: appStyle.colors.accent, size: 16),
                                lessons!
                                    .where((lesson) => tests!.any((test) =>
                                        test.lessonNumber ==
                                            lesson.lessonNumber &&
                                        lesson.start
                                            .isAfter(test.date.getMidnight()) &&
                                        lesson.end.isBefore(test.date
                                            .getMidnight()
                                            .add(Duration(
                                                hours: 23, minutes: 59)))))
                                    .length,
                                activeFilter == ActiveFilter.tests, () {
                              setState(() {
                                activeFilter = ActiveFilter.tests;
                              });
                            }),
                            _StatusToast(
                                FirkaIconWidget(FirkaIconType.majesticons,
                                    Majesticon.timerLine,
                                    color: appStyle.colors.accent, size: 16),
                                lessons!
                                    .where((lesson) =>
                                        lesson.start
                                            .isAfter(currentMonthStart) &&
                                        lesson.end.isBefore(currentMonthEnd) &&
                                        lesson.studentPresence != null &&
                                        lesson.studentPresence?.name !=
                                            OmissionConsts.na &&
                                        lesson.studentPresence?.name !=
                                            OmissionConsts.present)
                                    .length,
                                activeFilter == ActiveFilter.omissions, () {
                              setState(() {
                                activeFilter = ActiveFilter.omissions;
                              });
                            }),
                          ],
                        ),
                        SizedBox()
                      ],
                    ),
                  )
                ],
              ),
            ),
          ]));
    } else {
      return Scaffold(
        backgroundColor: appStyle.colors.background,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [DelayedSpinnerWidget()],
            )
          ],
        ),
      );
    }
  }
}

class _StatusToast extends StatelessWidget {
  final FirkaIconWidget _icon;
  final int _count;
  final bool _active;
  final void Function() _onTap;

  const _StatusToast(this._icon, this._count, this._active, this._onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: _active
              ? appStyle.colors.buttonSecondaryFill
              : appStyle.colors.cardTranslucent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              _icon,
              SizedBox(width: 6),
              Text(_count.toString(),
                  style: appStyle.fonts.H_16px
                      .apply(color: appStyle.colors.textPrimary))
            ],
          ),
        ),
      ),
    );
  }
}
