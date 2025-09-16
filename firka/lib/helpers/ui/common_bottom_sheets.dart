import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/api/model/grade.dart';
import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../main.dart';
import '../../ui/model/style.dart';
import '../../ui/phone/widgets/lesson.dart';
import '../../ui/widget/class_icon.dart';
import '../api/model/notice_board.dart';
import '../api/model/timetable.dart';
import 'firka_card.dart';
import 'grade.dart';

Future<void> showLessonBottomSheet(
    BuildContext context,
    AppInitialization data,
    Lesson lesson,
    int? lessonNo,
    Color accent,
    Color secondary,
    Color bgColor) async {
  final statsForNerdsEnabled = data.settings
      .group("settings")
      .subGroup("developer")
      .boolean("stats_for_nerds");
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height *
          (statsForNerdsEnabled ? 0.35 : 0.3),
    ),
    builder: (BuildContext context) {
      Widget statsForNerds = SizedBox();

      final y2k = DateTime(2000, 1);

      if (statsForNerdsEnabled) {
        final stats =
            "${data.l10n.stats_date}: ${lesson.start.isAfter(y2k) ? lesson.start.format(data.l10n, FormatMode.yyyymmddhhmmss) : "N/A"}\n"
            "${data.l10n.stats_created_at}: ${lesson.createdAt.isAfter(y2k) ? lesson.createdAt.format(data.l10n, FormatMode.yyyymmddhhmmss) : "N/A"}\n"
            "${data.l10n.stats_last_mod}: ${lesson.lastModifiedAt.isAfter(y2k) ? lesson.lastModifiedAt.format(data.l10n, FormatMode.yyyymmddhhmmss) : "N/A"}";
        statsForNerds = Text(stats,
            style:
                appStyle.fonts.B_16R.apply(color: appStyle.colors.textPrimary));
      }

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Stack(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/subtract.svg",
                                color: bgColor,
                                width: 18,
                                height: 18,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(lessonNo.toString(),
                                    style: appStyle.fonts.B_12R
                                        .apply(color: secondary)),
                              )
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(-4, 0),
                          child: Card(
                            shadowColor: Colors.transparent,
                            color: bgColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: EdgeInsetsGeometry.all(4),
                              child: ClassIconWidget(
                                color: accent,
                                size: 20,
                                uid: lesson.uid,
                                className: lesson.name,
                                category: lesson.subject?.name ?? '',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${lesson.name} ${statsForNerdsEnabled ? "(${lesson.classGroup?.name ?? ''})" : ""}",
                            style: appStyle.fonts.H_18px
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                          Text(
                            lesson.teacher ?? 'N/A',
                            style: appStyle.fonts.B_14R
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                          Text(
                            '${lesson.start.format(data.l10n, FormatMode.hmm)} - ${lesson.end.format(data.l10n, FormatMode.hmm)}',
                            style: appStyle.fonts.B_14R
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    FirkaCard(left: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.l10n.lesson_subject,
                            style: appStyle.fonts.H_14px
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            lesson.theme ?? 'N/A',
                            style: appStyle.fonts.B_16R
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          statsForNerds
                        ],
                      )
                    ])
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> showGradeBottomSheet(
    BuildContext context, AppInitialization data, Grade grade) async {
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(
      minHeight: MediaQuery.of(context).size.height * 0.34,
    ),
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [GradeWidget(grade)],
                    ),
                    SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(grade.topic ?? grade.type.description!,
                              style: appStyle.fonts.H_18px
                                  .apply(color: appStyle.colors.textPrimary)),
                          grade.mode?.description != null
                              ? SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 1.45,
                                  child: Text(
                                    grade.mode!.description!,
                                    style: appStyle.fonts.B_14R.apply(
                                        color: appStyle.colors.textSecondary),
                                  ),
                                )
                              : SizedBox(),
                          SizedBox(
                            height: 20,
                          ),
                          LessonWidget(
                            data,
                            [],
                            -1,
                            Lesson(
                                uid: "-1",
                                date: "",
                                start: grade.creationDate,
                                end: grade.creationDate,
                                name: grade.subject.name,
                                type: NameUidDesc(
                                    uid: "", name: "", description: ""),
                                state: NameUidDesc(
                                    uid: "", name: "", description: ""),
                                canStudentEditHomework: false,
                                isHomeworkComplete: false,
                                attachments: [],
                                isDigitalLesson: false,
                                digitalSupportDeviceTypeList: [],
                                createdAt: timeNow(),
                                subject: grade.subject,
                                lastModifiedAt: timeNow()),
                            null,
                            null,
                            placeholderMode: true,
                          ),
                          FirkaCard(left: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${data.l10n.tt_added}${grade.creationDate}",
                                    style: appStyle.fonts.B_14R.apply(
                                        color: appStyle.colors.textPrimary),
                                  ),
                                  Text(
                                    "${data.l10n.grade_teacherName}${grade.teacher}",
                                    style: appStyle.fonts.B_14R.apply(
                                        color: appStyle.colors.textPrimary),
                                  ),
                                  Text(
                                    "${data.l10n.grade_strValue}${grade.strValue}",
                                    style: appStyle.fonts.B_14R.apply(
                                        color: appStyle.colors.textPrimary),
                                  )
                                ])
                          ])
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> showAnnouncementBottomSheet(
    BuildContext context, AppInitialization data, InfoBoardItem info) async {
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: Text(
                            info.title,
                            textAlign: TextAlign.center,
                            style: appStyle.fonts.H_H2
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          info.date.format(data.l10n, FormatMode.yyyymmdd),
                          textAlign: TextAlign.center,
                          style: appStyle.fonts.B_14R
                              .apply(color: appStyle.colors.textSecondary),
                        ),
                      ],
                    ),
                    SizedBox(height: 56),
                    Row(
                      children: [
                        Container(
                          decoration: ShapeDecoration(
                              color: appStyle.colors.accent,
                              shape: CircleBorder(
                                eccentricity: 1,
                              )),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    info.author[0],
                                    style: appStyle.fonts.H_18px.copyWith(
                                        fontSize: 20,
                                        color: appStyle.colors.textPrimary),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 1.4,
                              child: Text(
                                info.author,
                                style: appStyle.fonts.B_14SB
                                    .apply(color: appStyle.colors.textPrimary),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                            color: appStyle.colors.card,
                            borderRadius:
                                BorderRadius.all(Radius.circular(16))),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            info.contentText,
                            style: appStyle.fonts.B_16R
                                .apply(color: appStyle.colors.textPrimary),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
