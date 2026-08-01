import 'dart:async';
import 'dart:collection';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/homework_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/message_cache_model.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:firka_common/data/models/test_cache_model.dart';
import 'package:firka/ui/phone/widgets/info_card.dart';
import 'package:firka/ui/phone/widgets/lesson.dart';
import 'package:firka/ui/phone/widgets/lesson_slider.dart';
import 'package:firka_common/data/util.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:flutter/rendering.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/ui/phone/widgets/home_main_starting_soon.dart';
import 'package:firka/ui/shared/delayed_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka_common/ui/components/firka_card.dart';
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

  void _onRefreshRequested(BuildContext context) async {
    final cubit = context.read<HomeRefreshCubit>();
    if (mounted) {
      setState(() {});
      cubit.onRefreshComplete();
    }
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
    final now = timeNow();
    final infoItems = widget.data.client!.cache.getMessages().findAllSync();
    final gradeItems = widget.data.client!.cache.getGrades().findAllSync();
    final testItems = widget.data.client!.cache.getTests().findAllSync();
    final homeworkItems = widget.data.client!.cache
        .getHomeworks()
        .findAllSync();
    final omissionItems = widget.data.client!.cache
        .getOmissions()
        .findAllSync()
        .groupList((o) => o.lesson.loadAndGet()!.start);
    final noticeBoardWidgets = <(Widget, DateTime)>[];
    final todayLesson = widget.data.client!.cache
        .getClassLessons()
        .on(now)
        .findAllSync();

    for (final item in infoItems) {
      noticeBoardWidgets.add((InfoCard.messageItem(item), item.createdAt));
    }

    for (final test in testItems) {
      noticeBoardWidgets.add((InfoCard.test(test), test.createdAt));
    }

    for (final grade in gradeItems) {
      noticeBoardWidgets.add((InfoCard.gradeSubj(grade), grade.createdAt));
    }

    for (final entry in homeworkItems) {
      noticeBoardWidgets.add((InfoCard.homework(entry), entry.createdAt));
    }

    for (final entry in omissionItems.entries) {
      noticeBoardWidgets.add((InfoCard.omission(entry.value), entry.key));
    }

    noticeBoardWidgets.sort(
      (item1, item2) => item2.$2.difference(item1.$2).inMilliseconds,
    );

    int testsTomorrow = testItems
        .where(
          (test) =>
              test.lesson.loadAndGet() != null &&
              test.lesson.loadAndGet()!.start.isAfter(
                now.getMidnight().add(Duration(hours: 23, minutes: 59)),
              ) &&
              test.lesson.loadAndGet()!.start.isBefore(
                now.getMidnight().add(Duration(days: 2)),
              ),
        )
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: RefreshIndicator(
        onRefresh: () => Future.value(),
        notificationPredicate: (ScrollNotification notification) {
          return notification.depth == 0;
        },
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        displacement: 0,
        child: ListView(
          clipBehavior: Clip.none,
          children: [
            SizedBox(height: 24),
            WelcomeWidget(
              widget.data.l10n,
              now,
              widget.data.client!.cache.findStudent(),
              todayLesson,
            ),
            SizedBox(height: 48),
            LessonSlider(todayLesson, testsTomorrow),
            SizedBox(height: 24),
            ...noticeBoardWidgets
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
                ),
          ],
        ),
      ),
    );
  }
}
