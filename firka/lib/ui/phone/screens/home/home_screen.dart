import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/api/exceptions/token.dart';
import 'package:firka/helpers/settings.dart';
import 'package:firka/helpers/update_notifier.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/pages/extras/main_wear_pair.dart';
import 'package:firka/ui/phone/pages/home/home_grades.dart';
import 'package:firka/ui/phone/pages/home/home_main.dart';
import 'package:firka/ui/phone/pages/home/home_subpage.dart';
import 'package:firka/ui/phone/pages/home/home_timetable_mo.dart';
import 'package:firka/ui/phone/screens/home/beta_screen.dart';
import 'package:firka/ui/phone/widgets/bottom_nav_icon.dart';
import 'package:firka/ui/phone/widgets/login_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:smart_scroll/smart_scroll.dart';

import '../../../../helpers/db/widget.dart';
import '../../../../helpers/debug_helper.dart';
import '../../../../helpers/firka_bundle.dart';
import '../../../../helpers/firka_state.dart';
import '../../../../helpers/image_preloader.dart';
import '../../../widget/delayed_spinner.dart';
import '../../../widget/firka_icon.dart';
import '../../pages/extras/extras.dart';
import '../../pages/extras/main_error.dart';
import '../../pages/home/home_grades_subject.dart';
import '../../pages/home/home_timetable.dart';

class HomeScreen extends StatefulWidget {
  final AppInitialization data;
  final bool watchPair;
  final String? model;
  final UpdateNotifier updateNotifier = UpdateNotifier();
  final UpdateNotifier updateFinishedNotifier = UpdateNotifier();

