import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/api/client/kreta_stream.dart';
import 'package:firka/ui/phone/widgets/info_card.dart';
import 'package:firka/ui/phone/widgets/lesson.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:flutter/rendering.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/ui/phone/widgets/home_main_starting_soon.dart';
import 'package:firka/ui/phone/widgets/lesson_small.dart';
import 'package:firka/ui/shared/delayed_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import '../../widgets/home_main_welcome.dart';
import '../../widgets/lesson_big.dart';

class HomeMainScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeMainScreen(this.data, {super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreen();
}

class _HomeMainScreen extends FirkaState<HomeMainScreen> {
  _HomeMainScreen();

  DateTime now = timeNow();
  int swipeBack = 0;
  int activeLessonIndex = 0;
  List<Lesson>? lessons;
  List<NoticeBoardItem>? noticeBoard;
  List<InfoBoardItem>? infoBoard;
  List<Test>? tests;
  List<Grade>? grades;
  List<Homework>? homework;
  CarouselSliderController controller = CarouselSliderController();
  Student? student;
  Timer? timer;

  void _onRefreshRequested(BuildContext context) async {
    final cubit = context.read<HomeRefreshCubit>();
    await fetchData(cacheOnly: false);
    if (mounted) {
      cubit.onRefreshComplete();
    }
  }

  Future<void> fetchData({bool cacheOnly = false}) async {
    final midnight = now.getMidnight();

    var lessonsFetched = 0;
    var noticeBoardFetched = 0;
    var infoBoardFetched = 0;
    var studentFetched = 0;
    var testsFetched = 0;
    var gradesFetched = 0;
    var homeworkFetched = 0;

    widget.data.client
        .getTimeTableStream(
          midnight,
          midnight.add(Duration(hours: 23, minutes: 59)),
          cacheOnly: cacheOnly,
        )
        .forEach((lessons) {
          lessonsFetched++;

          if (mounted) {
            setState(() {
              this.lessons = lessons.response;
            });
          }
        });

    widget.data.client.getNoticeBoardStream(cacheOnly: cacheOnly).forEach((
      items,
    ) {
      noticeBoardFetched++;

      if (mounted) {
        setState(() {
          noticeBoard = items.response;
        });
      }
    });

    widget.data.client.getInfoBoardStream(cacheOnly: cacheOnly).forEach((
      items,
    ) {
      infoBoardFetched++;

      if (mounted) {
        setState(() {
          infoBoard = items.response;
        });
      }
    });

    widget.data.client.getStudentStream(cacheOnly: cacheOnly).forEach((
      student,
    ) {
      studentFetched++;

      if (mounted) {
        setState(() {
          this.student = student.response;
        });
      }
    });

    widget.data.client.getTestsStream(cacheOnly: cacheOnly).forEach((tests) {
      testsFetched++;

      if (mounted) {
        setState(() {
          this.tests = tests.response;
        });
      }
    });

    widget.data.client.getGradesStream(cacheOnly: cacheOnly).forEach((grades) {
      gradesFetched++;

      if (mounted) {
        setState(() {
          this.grades = grades.response;
        });
      }
    });

    widget.data.client.getHomeworkStream(cacheOnly: cacheOnly).forEach((
      homework,
    ) {
      homeworkFetched++;

      if (mounted) {
        setState(() {
          this.homework = homework.response;
        });
      }
    });

    final r = cacheOnly ? 1 : 2;
    final startTime = DateTime.now();
    const maxWaitTime = Duration(seconds: 30);

    while (lessonsFetched < r ||
        noticeBoardFetched < r ||
        infoBoardFetched < r ||
        studentFetched < r ||
        testsFetched < r ||
        gradesFetched < r ||
        homeworkFetched < r) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        debugPrint('[HomeMain] Data fetch timed out after 30s');
        break;
      }
      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  @override
  void initState() {
    super.initState();

    now = timeNow();
    if (!mounted) return;

    (() async {
      await fetchData();
    })();

    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (swipeBack > 0) swipeBack -= 1;
      if (!mounted) return;
      setState(() {
        now = timeNow();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeRefreshCubit, HomeRefreshState>(
      listenWhen: (previous, current) =>
          current.refreshTrigger != previous.refreshTrigger,
      listener: (context, state) {
        _onRefreshRequested(context);
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (student != null && lessons != null) {
      final infoItems = [...(infoBoard ?? []), ...(noticeBoard ?? [])];
      final gradeItems = grades ?? [];
      final testItems = tests ?? [];
      final homeworkItems = homework ?? [];
      final noticeBoardWidgets = <(Widget, DateTime)>[];

      for (final item in infoItems) {
        noticeBoardWidgets.add((InfoCard.messageItem(item), item.date));
      }

      for (final test in testItems) {
        noticeBoardWidgets.add((InfoCard.test(test), test.reportDate));
      }

      for (final grade in gradeItems) {
        noticeBoardWidgets.add((InfoCard.gradeSubj(grade), grade.creationDate));
      }

      for (final entry in homeworkItems) {
        noticeBoardWidgets.add((InfoCard.homework(entry), entry.creationDate));
      }

      noticeBoardWidgets.sort(
        (item1, item2) => item2.$2.difference(item1.$2).inMilliseconds,
      );

      var currentLesson = lessons!.firstWhereOrNull(
        (lesson) => now.isBefore(lesson.end),
      );

      Map<Lesson, Test?> lessonTestMap = Map.fromEntries(
        lessons!.indexed.map(
          (i) => MapEntry(
            i.$2,
            testItems.firstWhereOrNull(
              (t) =>
                  t.date.getMidnight() == i.$2.start.getMidnight() &&
                  (i.$2.lessonNumber ?? i.$1) == t.lessonNumber,
            ),
          ),
        ),
      );

      int tmpIndex = lessons!.isEmpty || now.isBefore(lessons!.first.start)
          ? 0
          : currentLesson == null
          ? lessons!.length + 1
          : lessons!.indexOf(currentLesson) + 1;

      if (tmpIndex != activeLessonIndex) {
        activeLessonIndex = tmpIndex;
        swipeBack = 0;
      }

      if (controller.ready && swipeBack == 0) {
        controller.animateToPage(activeLessonIndex);
      }

      int testsTomorrow = testItems
          .where(
            (test) =>
                test.date.isAfter(
                  now.getMidnight().add(Duration(hours: 23, minutes: 59)),
                ) &&
                test.date.isBefore(now.getMidnight().add(Duration(days: 1))),
          )
          .length;

      return Padding(
        padding: const EdgeInsets.only(left: 20.0, top: 24.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WelcomeWidget(widget.data.l10n, now, student!, lessons!),
            SizedBox(height: 48),
            if (lessons!.isNotEmpty)
              OverflowBox(
                maxWidth: MediaQuery.widthOf(context),
                fit: OverflowBoxFit.deferToChild,
                child: CarouselSlider(
                  items: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: StartingSoonWidget(
                        widget.data.l10n,
                        now,
                        lessons!,
                      ),
                    ),
                    ...lessonTestMap.entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: LessonWidget(
                          widget.data,
                          lessons!.getLessonNo(entry.key),
                          entry.key,
                          entry.value,
                          active: currentLesson == entry.key,
                          expanded: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: FirkaCard.single(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                FilledCircle(
                                  diameter: 32,
                                  color: appStyle.colors.a15p,
                                  child: FirkaIconWidget(
                                    FirkaIconType.majesticons,
                                    Majesticon.moonSolid,
                                    size: 20,
                                    color: appStyle.colors.accent,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  testsTomorrow == 0
                                      ? widget.data.l10n.tt_no_classes_l2
                                      : widget.data.l10n.get_ready,
                                  style: appStyle.fonts.B_16R.apply(
                                    color: appStyle.colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 28,
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                color: appStyle.colors.background,
                              ),
                              child: Row(
                                children: [
                                  FirkaIconWidget(
                                    FirkaIconType.majesticons,
                                    Majesticon.editPen4Solid,
                                    size: 12,
                                    color: appStyle.colors.accent,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    testsTomorrow == 0
                                        ? widget.data.l10n.no_tests_tomorrow
                                        : widget.data.l10n.tests_tomorrow(
                                            testsTomorrow.toString(),
                                          ),
                                    style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  carouselController: controller,
                  options: CarouselOptions(
                    initialPage: activeLessonIndex,
                    height: 106,
                    viewportFraction: 346 / 376,
                    enableInfiniteScroll: false,
                    onPageChanged: (index, reason) {
                      if (index == activeLessonIndex) {
                        swipeBack = -1;
                      } else if (reason == CarouselPageChangedReason.manual) {
                        swipeBack = 5;
                      }
                    },
                  ),
                ),
              ),
            if (lessons!.isNotEmpty) SizedBox(height: 12),
            if (lessons!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  FirkaIconWidget(
                    FirkaIconType.majesticonsLocal,
                    "sunSolid",
                    color: activeLessonIndex == 0
                        ? appStyle.colors.accent
                        : appStyle.colors.accent.withAlpha(128),
                    size: activeLessonIndex == 0 ? 16 : 12,
                  ),
                  ...lessons!.indexed.map(
                    (i) => FilledCircle(
                      diameter: activeLessonIndex == i.$1 + 1 ? 10 : 8,
                      color: activeLessonIndex == i.$1 + 1
                          ? appStyle.colors.accent
                          : appStyle.colors.accent.withAlpha(128),
                      child: SizedBox(),
                    ),
                  ),
                  FirkaIconWidget(
                    FirkaIconType.majesticons,
                    Majesticon.moonSolid,
                    color: activeLessonIndex == lessons!.length + 1
                        ? appStyle.colors.accent
                        : appStyle.colors.accent.withAlpha(128),
                    size: activeLessonIndex == lessons!.length + 1 ? 14 : 10,
                  ),
                ],
              ),
            if (lessons!.isNotEmpty) SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => fetchData(),
                notificationPredicate: (ScrollNotification notification) {
                  return notification.depth == 0;
                },
                triggerMode: RefreshIndicatorTriggerMode.onEdge,
                displacement: 0,
                child: ListView(
                  children: noticeBoardWidgets
                      .groupList((e) => e.$2)
                      .entries
                      .map(
                        (e) => Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.key.format(widget.data.l10n, FormatMode.main),
                              style: appStyle.fonts.B_16R.apply(
                                color: appStyle.colors.textSecondary,
                              ),
                            ),
                            ...e.value.map((v) => v.$1),
                            SizedBox(height: 10),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: appStyle.colors.background,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [DelayedSpinnerWidget()],
            ),
          ],
        ),
      );
    }
  }
}
