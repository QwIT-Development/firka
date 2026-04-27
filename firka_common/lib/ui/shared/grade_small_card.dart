import 'package:flutter/material.dart';
import 'package:kreta_api/kreta_api.dart';

import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/ui/components/grade_helpers.dart';
import 'package:firka_common/ui/shared/class_icon.dart';
import 'package:firka_common/ui/theme/style.dart';

class GradeSmallCard extends StatelessWidget {
  final double? studentAverage;
  final double? classAverage;
  final Subject subject;

  GradeSmallCard(
    List<Grade> grades,
    this.classAverage,
    this.subject, {
    super.key,
  }) : studentAverage = grades.getAverageBySubject(subject);

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
          if (classAverage != null)
            Container(
              width: 48,
              height: 26,
              decoration: ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: getGradeColor(classAverage!)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  classAverage!.toStringAsFixed(2),
                  style: appStyle.fonts.B_16R.apply(
                    color: getGradeColor(classAverage!),
                  ),
                ),
              ),
            ),
          if (studentAverage != null)
            Container(
              width: 48,
              height: 26,
              decoration: ShapeDecoration(
                color: getGradeColor(studentAverage!).withAlpha(38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  studentAverage!.toStringAsFixed(2),
                  style: appStyle.fonts.B_16R.apply(
                    color: getGradeColor(studentAverage!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
