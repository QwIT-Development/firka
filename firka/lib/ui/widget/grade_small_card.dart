import 'package:firka/helpers/api/model/grade.dart';
import 'package:firka/helpers/api/model/subject.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/helpers/ui/grade_helpers.dart';
import 'package:firka/ui/widget/class_icon.dart';
import 'package:flutter/material.dart';

import '../model/style.dart';

class GradeSmallCard extends FirkaCard {
  final List<Grade> grades;
  final Subject subject;

  GradeSmallCard(this.grades, this.subject, {super.key})
      : super(left: [
          ClassIconWidget(
            uid: subject.uid,
            className: subject.name,
            category: subject.category.name!,
            color: appStyle.colors.accent,
          ),
          SizedBox(
            width: 4,
          ),
          SizedBox(
            width: 200,
            child: Text(
              subject.name,
              style: appStyle.fonts.B_16SB
                  .apply(color: appStyle.colors.textPrimary),
            ),
          ),
        ], right: [
          grades.getAverageBySubject(subject).isNaN
              ? SizedBox()
              : Card(
                  shadowColor: Colors.transparent,
                  color: getGradeColor(grades.getAverageBySubject(subject))
                      .withAlpha(38),
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                    child: Text(
                      grades.getAverageBySubject(subject).toStringAsFixed(2),
                      style: appStyle.fonts.B_16SB.apply(
                          color: getGradeColor(
                              grades.getAverageBySubject(subject))),
                    ),
                  ),
                ),
        ]);
}
