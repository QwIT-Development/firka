import 'package:flutter/material.dart';
import 'package:kreta_api/kreta_api.dart';

import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/ui/components/grade_helpers.dart';
import 'package:firka_common/ui/shared/class_icon.dart';
import 'package:firka_common/ui/theme/style.dart';

import '../../firka_common.dart';

class GradeSmallCard extends StatelessWidget {
  final List<Grade> grades;
  final Subject subject;

  GradeSmallCard(this.grades, this.subject, {super.key});

  @override
  Widget build(BuildContext context) {
    return FirkaCard.single(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: 16),
      margin: EdgeInsets.all(0),
      child: Row(
        spacing: 8,
        children: [
          ClassIconWidget(
            uid: subject.uid,
            className: subject.name,
            category: subject.category.name!,
            color: appStyle.colors.accent,
            size: 20,
          ),
          Expanded(
            child: Text(
              subject.name,
              style: appStyle.fonts.B_16SB.apply(
                color: appStyle.colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          grades.getAverageBySubject(subject).isNaN
              ? const SizedBox()
              : Container(
                  width: 48,
                  height: 26,
                  decoration: ShapeDecoration(
                    color: getGradeColor(
                      grades.getAverageBySubject(subject),
                    ).withAlpha(38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      grades.getAverageBySubject(subject).toStringAsFixed(2),
                      style: appStyle.fonts.B_16R.apply(
                        color: getGradeColor(
                          grades.getAverageBySubject(subject),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
