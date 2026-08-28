import 'dart:async';
import 'dart:collection';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka_common/core/consts.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/routing/chart_interaction_scope.dart';
import 'package:firka/ui/phone/widgets/home_main_new_grades.dart';
import 'package:firka/ui/phone/widgets/home_main_starting_soon.dart';
import 'package:firka/ui/phone/widgets/lesson_big.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:firka_common/core/debug_helper.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/ui/theme/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

class _LessonSliderState extends State<LessonSlider> {
  DateTime now = timeNow();
  int? swipeBack;
  late Timer timer;
  int? activeLessonIndex;
  int? centeredPageIndex;
  CarouselSliderController controller = CarouselSliderController();

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (widget.lessons.isEmpty || !mounted) return;
      setState(() {
        if (swipeBack != null) swipeBack = swipeBack! - 1;
        now = timeNow();
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNewGrades = widget.newGrades.isNotEmpty;
    final hasLessons = widget.lessons.isNotEmpty;

    if (!hasNewGrades && !hasLessons) {
      return SizedBox();
    }

    final offset = hasNewGrades ? 1 : 0;

    LessonCacheModel? currentLesson;
    int tmpIndex;
    if (!hasLessons) {
      tmpIndex = 0;
    } else if (now.isBefore(widget.lessons.first.start)) {
      tmpIndex = 0;
    } else {
      (int, LessonCacheModel)? currentIndex = widget.lessons.indexed
          .firstWhereOrNull((e) => now.isBefore(e.$2.end));

      tmpIndex = (currentIndex?.$1 ?? widget.lessons.length) + 1;
      if (currentIndex != null) {
        currentLesson = currentIndex.$2;
      }
    }

    if (activeLessonIndex == null || tmpIndex != activeLessonIndex) {
      activeLessonIndex = tmpIndex;
      swipeBack = 0;
    }

    final initialPage = hasNewGrades ? 0 : activeLessonIndex!;
    centeredPageIndex ??= initialPage;

    if (controller.ready && swipeBack == 0 && !hasNewGrades) {
      controller.animateToPage(activeLessonIndex!);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      spacing: 12,
      children: [
        OverflowBox(
          maxWidth: MediaQuery.widthOf(context),
          fit: OverflowBoxFit.deferToChild,
          child: Listener(
            behavior: HitTestBehavior.deferToChild,
            onPointerDown: (_) =>
                ChartInteractionScope.of(context).value = true,
            onPointerUp: (_) => ChartInteractionScope.of(context).value = false,
            onPointerCancel: (_) =>
                ChartInteractionScope.of(context).value = false,
            child: CarouselSlider(
              items: [
                if (hasNewGrades)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: NewGradesWidget(
                      initData.l10n,
                      widget.newGrades,
                      onTap: widget.onNewGradesTap,
                    ),
                  ),
                if (hasLessons)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: StartingSoonWidget(
                      initData.l10n,
                      now,
                      widget.lessons,
                    ),
                  ),
                ...widget.lessons.map(
                  (entry) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: LessonBigWidget(
                      initData,
                      entry,
                      active: currentLesson == entry,
                    ),
                  ),
                ),
                if (hasLessons)
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
                                widget.tomorrowTestAmount == 0
                                    ? initData.l10n.tt_no_classes_l2
                                    : initData.l10n.get_ready,
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
                                  widget.tomorrowTestAmount == 0
                                      ? initData.l10n.no_tests_tomorrow
                                      : initData.l10n.tests_tomorrow(
                                          widget.tomorrowTestAmount.toString(),
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
                initialPage: initialPage,
                height: 106,
                viewportFraction: 346 / 376,
                enableInfiniteScroll: false,
                onPageChanged: (index, reason) {
                  centeredPageIndex = index;
                  if (index == activeLessonIndex! + offset) {
                    swipeBack = null;
                  } else if (reason == CarouselPageChangedReason.manual) {
                    swipeBack = 5;
                  } else {
                    return;
                  }
                  setState(() {});
                },
              ),
            ),
          ),
        ),
        SizedBox(
          height: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              if (hasNewGrades)
                FirkaIconWidget(
                  FirkaIconType.majesticons,
                  Majesticon.shootingStarSolid,
                  color: centeredPageIndex == 0
                      ? appStyle.colors.accent
                      : appStyle.colors.accent.withAlpha(128),
                  size: centeredPageIndex == 0 ? 16 : 12,
                ),
              if (hasLessons) ...[
                FirkaIconWidget(
                  FirkaIconType.majesticonsLocal,
                  "sunSolid",
                  color: centeredPageIndex == offset
                      ? appStyle.colors.accent
                      : appStyle.colors.accent.withAlpha(128),
                  size: centeredPageIndex == offset ? 16 : 12,
                ),
                ...widget.lessons.indexed.map(
                  (i) => FilledCircle(
                    diameter: centeredPageIndex == i.$1 + 1 + offset ? 10 : 8,
                    color: centeredPageIndex == i.$1 + 1 + offset
                        ? appStyle.colors.accent
                        : appStyle.colors.accent.withAlpha(128),
                    child: SizedBox(),
                  ),
                ),
                FirkaIconWidget(
                  FirkaIconType.majesticons,
                  Majesticon.moonSolid,
                  color: centeredPageIndex == widget.lessons.length + 1 + offset
                      ? appStyle.colors.accent
                      : appStyle.colors.accent.withAlpha(128),
                  size: centeredPageIndex == widget.lessons.length + 1 + offset
                      ? 16
                      : 12,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class LessonSlider extends StatefulWidget {
  final List<LessonCacheModel> lessons;
  final int tomorrowTestAmount;
  final List<GradeCacheModel> newGrades;
  final VoidCallback? onNewGradesTap;

  LessonSlider(
    Iterable<LessonCacheModel> lessons,
    this.tomorrowTestAmount, {
    this.newGrades = const [],
    this.onNewGradesTap,
    super.key,
  }) : lessons = lessons
           .where(((l) => l.type != TimetableConsts.event))
           .toList();

  @override
  State<StatefulWidget> createState() => _LessonSliderState();
}
