import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka/ui/phone/widgets/info_card.dart';
import 'package:firka/ui/phone/widgets/lesson_slider.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:firka/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/bloc/toast_cubit.dart';
import 'package:firka/ui/shared/delayed_spinner.dart';
import 'package:firka/ui/theme/style.dart';
import '../../widgets/home_main_welcome.dart';

class HomeMainScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeMainScreen(this.data, {super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreen();
}

class _HomeMainScreen extends FirkaState<HomeMainScreen> {
  _HomeMainScreen();

  // After the first frame, newly inserted notice groups fade in.
  // Groups present on the initial paint (warm cache) stay instant.
  bool _fadeNewInserts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _fadeNewInserts = true);
    });
  }

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
      child: BlocBuilder<ToastCubit, ToastState>(
        buildWhen: (previous, current) => previous.type != current.type,
        builder: (context, toastState) => _buildContent(context, toastState),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ToastState toastState) {
    final now = timeNow();
    final student = widget.data.client!.cache.findStudentOrNull();
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

    final bodyEmpty = todayLesson.isEmpty && noticeBoardWidgets.isEmpty;
    final showInnerSpinner =
        toastState.type == ActiveToastType.fetching && bodyEmpty;

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
            _FadeInWhenLoaded(
              loaded: student != null,
              child: student != null
                  ? WelcomeWidget(
                      widget.data.l10n,
                      now,
                      student,
                      todayLesson,
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(height: 48),
            if (showInnerSpinner)
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.35,
                child: const Center(child: DelayedSpinnerWidget()),
              ),
            _FadeInWhenLoaded(
              loaded: todayLesson.isNotEmpty,
              child: LessonSlider(todayLesson, testsTomorrow),
            ),
            SizedBox(height: 24),
            ...noticeBoardWidgets
                .groupList((e) => e.$2)
                .entries
                .map(
                  (e) => _FadeInOnInsert(
                    key: ValueKey(e.key),
                    animate: _fadeNewInserts,
                    child: Column(
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
                ),
          ],
        ),
      ),
    );
  }
}

/// Fades in when [loaded] flips from false to true. First paint with data is instant.
class _FadeInWhenLoaded extends StatelessWidget {
  const _FadeInWhenLoaded({
    required this.loaded,
    required this.child,
  });

  final bool loaded;
  final Widget child;

  static const _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _duration,
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: loaded
          ? KeyedSubtree(key: const ValueKey("content"), child: child)
          : const SizedBox.shrink(key: ValueKey("empty")),
    );
  }
}

/// Fades newly inserted list sections. Skips animation when [animate] is false (warm cache).
class _FadeInOnInsert extends StatefulWidget {
  const _FadeInOnInsert({
    super.key,
    required this.animate,
    required this.child,
  });

  final bool animate;
  final Widget child;

  @override
  State<_FadeInOnInsert> createState() => _FadeInOnInsertState();
}

class _FadeInOnInsertState extends State<_FadeInOnInsert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.animate ? 0 : 1,
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curved);
    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
