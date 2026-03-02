import 'package:flutter/material.dart';
import 'package:kreta_api/kreta_api.dart';

import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/ui/components/grade_helpers.dart';
import 'package:firka_common/ui/shared/class_icon.dart';
import 'package:firka_common/ui/theme/style.dart';

class GradeSmallCard extends FirkaCard {
  final List<Grade> grades;
  final Subject subject;

  GradeSmallCard(this.grades, this.subject, {super.key})
    : super(
        left: [
          ClassIconWidget(
            uid: subject.uid,
            className: subject.name,
            category: subject.category.name!,
            color: appStyle.colors.accent,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 200,
            child: Text(
              subject.name,
              style: appStyle.fonts.B_16SB.apply(
                color: appStyle.colors.textPrimary,
              ),
            ),
          ),
        ],
        right: [
          grades.getAverageBySubject(subject).isNaN
              ? const SizedBox()
              : Card(
                  shadowColor: Colors.transparent,
                  color: getGradeColor(
                    grades.getAverageBySubject(subject),
                  ).withAlpha(38),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 4,
                      bottom: 4,
                    ),
                    child: Text(
                      grades.getAverageBySubject(subject).toStringAsFixed(2),
                      style: appStyle.fonts.B_16SB.apply(
                        color: getGradeColor(
                          grades.getAverageBySubject(subject),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      );
}
