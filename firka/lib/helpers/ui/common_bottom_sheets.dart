import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/api/model/grade.dart';
import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:firka/helpers/settings.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../../ui/model/style.dart';
import '../../ui/phone/screens/home/home_screen.dart';
import '../../ui/phone/widgets/lesson.dart';
import '../../ui/widget/class_icon.dart';
import '../api/model/timetable.dart';
import 'firka_card.dart';
import 'grade.dart';
import '../../helpers/api/model/test.dart';

Future<void> showLessonBottomSheet(
    BuildContext context,
    AppInitialization data,
    Lesson lesson,
    int? lessonNo,
    Color accent,
    Color secondary,
    Color bgColor,
    Test? test,

    ) async {
  final statsForNerdsEnabled = data.settings
      .group("settings")
      .subGroup("developer")
      .boolean("stats_for_nerds");

  final showTests = data.settings
        .group("settings")
        .subGroup("timetable_toast")
        .boolean("tests_and_homework");
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
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
                padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                                category: lesson.subject?.name != null
                                    ? lesson.subject!.name.firstUpper()
                                    : '',
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
                          Row(children: [
                            Text(
                              "${lesson.name} ${statsForNerdsEnabled ? "(${lesson.classGroup?.name ?? ''})" : ""}",
                              style: appStyle.fonts.H_18px
                                  .apply(color: appStyle.colors.textPrimary),
                            ),
                            Card(
                              shadowColor: Colors.transparent,
                              color: appStyle.colors.a15p,
                              child: Padding(
                                padding: EdgeInsets.all(4),
                                child: Text(lesson.roomName ?? 'N/A',
                                    style: appStyle.fonts.B_12R.apply(
                                        color: appStyle.colors.secondary)),
                              ),
                            ),
                          ]),
                          Text(
                            lesson.teacher ?? 'N/A',
                            style: appStyle.fonts.B_16R
                                .apply(color: appStyle.colors.textPrimary),
                          ),
                          Text(
                            '${lesson.start.format(data.l10n, FormatMode.hmm)} - ${lesson.end.format(data.l10n, FormatMode.hmm)}',
                            style: appStyle.fonts.B_16R
                                .apply(color: appStyle.colors.textSecondary),
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
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Text(
                                lesson.theme ?? 'N/A',
                                style: appStyle.fonts.B_16R
                                  .apply(color: appStyle.colors.textPrimary),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          SizedBox(height: 4),
                          statsForNerds
                        ],
                      )
                    ]),
                    if (test != null && showTests) 
                      FirkaCard(
                        left: [
                          Container(
                            decoration: ShapeDecoration(
                              color: appStyle.colors.a15p,
                              shape: CircleBorder(),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: FirkaIconWidget(
                                FirkaIconType.majesticons,
                                Majesticon.editPen4Solid,
                                size: 26.0,
                                color: appStyle.colors.accent,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    test.theme,
                                    style: appStyle.fonts.B_16SB.apply(color: appStyle.colors.textPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ),
                                SizedBox(height: 4),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    test.method.description ?? 'N/A',
                                    style: appStyle.fonts.B_16R.apply(color: appStyle.colors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          ),
                          Container(
                            decoration: ShapeDecoration(
                              color: appStyle.colors.a15p,
                              shape: CircleBorder(),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: FirkaIconWidget(
                                FirkaIconType.majesticons,
                                Majesticon.tooltipsSolid,
                                size: 26.0,
                                color: appStyle.colors.accent,
                              ),
                            ),
                          ),
                      ]),
                    SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: GestureDetector(
                        child: FirkaCard(
                          left: [],
                          center: [
                            Text(
                              data.l10n.view_subject_btn,
                              style: appStyle.fonts.B_16R
                                  .apply(color: appStyle.colors.textSecondary),
                            )
                          ],
                          color: appStyle.colors.buttonSecondaryFill,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          pageNavNotifier.value = PageNavData(HomePage.grades, lesson.subject!.uid, lesson.subject!.name);
                        },
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

Future<void> showTestBottomSheet(
    BuildContext context,
    AppInitialization data,
    Lesson lesson,
    int? lessonNo,
    Color accent,
    Color secondary,
    Color bgColor,
    Test? test,

    ) async {
  final date = lesson.start;
  final formattedDate = DateFormat('MMMM d, EEEE').format(date);
  final formattedTime = DateFormat('MMMM d, HH:mm').format(date);

  final statsForNerdsEnabled = data.settings
      .group("settings")
      .subGroup("developer")
      .boolean("stats_for_nerds");

  final showTests = data.settings
        .group("settings")
        .subGroup("timetable_toast")
        .boolean("tests_and_homework");
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
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
                padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: ShapeDecoration(
                        color: appStyle.colors.a15p,
                        shape: CircleBorder(),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.editPen4Solid,
                          size: 22.0,
                          color: appStyle.colors.accent,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(
                              "${test?.theme ?? 'N/A'} ${statsForNerdsEnabled ? "(${lesson.classGroup?.name ?? ''})" : ""}",
                              style: appStyle.fonts.H_18px
                                  .apply(color: appStyle.colors.textPrimary),
                            ),
                          ]),
                          Text(
                            test?.method.description ?? 'N/A',
                            style: appStyle.fonts.B_16R
                                .apply(color: appStyle.colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    FirkaCard(left: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Text(
                                "${data.l10n.date}: $formattedDate",
                                style: appStyle.fonts.B_16R
                                  .apply(color: appStyle.colors.textPrimary),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          SizedBox(height: 4),
                          statsForNerds
                        ],
                      )
                    ]),
                    if (test != null && showTests) 
                      FirkaCard(
                        left: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Stack(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/subtract.svg",
                                      color: bgColor,
                                      width: 24,
                                      height: 24,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 8, top: 4),
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
                                      size: 28,
                                      uid: lesson.uid,
                                      className: lesson.name,
                                      category: lesson.subject?.name != null
                                          ? lesson.subject!.name.firstUpper()
                                          : '',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 12),
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.37,
                                  child: Text(
                                    lesson.name,
                                    style: appStyle.fonts.B_16SB.apply(color: appStyle.colors.textPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ),
                              ],
                            ),
                          ),
                          Text(
                              formattedTime,
                              style: appStyle.fonts.B_14R.apply(color: appStyle.colors.textSecondary),
                          )
                      ]),
                    SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: GestureDetector(
                        child: FirkaCard(
                          left: [],
                          center: [
                            Text(
                              data.l10n.view_lesson_btn,
                              style: appStyle.fonts.B_16R
                                  .apply(color: appStyle.colors.textSecondary),
                            )
                          ],
                          color: appStyle.colors.buttonSecondaryFill,
                        ),
                        onTap: () {
                          showLessonBottomSheet(context, data, lesson, lessonNo, accent, secondary, bgColor, test);
                        },
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
                                    style: appStyle.fonts.B_16R.apply(
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
                                    "${data.l10n.tt_added}${grade.creationDate.format(data.l10n, FormatMode.yyyymmddhhmmss)}",
                                    style: appStyle.fonts.B_16R.apply(
                                        color: appStyle.colors.textPrimary),
                                  ),
                                  Text(
                                    "${data.l10n.grade_teacherName}${grade.teacher}",
                                    style: appStyle.fonts.B_16R.apply(
                                        color: appStyle.colors.textPrimary),
                                  ),
                                  Text(
                                    "${data.l10n.grade_strValue}${grade.strValue}",
                                    style: appStyle.fonts.B_16R.apply(
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