  HomeScreen(this.data, this.watchPair, {this.model, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum HomePage { home, grades, timetable }

enum ActiveToastType { fetching, error, reauth, none }

bool _fetching = true;
bool _prefetched = false;
bool canPop = true;
ValueNotifier<bool> subPageActive = ValueNotifier(false);
UpdateNotifier subPageBack = UpdateNotifier();

class _HomeScreenState extends FirkaState<HomeScreen> {
  _HomeScreenState();

  HomePage page = HomePage.home;
  List<HomePage> previousPages = List.empty(growable: true);
  final PageController _pageController = PageController();

  Widget? toast;
  bool pairingDone = false;
  bool _disposed = false;
  bool _preloadDone = false;
  int forcedNav = 0;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  ActiveToastType activeToast = ActiveToastType.none;

  void setPageCB(HomePage newPage, bool setPrev) {
    if (_disposed) return;
    setState(() {
      if (setPrev) previousPages.add(page);
      canPop = false;
      page = newPage;
    });
  }

  void prefetch() async {
    if (_prefetched) return;

    try {
      _prefetched = true;
      var random = Random();

      ApiResponse<Object> res =
          await widget.data.client.getStudent(forceCache: false);
      if (res.statusCode >= 400 ||
          res.err == TokenExpiredException().toString()) {
        if (_disposed) return;
        setState(() {
          activeToast = ActiveToastType.reauth;
          toast = Positioned(
            top: MediaQuery.of(context).size.height / 1.6,
            left: 0.0,
            right: 0.0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                child: Card(
                  color: appStyle.colors.warningCard,
                  shadowColor: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      // Use min to prevent filling the width
                      children: [
                        FirkaIconWidget(FirkaIconType.majesticons,
                            Majesticon.alertCircleSolid,
                            color: appStyle.colors.warningAccent, size: 24),
                        SizedBox(width: 4),
                        Text(
                          widget.data.l10n.reauth,
                          style: appStyle.fonts.B_16SB
                              .copyWith(color: appStyle.colors.warningText),
                        )
                      ],
                    ),
                  ),
                ),
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return LoginWebviewWidget(widget.data,
                          username:
                              widget.data.client.model.studentId.toString(),
                          schoolId: widget.data.client.model.iss!);
                    },
                  );
                },
              ),
            ),
          );
        });
        return;
      }

      if (res.err != null) {
        throw "await widget.data.client.getStudent\n${res.err!}";
      }

      res = await widget.data.client.getGrades(forceCache: false);

      if (res.err != null) {
        throw "await widget.data.client.getGrades\n${res.err!}";
      }

      await Future.delayed(Duration(seconds: 1 + random.nextInt(2)));

      var now = timeNow();
      var start = now.subtract(Duration(days: now.weekday - 1));
      var end = start.add(Duration(days: 6));

      res =
          await widget.data.client.getTimeTable(start, end, forceCache: false);
      if (res.err != null) {
        throw "await widget.data.client.getTimeTable\n${res.err!}";
      }

      if (Platform.isAndroid) {
        await WidgetCacheHelper.updateWidgetCache(appStyle, widget.data.client);
        await HomeWidget.updateWidget(
            qualifiedAndroidName: "app.firka.naplo.glance.TimetableWidget");
      }
    } catch (e) {
      activeToast = ActiveToastType.error;

      var dismissDelay = 120;
      if (kDebugMode) {
        dismissDelay = 2;
      }
      Timer(Duration(seconds: dismissDelay), () {
        if (_disposed) return;
        setState(() {
          activeToast = ActiveToastType.none;
          toast = null;
        });
      });

      if (_disposed) return;
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(200)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  // Use min to prevent filling the width
                  children: [
                    Text(
                      widget.data.l10n.api_error,
                      style: appStyle.fonts.B_16SB
                          .copyWith(color: appStyle.colors.errorText),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      child: FirkaIconWidget(FirkaIconType.majesticons,
                          Majesticon.questionCircleSolid,
                          color: appStyle.colors.errorAccent, size: 24),
                      onTap: () {
                        var stackTrace = "";
                        if (e is Error && e.stackTrace != null) {
                          stackTrace = e.stackTrace.toString();
                        }
                        showErrorBottomSheet(context, "$e\n$stackTrace");
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
      if (!_disposed) {
        setState(() {
          _fetching = false;

          if (activeToast == ActiveToastType.fetching) toast = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    widget.data.settingsUpdateNotifier.addListener(settingsUpdateListener);

    widget.data.profilePictureUpdateNotifier.addListener(() {
      if (mounted) setState(() {});
    });

    prefetch();
    _preloadImages();
  }

  void settingsUpdateListener() {
    if (mounted) setState(() {});
  }

  Future<void> _preloadImages() async {
    final imagePaths = widget.data.settings.appIcons.keys
        .map((icon) => "assets/images/icons/$icon.webp")
        .toList();

    imagePaths.add("assets/images/background.webp");

    try {
      await ImagePreloader.preloadMultipleAssets(FirkaBundle(), imagePaths);

      if (!mounted) return;
      setState(() {
        _preloadDone = true;
      });
    } catch (e) {
      logger.severe('Home: error preloading images: $e');
      if (!mounted) return;
      setState(() {
        _preloadDone = true;
      });
    }
  }

  void _onRefresh() async {
    late void Function() finishListener;
    finishListener = () {
      widget.updateFinishedNotifier.removeListener(finishListener);

      _refreshController.refreshCompleted();
    };

    widget.updateFinishedNotifier.addListener(finishListener);
    widget.updateNotifier.update();
  }

  void _onLoading() async {
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.data.settings.group("settings").boolean("beta_warning")) {
      Timer.run(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => BetaScreen(widget.data)),
          (route) => false,
        );
      });

      return SizedBox();
    }

    if (!_preloadDone) {
      return Scaffold(
        backgroundColor: appStyle.colors.background,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [SizedBox(), DelayedSpinnerWidget(), SizedBox()],
            ),
            SizedBox(),
          ],
        ),
      );
    }

    if (widget.watchPair && !pairingDone) {
      Timer.run(() {
        showWearBottomSheet(context, widget.data, widget.model!);

        // pairingDone = true;
      });
    }

    if (_fetching) {
      if (_disposed) return SizedBox();
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
                      widget.data.l10n.refreshing,
                      style: appStyle.fonts.B_16SB
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
    return DefaultAssetBundle(
        bundle: FirkaBundle(),
        child: PopScope(
          canPop: canPop || subPageActive.value,
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
                        Expanded(
                          child: RefreshConfiguration(
                              springDescription: SpringDescription(
                                  mass: 1.9, stiffness: 85, damping: 16),
                              child: SmartScroll(
                                  controller: _refreshController,
                                  onLoading: _onLoading,
                                  onRefresh: _onRefresh,
                                  header: MaterialClassicHeader(
                                    color: appStyle.colors.accent,
                                    backgroundColor: appStyle.colors.background,
                                    offset: 24,
                                  ),
                                  physics: ClampingScrollPhysics(),
                                  child: PageView(
                                    controller: _pageController,
                                    physics: ClampingScrollPhysics(),
                                    onPageChanged: (index) {
                                      HapticFeedback.heavyImpact();

                                      if (forcedNav > 0) {
                                        forcedNav--;

                                        if (previousPages.isEmpty) {
                                          canPop = true;
                                        }
                                        return;
                                      }

                                      setState(() {
                                        previousPages.add(page);
                                        canPop = false;
                                        page = HomePage.values[index];
                                      });
                                    },
                                    children: [
                                      HomeSubPage(
                                        HomePage.home,
                                        widget.data,
                                        widget.updateNotifier,
                                        widget.updateFinishedNotifier,
                                      ),
                                      HomeSubPage(
                                        HomePage.grades,
                                        widget.data,
                                        widget.updateNotifier,
                                        widget.updateFinishedNotifier,
                                      ),
                                      HomeSubPage(
                                        HomePage.timetable,
                                        widget.data,
                                        widget.updateNotifier,
                                        widget.updateFinishedNotifier,
                                      ),
                                    ],
                                  ))),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                appStyle.colors.background,
                                appStyle.colors.background
                                    .withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(55, 0, 55, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Home Button
                                BottomNavIconWidget(() {
                                  if (page != HomePage.home) {
                                    _pageController.animateToPage(
                                      HomePage.home.index,
                                      duration: Duration(milliseconds: 175),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                    page == HomePage.home,
                                    page == HomePage.home
                                        ? Majesticon.homeSolid
                                        : Majesticon.homeLine,
                                    widget.data.l10n.home,
                                    page == HomePage.home
                                        ? appStyle.colors.accent
                                        : appStyle.colors.secondary,
                                    appStyle.colors.textPrimary),
                                // Grades Button
                                BottomNavIconWidget(() {
                                  if (page != HomePage.grades) {
                                    _pageController.animateToPage(
                                      HomePage.grades.index,
                                      duration: Duration(milliseconds: 175),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                    page == HomePage.grades,
                                    page == HomePage.grades
                                        ? Majesticon.bookmarkSolid
                                        : Majesticon.bookmarkLine,
                                    widget.data.l10n.grades,
                                    page == HomePage.grades
                                        ? appStyle.colors.accent
                                        : appStyle.colors.secondary,
                                    appStyle.colors.textPrimary),
                                // Timetable Button
                                BottomNavIconWidget(() {
                                  if (page != HomePage.timetable) {
                                    _pageController.animateToPage(
                                      HomePage.timetable.index,
                                      duration: Duration(milliseconds: 175),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                    page == HomePage.timetable,
                                    page == HomePage.timetable
                                        ? Majesticon.calendarSolid
                                        : Majesticon.calendarLine,
                                    widget.data.l10n.timetable,
                                    page == HomePage.timetable
                                        ? appStyle.colors.accent
                                        : appStyle.colors.secondary,
                                    appStyle.colors.textPrimary),
                                // More Button
                                BottomNavIconWidget(
                                  () {
                                    HapticFeedback.lightImpact();
                                    showExtrasBottomSheet(context, widget.data);
                                  },
                                  false,
                                  widget.data.profilePicture != null
                                      ? widget.data.profilePicture!
                                      : Majesticon.menuLine,
                                  widget.data.l10n.other,
                                  appStyle.colors.secondary,
                                  appStyle.colors.textPrimary,
                                  isProfilePicture:
                                      widget.data.profilePicture != null,
                                ),
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
          onPopInvokedWithResult: (_, __) {
            if (subPageActive.value) {
              subPageBack.update();
              return;
            }

            if (previousPages.isNotEmpty && page != previousPages.last) {
              setState(() {
                page = previousPages.removeLast();

                forcedNav++;
                _pageController.animateToPage(
                  page.index,
                  duration: Duration(milliseconds: 175),
                  curve: Curves.easeInOut,
                );
                canPop = previousPages.isEmpty;
              });
            }
          },
        ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    widget.data.settingsUpdateNotifier.removeListener(settingsUpdateListener);
    widget.data.profilePictureUpdateNotifier
        .removeListener(settingsUpdateListener);

    widget.data.profilePictureUpdateNotifier.removeListener(() {
      if (mounted) setState(() {});
    });

    _disposed = true;
    _fetching = false;
    _prefetched = false;
    activeToast = ActiveToastType.none;
    super.dispose();
  }
}

class HomeSubPage extends StatelessWidget {
  final HomePage page;
  final AppInitialization data;
  final UpdateNotifier _updateNotifier;
  final UpdateNotifier _updateFinishNotifier;

  const HomeSubPage(
      this.page, this.data, this._updateNotifier, this._updateFinishNotifier,
      {super.key});

  @override
  Widget build(BuildContext context) {
    switch (page) {
      case HomePage.home:
        return HomeMainScreen(data, _updateNotifier, _updateFinishNotifier);
      case HomePage.grades:
        return PageWithSubPages([
          (cb) => HomeGradesScreen(
              data, _updateNotifier, _updateFinishNotifier, cb),
          (cb) => HomeGradesSubjectScreen(
              data, _updateNotifier, _updateFinishNotifier)
        ], subPageActive, subPageBack, pageIndex: 0);
      case HomePage.timetable:
        return PageWithSubPages([
          (cb) => HomeTimetableScreen(
              data, _updateNotifier, _updateFinishNotifier, cb),
          (cb) => HomeTimetableMonthlyScreen(
              data, _updateNotifier, _updateFinishNotifier, cb)
        ], subPageActive, subPageBack, pageIndex: 0);
    }
  }
}
