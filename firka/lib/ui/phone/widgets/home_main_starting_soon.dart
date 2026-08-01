import 'package:firka/core/extensions.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/counter_digit.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';

class StartingSoonWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final List<LessonCacheModel> lessons;
  final DateTime now;

  const StartingSoonWidget(this.l10n, this.now, this.lessons, {super.key});

  @override
  Widget build(BuildContext context) {
    var diff = lessons.first.start.difference(now.min(lessons.first.start));
    var hour = diff.inHours % 60;
    var min = diff.inMinutes % 60;
    var sec = diff.inSeconds % 60;

    var hourTxt = hour == 1 ? l10n.starting_hour : l10n.starting_hour_plural;
    var minTxt = hour == 1 ? l10n.starting_min : l10n.starting_min_plural;
    var secTxt = hour == 1 ? l10n.starting_sec : l10n.starting_sec_plural;

    return FirkaCard.single(
      margin: EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.all(16),
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
                  FirkaIconType.majesticonsLocal,
                  "sunSolid",
                  size: 20,
                  color: appStyle.colors.accent,
                ),
              ),
              SizedBox(width: 8),
              Text(
                l10n.starting_soon,
                style: appStyle.fonts.B_16SB.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              CounterDigitWidget((hour / 10).floor().toString()),
              SizedBox(width: 4),
              CounterDigitWidget(((hour % 10)).toString()),
              SizedBox(width: 8),
              Text(
                hourTxt,
                style: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textSecondary,
                ),
              ),
              SizedBox(width: 8),
              CounterDigitWidget((min / 10).floor().toString()),
              SizedBox(width: 4),
              CounterDigitWidget(((min % 10)).toString()),
              SizedBox(width: 8),
              Text(
                minTxt,
                style: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textSecondary,
                ),
              ),
              SizedBox(width: 8),
              CounterDigitWidget((sec / 10).floor().toString()),
              SizedBox(width: 4),
              CounterDigitWidget(((sec % 10)).toString()),
              SizedBox(width: 8),
              Text(
                secTxt,
                style: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
