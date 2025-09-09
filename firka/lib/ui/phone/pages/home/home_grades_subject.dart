import 'package:firka/helpers/api/model/grade.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/helpers/ui/grade.dart';
import 'package:firka/ui/phone/pages/home/home_grades.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/firka_state.dart';
import '../../../../helpers/update_notifier.dart';
import '../../../../main.dart';
import '../../../model/style.dart';
import '../../../widget/delayed_spinner.dart';

class HomeGradesSubjectScreen extends StatefulWidget {
  final AppInitialization data;
  final UpdateNotifier updateNotifier;
  final UpdateNotifier finishNotifier;

  const HomeGradesSubjectScreen(
      this.data, this.updateNotifier, this.finishNotifier,
      {super.key});

  @override
  State<StatefulWidget> createState() => _HomeGradesSubjectScreen();
}

class _HomeGradesSubjectScreen extends FirkaState<HomeGradesSubjectScreen> {
  Iterable<Grade>? grades;

  @override
  void didUpdateWidget(HomeGradesSubjectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.updateNotifier.removeListener(updateListener);
    widget.updateNotifier.addListener(updateListener);
  }

  void updateListener() async {
    grades = (await widget.data.client.getGrades(forceCache: false))
        .response!
        .where((grade) => grade.subject.uid == activeSubjectUid)
        .where((grade) => grade.type.name != "felevi_jegy_ertekeles");

    if (mounted) setState(() {});

    widget.finishNotifier.update();
  }

  @override
  void initState() {
    super.initState();

    widget.updateNotifier.addListener(updateListener);

    (() async {
      grades = (await widget.data.client.getGrades())
          .response!
          .where((grade) => grade.subject.uid == activeSubjectUid)
          .where((grade) => grade.type.name != "felevi_jegy_ertekeles");

      if (mounted) setState(() {});
    })();
  }

  @override
  void dispose() {
    super.dispose();
    widget.updateNotifier.removeListener(updateListener);
  }

  @override
  Widget build(BuildContext context) {
    if (grades != null && activeSubjectUid != "") {
      var aGrade = grades!.first;
      var groups = grades!.groupList((grade) => grade.recordDate);

      var gradeWidgets = List<Widget>.empty(growable: true);

      for (var group in groups.entries) {
        gradeWidgets.add(SizedBox(
          height: 8,
        ));
        gradeWidgets.add(Text(
          group.key.format(widget.data.l10n, FormatMode.grades),
          style:
              appStyle.fonts.H_14px.apply(color: appStyle.colors.textPrimary),
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
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 1.45,
                        child: Text(grade.topic ?? grade.type.description!,
                            style: appStyle.fonts.B_14SB),
                      ),
                      grade.mode?.description != null
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width / 1.45,
                              child: Text(
                                grade.mode!.description!,
                                style: appStyle.fonts.B_14R
                                    .apply(color: appStyle.colors.textPrimary),
                              ),
                            )
                          : SizedBox(),
                    ],
                  )
                ],
              )
            ],
          ));
        }
      }

      return Scaffold(
          backgroundColor: appStyle.colors.background,
          body: Padding(
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
                      widget.data.l10n.subjects,
                      style: appStyle.fonts
                          .H_16px // TODO: Replace this with the proper font
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
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 1.45,
                                  child: Text(
                                    aGrade.subject.name,
                                    style: appStyle.fonts.H_H2.apply(
                                        color: appStyle.colors.textPrimary),
                                  ),
                                ),
                                Text(
                                  aGrade
                                      .teacher, // For some reason the teacher's
                                  // name isn't stored in the subject, so we need
                                  // to get *a* grade, and then get the teacher's
                                  // name from there :3
                                  style: appStyle.fonts.B_14R.apply(
                                      color: appStyle.colors.textPrimary),
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
          ));
    } else {
      return Scaffold(
        backgroundColor: appStyle.colors.background,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [DelayedSpinnerWidget()],
            )
          ],
        ),
      );
    }
  }
}
