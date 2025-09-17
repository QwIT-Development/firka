import 'package:firka/helpers/extensions.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../helpers/api/model/student.dart';
import '../../../helpers/api/model/timetable.dart';
import '../../model/style.dart';

class WelcomeWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final Student student;
  final List<Lesson> lessons;
  final DateTime now;

  const WelcomeWidget(this.l10n, this.now, this.student, this.lessons,
      {super.key});

  getIconForCycle(Cycle dayCycle) {
    switch (dayCycle) {
      case Cycle.morning:
        return FirkaIconWidget(FirkaIconType.majesticonsLocal, "sunSolid",
            color: appStyle.colors.accent);
      case Cycle.day:
        return FirkaIconWidget(
            FirkaIconType.majesticonsLocal, "parkSolidSchool",
            color: appStyle.colors.accent);
      case Cycle.afternoon:
        return FirkaIconWidget(FirkaIconType.majesticons, Majesticon.moonSolid,
            color: appStyle.colors.accent);
      case Cycle.night:
        return FirkaIconWidget(FirkaIconType.majesticons, Majesticon.moonSolid,
            color: appStyle.colors.accent);
    }
  }

  String getRawTitle(String name, Cycle dayCycle) {
    switch (dayCycle) {
      case Cycle.morning:
        return l10n.good_morning(name);
      case Cycle.day:
        return l10n.good_day(name);
      case Cycle.afternoon:
        return l10n.good_afternoon(name);
      case Cycle.night:
        return l10n.good_night(name);
    }
  }

  String getTitle(Cycle dayCycle) {
    var name = "";

    try {
      name = student.name.split(" ")[1];
    } catch (ex) {
      name = student.name;
    }

    if (lessons.isEmpty) {
      return getRawTitle(name, dayCycle);
    } else {
      if (now.isBefore(lessons.first.start)) {
        return getRawTitle(name, dayCycle);
      }
      return getRawTitle(name, dayCycle);
    }
  }

  String getSubtitle(Cycle dayCycle) {
    if (lessons.isEmpty) {
      return now.format(l10n, FormatMode.welcome);
    } else {
      if (now.isBefore(lessons.first.start)) {
        return now.format(l10n, FormatMode.welcome);
      }
      var lessonsLeft =
          lessons.where((lesson) => lesson.end.isAfter(now)).length;
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
    var dayCycle = now.getDayCycle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        getIconForCycle(dayCycle),
        const SizedBox(height: 16.0),
        Text(getTitle(dayCycle),
            style: appStyle.fonts.H_H2
                .copyWith(color: appStyle.colors.textPrimary)),
        const SizedBox(height: 2.0),
        Text(getSubtitle(dayCycle),
            style: appStyle.fonts.B_16R
                .copyWith(color: appStyle.colors.textSecondary)),
      ],
    );
  }
}
