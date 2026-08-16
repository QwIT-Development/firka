import 'package:firka/ui/components/firka_icon_button.dart';
import 'package:firka/ui/phone/screens/settings/settings_screen.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/ui/shared/firka_icon.dart';

class HomeTimetableMonthlyScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeTimetableMonthlyScreen(this.data, {super.key});

  @override
  State<HomeTimetableMonthlyScreen> createState() =>
      _HomeTimetableMonthlyScreen();
}

enum ActiveFilter { lessonNo, tests, omissions }

class _HomeTimetableMonthlyScreen
    extends FirkaState<HomeTimetableMonthlyScreen> {
  List<DateTime> dates = [];
  late DateTime now;
  int active = 0;
  ActiveFilter activeFilter = ActiveFilter.lessonNo;

  _HomeTimetableMonthlyScreen();

  void updateDates() {
    DateTime from = now.getMidnight().getMonthFirstDay().getMonday().subtract(
      Duration(days: 7),
    );

    dates = List.generate(49, (i) => from.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();

    now = timeNow();

    updateDates();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeRefreshCubit, HomeRefreshState>(
      listenWhen: (previous, current) =>
          current.refreshTrigger != previous.refreshTrigger,
      listener: (context, state) {
        setState(() {});
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    List<Widget> ttDays = [];

    updateDates();

    final currentMonthStart = now.getMidnight().getMonthFirstDay();
    final currentMonthEnd = now
        .getMonthLastDay()
        .add(Duration(days: 1))
        .getMidnight()
        .subtract(Duration(microseconds: 1));

    // column-major -> row-major
    for (var week = 0; week < 7; week++) {
      for (var day = 0; day < 7; day++) {
        final d = dates[week * 7 + day];

        bool outOfRange =
            d.isBefore(currentMonthStart) || d.isAfter(currentMonthEnd);
        bool isToday =
            !outOfRange &&
            timeNow().year == d.year &&
            timeNow().day == d.day &&
            timeNow().month == d.month;

        Widget body = SizedBox();
        Color? todayAccent = isToday ? appStyle.colors.textPrimaryLight : null;
        Color bodyBgColor = appStyle.colors.a15p;

        var lessonsToday = widget.data.client!.cache.getClassLessons().on(d);

        int lessonCountToday = lessonsToday.countSync();

        // TODO: Nézze meg a többi órát is
        var omittedLesson = lessonsToday
            .and()
            .not()
            .omissionIsNull()
            .findFirstSync();

        if (lessonCountToday > 0) {
          switch (activeFilter) {
            case ActiveFilter.lessonNo:
              body = Center(
                child: Text(
                  lessonCountToday.toString(),
                  style: appStyle.fonts.H_16px.apply(
                    color:
                        (todayAccent ??
                                (omittedLesson != null
                                    ? appStyle.colors.errorText
                                    : appStyle.colors.secondary))
                            .withAlpha(outOfRange ? 77 : 255),
                  ),
                ),
              );

              if (omittedLesson != null) {
                bodyBgColor = appStyle.colors.error15p;
              }
              break;
            case ActiveFilter.tests:
              if (lessonsToday.not().testIsNull().isNotEmptySync()) {
                body = Center(
                  child: FirkaIconWidget(
                    FirkaIconType.majesticons,
                    Majesticon.editPen4Solid,
                    size: 20.0,
                    color: todayAccent ?? appStyle.colors.accent,
                  ),
                );
              }
              break;
            case ActiveFilter.omissions:
              if (omittedLesson == null) {
                break;
              }

              var omissionState = omittedLesson.omission.loadAndGet()!.state;
              switch (omissionState) {
                case OmissionState.excused:
                  body = Center(
                    child: FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.multiplySolid,
                      size: 20.0,
                      color: todayAccent ?? appStyle.colors.accent,
                    ),
                  );
                  break;
                case OmissionState.pending:
                  body = Center(
                    child: FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.timerLine,
                      size: 20.0,
                      color: todayAccent ?? appStyle.colors.warningAccent,
                    ),
                  );
                  bodyBgColor = appStyle.colors.warning15p;
                  break;
                default:
                  body = Center(
                    child: FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.restrictedSolid,
                      size: 20.0,
                      color: todayAccent ?? appStyle.colors.errorAccent,
                    ),
                  );
                  bodyBgColor = appStyle.colors.error15p;
                  break;
              }
              break;
          }
        }

        if (isToday) {
          bodyBgColor = appStyle.colors.accent;
        }

        if (outOfRange) {
          bodyBgColor = appStyle.colors.cardTranslucent;
        }

        bool isWeekend = d.weekday > 5 && lessonCountToday == 0;
        Color textColor = (isWeekend
            ? appStyle.colors.errorText
            : isToday
            ? appStyle.colors.textPrimary
            : appStyle.colors.textTertiary);

        if (outOfRange) {
          textColor = textColor.withAlpha(77);
        } else if (isWeekend) {
          textColor = textColor.withAlpha(128);
        }

        ttDays.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: bodyBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: body,
              ),
              SizedBox(height: 4),
              Text(
                d.format(widget.data.l10n, FormatMode.d),
                style: (isToday ? appStyle.fonts.B_14SB : appStyle.fonts.B_14R)
                    .apply(color: textColor),
              ),
            ],
          ),
        );
      }
    }

    final lessonsInMonth = widget.data.client!.cache.getClassLessons().between(
      currentMonthStart,
      currentMonthEnd,
    );

    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: Stack(
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
                        headingText(widget.data.l10n.timetable),
                        style: appStyle.fonts.H_H2.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          FirkaIconButton(
                            onTap: () {
                              context.pop();
                            },
                            child: FirkaIconWidget(
                              FirkaIconType.majesticons,
                              Majesticon.tableSolid,
                              size: 20.0,
                              color: appStyle.colors.accent,
                            ),
                          ),
                          // Nincs elkészítve jelenleg: Dolgozat stb hozzáadása(?)
                          // FirkaIconButton(
                          //   child: FirkaIconWidget(
                          //     FirkaIconType.majesticons,
                          //     Majesticon.plusLine,
                          //     size: 20.0,
                          //     color: appStyle.colors.accent,
                          //   ),
                          // ),
                          FirkaIconButton(
                            onTap: () {
                              showSettingsSheet(
                                context,
                                MediaQuery.of(context).size.height * 0.4,
                                widget.data,
                                timetableToastTree(widget.data.l10n),
                              );
                            },
                            child: FirkaIconWidget(
                              FirkaIconType.majesticons,
                              Majesticon.settingsCogSolid,
                              size: 20.0,
                              color: appStyle.colors.accent,
                            ),
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
                          setState(() {
                            now = DateTime(now.year, now.month - 1);
                          });
                        },
                      ),
                      Text(
                        now
                            .format(widget.data.l10n, FormatMode.yyyymmmm)
                            .toLowerCase(),
                        style: appStyle.fonts.B_16R.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        child: FirkaIconWidget(
                          FirkaIconType.icons,
                          "dropdownRight",
                          size: 24,
                          color: appStyle.colors.accent,
                        ),
                        onTap: () async {
                          setState(() {
                            now = DateTime(now.year, now.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          TransparentPointer(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 74 + 16 + 12,
                left: 20,
                right: 20,
              ),
              child: RefreshIndicator(
                onRefresh: () => widget.data.client!.pullRefresh(
                  () => widget.data.client!.getLessonsCovering(
                    currentMonthStart,
                    currentMonthEnd,
                  ),
                ),
                child: GridView.count(
                  physics: const AlwaysScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 62,
                  children: ttDays,
                ),
              ),
            ),
          ),
          TransparentPointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  _StatusToast(
                    FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.clockSolid,
                      color: appStyle.colors.accent,
                      size: 16,
                    ),
                    lessonsInMonth.countSync(),
                    activeFilter == ActiveFilter.lessonNo,
                    () {
                      setState(() {
                        activeFilter = ActiveFilter.lessonNo;
                      });
                    },
                  ),
                  _StatusToast(
                    FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.editPen4Solid,
                      color: appStyle.colors.accent,
                      size: 16,
                    ),
                    lessonsInMonth.and().not().testIsNull().countSync(),
                    activeFilter == ActiveFilter.tests,
                    () {
                      setState(() {
                        activeFilter = ActiveFilter.tests;
                      });
                    },
                  ),
                  _StatusToast(
                    FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.timerLine,
                      color: appStyle.colors.accent,
                      size: 16,
                    ),
                    lessonsInMonth.and().not().omissionIsNull().countSync(),
                    activeFilter == ActiveFilter.omissions,
                    () {
                      setState(() {
                        activeFilter = ActiveFilter.omissions;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: _active
              ? appStyle.colors.buttonSecondaryFill
              : appStyle.colors.cardTranslucent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          spacing: 6,
          children: [
            _icon,
            Text(
              _count.toString(),
              style: appStyle.fonts.H_16px.apply(
                color: _active
                    ? appStyle.colors.textPrimary
                    : appStyle.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
