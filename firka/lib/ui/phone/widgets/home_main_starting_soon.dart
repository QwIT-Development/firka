import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/widget/counter_digit.dart';
import 'package:flutter/material.dart';

import '../../../helpers/api/model/timetable.dart';

class StartingSoonWidget extends StatelessWidget {
  final List<Lesson> lessons;
  final DateTime now;

  const StartingSoonWidget(this.now, this.lessons, {super.key});

  @override
  Widget build(BuildContext context) {
    var diff = lessons.first.start.difference(now);
    var hour = diff.inHours % 60;
    var min = diff.inMinutes % 60;
    var sec = diff.inSeconds % 60;

    var hourTxt = hour == 1
        ? AppLocalizations.of(context)!.starting_hour
        : AppLocalizations.of(context)!.starting_hour_plural;
    var minTxt = hour == 1
        ? AppLocalizations.of(context)!.starting_min
        : AppLocalizations.of(context)!.starting_min_plural;
    var secTxt = hour == 1
        ? AppLocalizations.of(context)!.starting_sec
        : AppLocalizations.of(context)!.starting_sec_plural;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FirkaCard(
          left: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.starting_soon,
                      style: appStyle.fonts.H_16px
                          .apply(color: appStyle.colors.textPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CounterDigitWidget(
                        hour.toString(),
                        appStyle.fonts.H_16px
                            .apply(color: appStyle.colors.textPrimary)),
                    SizedBox(width: 2),
                    Text(
                      hourTxt,
                      style: appStyle.fonts.B_16R
                          .apply(color: appStyle.colors.textPrimary),
                    ),
                    SizedBox(width: 4),
                    CounterDigitWidget(
                        (min / 10).floor().toString(),
                        appStyle.fonts.H_16px
                            .apply(color: appStyle.colors.textPrimary)),
                    CounterDigitWidget(
                        ((min % 10)).toString(),
                        appStyle.fonts.H_16px
                            .apply(color: appStyle.colors.textPrimary)),
                    SizedBox(width: 2),
                    Text(
                      minTxt,
                      style: appStyle.fonts.B_16R
                          .apply(color: appStyle.colors.textPrimary),
                    ),
                    SizedBox(width: 4),
                    CounterDigitWidget(
                        (sec / 10).floor().toString(),
                        appStyle.fonts.H_16px
                            .apply(color: appStyle.colors.textPrimary)),
                    CounterDigitWidget(
                        ((sec % 10)).toString(),
                        appStyle.fonts.H_16px
                            .apply(color: appStyle.colors.textPrimary)),
                    SizedBox(width: 2),
                    Text(
                      secTxt,
                      style: appStyle.fonts.B_16R
                          .apply(color: appStyle.colors.textPrimary),
                    ),
                  ],
                )
              ],
            )
          ],
          right: [],
        )
      ],
    );
  }
}
