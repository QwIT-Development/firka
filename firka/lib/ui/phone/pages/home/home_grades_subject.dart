import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/helpers/ui/grade.dart';
import 'package:firka/helpers/ui/stateless_async_widget.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../main.dart';
import '../../../model/style.dart';

class HomeGradesSubjectScreen extends StatelessAsyncWidget {
  final AppInitialization data;
  final String subPageUid;

  const HomeGradesSubjectScreen(this.data, this.subPageUid, {super.key});

  @override
  Future<Widget> buildAsync(BuildContext context) async {
    var grades = (await data.client.getGrades())
        .response!
        .where((grade) => grade.subject.uid == subPageUid)
        .where((grade) => grade.type.name != "felevi_jegy_ertekeles");
    var aGrade = grades.first;
    var groups = grades.groupList((grade) => grade.recordDate);

    var gradeWidgets = List<Widget>.empty(growable: true);

    for (var group in groups.entries) {
      gradeWidgets.add(SizedBox(
        height: 8,
      ));
      gradeWidgets.add(Text(
        group.key.format(context, FormatMode.grades),
        style: appStyle.fonts.H_14px,
      ));
      gradeWidgets.add(SizedBox(
        height: 8,
      ));
      for (var grade in group.value) {
        gradeWidgets.add(FirkaCard(
          left: [
            Row(
              children: [
                GradeWidget(grade),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.topic ?? grade.type.description!,
                      style: appStyle.fonts.B_14SB,
                    ),
                    Text(
                      grade.mode?.description ?? "",
                      style: appStyle.fonts.B_14R,
                    )
                  ],
                )
              ],
            )
          ],
        ));
      }
    }

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.subjects,
                  style: appStyle
                      .fonts.H_16px // TODO: Replace this with the proper font
                      .apply(color: appStyle.colors.textPrimary),
                )
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  230,
              child: ListView(
                children: [
                  FirkaCard(
                    left: [
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              aGrade.subject.name,
                              style: appStyle.fonts.H_H2,
                            ),
                            Text(
                              aGrade.teacher, // For some reason the teacher's
                              // name isn't stored in the subject, so we need
                              // to get *a* grade, and then get the teacher's
                              // name from there :3
                              style: appStyle.fonts.B_14R,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: gradeWidgets,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
