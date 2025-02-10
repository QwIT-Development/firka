import 'dart:async';

import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/pages/home/home_grades.dart';
import 'package:firka/ui/phone/pages/home/home_main.dart';
import 'package:firka/ui/phone/widgets/bottom_nav_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';


import '../../../../helpers/debug_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widget/firka_icon.dart';
import '../../pages/extras/extras.dart';
import '../../pages/extras/main_error.dart';
import '../../pages/home/home_grades_subject.dart';
import '../../pages/home/home_timetable.dart';
import '../debug/debug_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeScreen(this.data, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState(data);
}

enum HomePages { home, grades, timetable }

enum ActiveToastType { fetching, error, none }

class ActiveHomePage {
  final HomePages page;
  final String? subPageUid;

  ActiveHomePage(this.page, {this.subPageUid});

  @override
  int get hashCode => (page.hashCode ^ subPageUid.hashCode);

  @override
  bool operator ==(Object other) {
    return (other is ActiveHomePage) && hashCode == other.hashCode;
  }
}

bool _fetching = true;
bool _prefetched = false;
bool canPop = true;

class _HomeScreenState extends State<HomeScreen> {
  final AppInitialization data;

  _HomeScreenState(this.data);

  ActiveHomePage page = ActiveHomePage(HomePages.home);
  List<ActiveHomePage> previousPages = List.empty(growable: true);

  Widget? toast;

  ActiveToastType activeToast = ActiveToastType.none;

  void setPageCB(ActiveHomePage newPage) {
    setState(() {
      previousPages.add(page);
      canPop = false;
      page = newPage;
    });
  }

  void prefetch() async {
    if (_prefetched) return;

    try {
      _prefetched = true;

      ApiResponse<Object> res = await data.client.getGrades(forceCache: false);

      if (res.err != null) throw res.err!;

      var now = timeNow();
      var start = now.subtract(Duration(days: now.weekday - 1));
      var end = start.add(Duration(days: 6));

      res = await data.client.getTimeTable(start, end, forceCache: false);

      if (res.err != null) throw res.err!;
    } catch (e) {
      activeToast = ActiveToastType.error;

      var dismissDelay = 120;
      if (kDebugMode) {
        dismissDelay = 2;
      }
      Timer(Duration(seconds: dismissDelay), () {
        setState(() {
          activeToast = ActiveToastType.none;
          toast = null;
        });
      });

      setState(() {
        // TODO: Make this and the error toast more rounded
        toast = Positioned(
          top: MediaQuery.of(context).size.height / 1.6,
          left: 0.0,
          right: 0.0,
          bottom: 0,
          child: Center(
            child: Card(
              color: appStyle.colors.errorCard,
              shadowColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  // Use min to prevent filling the width
                  children: [
                    Text(
                      AppLocalizations.of(context)!.api_error,
                      style: appStyle.fonts.B_14SB
                          .copyWith(color: appStyle.colors.errorText),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      child: FirkaIconWidget(FirkaIconType.Majesticons,
                          Majesticon.questionCircleSolid,
                          color: appStyle.colors.errorAccent, size: 24),
                      onTap: () {
                        showErrorBottomSheet(context, e.toString());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    } finally {
      setState(() {
        _fetching = false;

        if (activeToast == ActiveToastType.fetching) toast = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });

    prefetch();
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: appStyle.colors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    _updateSystemUI(); // Update system UI on every build, to compensate for the android system being dumb

    if (_fetching) {
      setState(() {
        activeToast = ActiveToastType.fetching;
        toast = Positioned(
          top: MediaQuery.of(context).size.height / 1.6,
          left: 0.0,
          right: 0.0,
          bottom: 0,
          child: Center(
            child: Card(
              color: appStyle.colors.card,
              shadowColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  // Use min to prevent filling the width
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: appStyle.colors.accent,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(context)!.refreshing,
                      style: appStyle.fonts.B_14SB
                          .copyWith(color: appStyle.colors.textPrimary),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      });
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        backgroundColor: appStyle.colors.background,
        body: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [HomeSubPage(page, setPageCB, data)],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            appStyle.colors.background,
                            appStyle.colors.background.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 55, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Home Button
                            BottomNavIconWidget(() {
                              if (page.page != HomePages.home) {
                                HapticFeedback.lightImpact();

                                setState(() {
                                  previousPages.add(page);
                                  canPop = false;
                                  page = ActiveHomePage(HomePages.home);
                                });
                              }
                            },
                                page.page == HomePages.home,
                                page.page == HomePages.home
                                    ? Majesticon.homeSolid
                                    : Majesticon.homeLine,
                                AppLocalizations.of(context)!.home,
                                page.page == HomePages.home
                                    ? appStyle.colors.accent
                                    : appStyle.colors.secondary,
                                appStyle.colors.textPrimary),
                            // Grades Button
                            BottomNavIconWidget(() {
                              if (page.page != HomePages.grades) {
                                HapticFeedback.lightImpact();

                                setState(() {
                                  previousPages.add(page);
                                  canPop = false;
                                  page = ActiveHomePage(HomePages.grades);
                                });
                              }
                            },
                                page.page == HomePages.grades,
                                page.page == HomePages.grades
                                    ? Majesticon.bookmarkSolid
                                    : Majesticon.bookmarkLine,
                                AppLocalizations.of(context)!.grades,
                                page.page == HomePages.grades
                                    ? appStyle.colors.accent
                                    : appStyle.colors.secondary,
                                appStyle.colors.textPrimary),
                            // Timetable Button
                            BottomNavIconWidget(() {
                              if (page.page != HomePages.timetable) {
                                HapticFeedback.lightImpact();

                                setState(() {
                                  previousPages.add(page);
                                  canPop = false;
                                  page = ActiveHomePage(HomePages.timetable);
                                });
                              }
                            },
                                page.page == HomePages.timetable,
                                page.page == HomePages.timetable
                                    ? Majesticon.calendarSolid
                                    : Majesticon.calendarLine,
                                AppLocalizations.of(context)!.timetable,
                                page.page == HomePages.timetable
                                    ? appStyle.colors.accent
                                    : appStyle.colors.secondary,
                                appStyle.colors.textPrimary),
                            // More Button
                            BottomNavIconWidget(() {
                              HapticFeedback.lightImpact();
                              showExtrasBottomSheet(context, data);
                            },
                                false,
                                Majesticon.globeEarthLine,
                                AppLocalizations.of(context)!.other,
                                appStyle.colors.secondary,
                                appStyle.colors.textPrimary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                toast ?? SizedBox(),
              ],
            ),
          ),
        ),
      ),
      onPopInvokedWithResult: (_, __) => {
        if (previousPages.isNotEmpty && page != previousPages.last)
          {
            setState(() {
              page = previousPages.removeLast();
              canPop = previousPages.isEmpty;
            })
          }
      },
    );
  }
}

class HomeSubPage extends StatelessWidget {
  final ActiveHomePage page;
  final void Function(ActiveHomePage) cb;
  final AppInitialization data;

  const HomeSubPage(this.page, this.cb, this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    switch (page.page) {
      case HomePages.home:
        return HomeMainScreen(data);
      case HomePages.grades:
        if (page.subPageUid != null) {
          return HomeGradesSubjectScreen(data, page.subPageUid!);
        } else {
          return HomeGradesScreen(data, cb);
        }
      case HomePages.timetable:
        return HomeTimetableScreen(data);
    }
  }
}
