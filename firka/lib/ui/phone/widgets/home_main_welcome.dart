import 'package:firka/helpers/extensions.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../helpers/api/model/student.dart';
import '../../../helpers/api/model/timetable.dart';
import '../../model/style.dart';

class WelcomeWidget extends StatelessWidget {
  final Student student;
  final List<Lesson> lessons;
  final DateTime now;

  const WelcomeWidget(this.now, this.student, this.lessons, {super.key});

  getIconForCycle(Cycle dayCycle) {
    switch (dayCycle) {
      case Cycle.morning:
        return FirkaIconWidget(FirkaIconType.MajesticonsLocal, "sunSolid",
            color: appStyle.colors.accent);
      case Cycle.day:
        return FirkaIconWidget(
            FirkaIconType.MajesticonsLocal, "parkSolidSchool",
            color: appStyle.colors.accent);
      case Cycle.afternoon:
        return FirkaIconWidget(FirkaIconType.Majesticons, Majesticon.moonSolid,
            color: appStyle.colors.accent);
      case Cycle.night:
        return FirkaIconWidget(FirkaIconType.Majesticons, Majesticon.moonSolid,
            color: appStyle.colors.accent);
    }
  }

  String getRawTitle(BuildContext context, String name, Cycle dayCycle) {
    switch (dayCycle) {
      case Cycle.morning:
        return AppLocalizations.of(context)!.good_morning(name);
      case Cycle.day:
        return AppLocalizations.of(context)!.good_day(name);
      case Cycle.afternoon:
        return AppLocalizations.of(context)!.good_afternoon(name);
      case Cycle.night:
        return AppLocalizations.of(context)!.good_night(name);
    }
  }

  String getTitle(BuildContext context, Cycle dayCycle) {
    var name = "";

    try {
      name = student.name.split(" ")[1];
    } catch (ex) {
      name = student.name;
    }

    if (lessons.isEmpty) {
      return getRawTitle(context, name, dayCycle);
    } else {
      if (now.isBefore(lessons.first.start)) {
        return getRawTitle(context, name, dayCycle);
      }
      return getRawTitle(context, name, dayCycle);
    }
  }

  String getSubtitle(BuildContext context, Cycle dayCycle) {
    if (lessons.isEmpty) {
      return now.format(context, FormatMode.welcome);
    } else {
      if (now.isBefore(lessons.first.start)) {
        return now.format(context, FormatMode.welcome);
      }
      var lessonsLeft =
          lessons.where((lesson) => lesson.start.isAfter(now)).length;
      if (lessonsLeft < 1) {
        return AppLocalizations.of(context)!.tomorrow_subtitle;
      }
      if (lessonsLeft == 1) {
        return AppLocalizations.of(context)!.suffering_almost_over_subtitle;
      }
      if (lessonsLeft <= 3) {
        return AppLocalizations.of(context)!.n_left_subtitle(lessonsLeft);
      }

      return now.format(context, FormatMode.welcome);
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
        Text(getTitle(context, dayCycle),
            style: appStyle.fonts.H_H2
                .copyWith(color: appStyle.colors.textPrimary)),
        const SizedBox(height: 2.0),
        Text(getSubtitle(context, dayCycle),
            style: appStyle.fonts.B_14R
                .copyWith(color: appStyle.colors.textSecondary)),
      ],
    );
  }
}
