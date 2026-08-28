import 'dart:math';

import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/phone/screens/surprise_grades/surprise_grades_screen.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _cardIcon = "assets/images/surprise_grades/play_card_star.svg";

class NewGradesWidget extends StatelessWidget {
  static const _designWidth = 336.0;
  static const _miniWidth = 90.117;
  static const _tilt = 15 * pi / 180;

  static const _slots = [
    (172.04, 46.86, -_tilt, 1),
    (302.63, 20.32, _tilt, 2),
    (222.92, 9.0, 0.0, 0),
  ];

  final AppLocalizations l10n;
  final List<GradeCacheModel> grades;
  final VoidCallback? onTap;

  const NewGradesWidget(this.l10n, this.grades, {this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FirkaCard.single(
        margin: EdgeInsets.only(bottom: 1),
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final s = constraints.maxWidth / _designWidth;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final (left, top, angle, index) in _slots)
                    if (index < grades.length)
                      Positioned(
                        left: left * s,
                        top: top * s,
                        child: Transform.rotate(
                          angle: angle,
                          child: SurpriseGradeMiniCard(
                            grades[index],
                            l10n,
                            width: _miniWidth * s,
                          ),
                        ),
                      ),
                  Positioned(left: 16 * s, top: 16 * s, child: _icon(s)),
                  Positioned(
                    left: 16 * s,
                    top: 67 * s,
                    child: Text(
                      l10n.new_grades_card,
                      style: appStyle.fonts.B_16SB.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _icon(double s) {
    return Container(
      width: 32 * s,
      height: 32 * s,
      decoration: BoxDecoration(
        color: appStyle.colors.a15p,
        borderRadius: BorderRadius.circular(16 * s),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        _cardIcon,
        width: 20 * s,
        height: 20 * s,
        color: appStyle.colors.accent,
      ),
    );
  }
}
