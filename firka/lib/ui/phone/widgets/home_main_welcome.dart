import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:kreta_api/kreta_api.dart';
import 'package:firka/ui/theme/style.dart';

class WelcomeWidget extends StatefulWidget {
  final AppLocalizations l10n;
  final Student student;
  final List<Lesson> lessons;
  final DateTime now;

  const WelcomeWidget(
    this.l10n,
    this.now,
    this.student,
    this.lessons, {
    super.key,
  });

  @override
  State<WelcomeWidget> createState() => _WelcomeWidgetState();
}

class _WelcomeWidgetState extends State<WelcomeWidget> {
  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    _controllerCenter = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    final birthDate = DateFormat("MM-dd").format(widget.student.birthdate);
    if (birthDate == DateFormat("MM-dd").format(widget.now)) {
      _controllerCenter.play();
    }
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  Widget getIconForCycle(Cycle dayCycle) {
    switch (dayCycle) {
      case Cycle.morning:
        return FirkaIconWidget(
          FirkaIconType.majesticonsLocal,
          "sunSolid",
          color: appStyle.colors.accent,
        );
      case Cycle.day:
        return FirkaIconWidget(
          FirkaIconType.majesticonsLocal,
          "parkSolidSchool",
          color: appStyle.colors.accent,
        );
      case Cycle.afternoon:
        return FirkaIconWidget(
          FirkaIconType.majesticons,
          Majesticon.moonSolid,
          color: appStyle.colors.accent,
        );
      case Cycle.night:
        return FirkaIconWidget(
          FirkaIconType.majesticons,
          Majesticon.moonSolid,
          color: appStyle.colors.accent,
        );
    }
  }

  String getRawTitle(String name, Cycle dayCycle) {
    switch (dayCycle) {
      case Cycle.morning:
        return widget.l10n.good_morning(name);
      case Cycle.day:
        return widget.l10n.good_day(name);
      case Cycle.afternoon:
        return widget.l10n.good_afternoon(name);
      case Cycle.night:
        return widget.l10n.good_night(name);
    }
  }

  String getTitle(Cycle dayCycle) {
    var name = "";

    try {
      name = widget.student.name.split(" ")[1];
    } catch (ex) {
      name = widget.student.name;
    }

    final birthDate = DateFormat("MM-dd").format(widget.student.birthdate);
    if (birthDate == DateFormat("MM-dd").format(widget.now)) {
      return widget.l10n.happy_birthday(name);
    } else if (widget.lessons.length > 1 &&
        widget.now.isBefore(widget.lessons.first.start)) {
      return getRawTitle(name, dayCycle);
    } else {
      return getRawTitle(name, dayCycle);
    }
  }

  String getSubtitle(Cycle dayCycle) {
    final now = widget.now;
    final lessons = widget.lessons;
    final l10n = widget.l10n;

    if (lessons.isEmpty) {
      return now.format(l10n, FormatMode.welcome);
    } else {
      if (now.isBefore(lessons.first.start)) {
        return now.format(l10n, FormatMode.welcome);
      }
      var lessonsLeft = lessons
          .where((lesson) => lesson.end.isAfter(now))
          .length;
      if (lessonsLeft < 1) {
        return l10n.tomorrow_subtitle;
      }
      if (lessonsLeft == 1) {
        return l10n.suffering_almost_over_subtitle;
      }
      if (lessonsLeft <= 3) {
        return l10n.n_left_subtitle(lessonsLeft);
      }

      return now.format(l10n, FormatMode.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    var dayCycle = widget.now.getDayCycle();

    return Stack(
      alignment: Alignment.center,
      children: [
        ConfettiWidget(
          confettiController: _controllerCenter,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 10,
          gravity: 0.4,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            getIconForCycle(dayCycle),
            const SizedBox(height: 16.0),
            Text(
              getTitle(dayCycle),
              style: appStyle.fonts.H_H2.copyWith(
                color: appStyle.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              getSubtitle(dayCycle),
              style: appStyle.fonts.B_16R.copyWith(
                color: appStyle.colors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
