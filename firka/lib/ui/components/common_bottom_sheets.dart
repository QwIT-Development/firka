import 'package:kreta_api/kreta_api.dart';
import 'package:firka/data/models/homework_cache_model.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/ui/components/firka_shadow.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:intl/intl.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/theme_cubit.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/phone/pages/home/home_grades.dart';
import 'package:firka/ui/phone/widgets/lesson.dart';
import 'package:go_router/go_router.dart';
import 'package:firka/ui/shared/class_icon.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/ui/components/grade.dart';
import 'package:firka/ui/components/grade_helpers.dart';

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
        statsForNerds = Text(
          stats,
          style: appStyle.fonts.B_16R.apply(color: appStyle.colors.textPrimary),
        );
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
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/icons/subtract.svg",
                                color: bgColor,
                                width: 18,
                                height: 18,
                              ),
                              Text(
                                lessonNo.toString(),
                                style: appStyle.fonts.B_12R.apply(
                                  color: secondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(-4, 0),
                          child: Card(
                            shadowColor: Colors.transparent,
                            color: bgColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                          Row(
                            children: [
                              Text(
                                "${lesson.name} ${statsForNerdsEnabled ? "(${lesson.classGroup?.name ?? ''})" : ""}",
                                style: appStyle.fonts.H_18px.apply(
                                  color: appStyle.colors.textPrimary,
                                ),
                              ),
                              Card(
                                shadowColor: Colors.transparent,
                                color: appStyle.colors.a15p,
                                child: Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Text(
                                    lesson.roomName ?? 'N/A',
                                    style: appStyle.fonts.B_12R.apply(
                                      color: appStyle.colors.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            lesson.teacher ?? 'N/A',
                            style: appStyle.fonts.B_16R.apply(
                              color: appStyle.colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${lesson.start.format(data.l10n, FormatMode.hmm)} - ${lesson.end.format(data.l10n, FormatMode.hmm)}',
                            style: appStyle.fonts.B_16R.apply(
                              color: appStyle.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    FirkaCard(
                      left: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.l10n.lesson_subject,
                              style: appStyle.fonts.H_14px.apply(
                                color: appStyle.colors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Text(
                                lesson.theme ?? 'N/A',
                                style: appStyle.fonts.B_16R.apply(
                                  color: appStyle.colors.textPrimary,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 4),
                            statsForNerds,
                          ],
                        ),
                      ],
                    ),
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
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    test.theme,
                                    style: appStyle.fonts.B_16SB.apply(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 4),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    test.method.description ?? 'N/A',
                                    style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                        ],
                      ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: GestureDetector(
                        child: FirkaCard(
                          left: [],
                          center: [
                            Text(
                              data.l10n.view_subject_btn,
                              style: appStyle.fonts.B_16R.apply(
                                color: appStyle.colors.textSecondary,
                              ),
                            ),
                          ],
                          color: appStyle.colors.buttonSecondaryFill,
                        ),
                        onTap: () {
                          activeSubjectUid = lesson.subject!.uid;
                          subjectName = lesson.subject!.name;
                          subjectId = lesson.subject!.uid;
                          subjectCategory = lesson.subject!.category.name ?? "";
                          subjectInfo = [];
                          Navigator.pop(context);
                          context.push(
                            '/timetable/subject/${lesson.subject!.uid}',
                          );
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
  final formattedDate = DateFormat(
    'MMMM d, EEEE',
    data.l10n.localeName,
  ).format(date);
  final formattedTime = DateFormat(
    'MMMM d, HH:mm',
    data.l10n.localeName,
  ).format(date);

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
        statsForNerds = Text(
          stats,
          style: appStyle.fonts.B_16R.apply(color: appStyle.colors.textPrimary),
        );
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${test?.theme ?? 'N/A'} ${statsForNerdsEnabled ? "(${lesson.classGroup?.name ?? ''})" : ""}",
                                  style: appStyle.fonts.H_18px.apply(
                                    color: appStyle.colors.textPrimary,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            test?.method.description ?? 'N/A',
                            style: appStyle.fonts.B_16R.apply(
                              color: appStyle.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    FirkaCard(
                      left: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Text(
                                "${data.l10n.data}: $formattedDate",
                                style: appStyle.fonts.B_16R.apply(
                                  color: appStyle.colors.textPrimary,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 4),
                            statsForNerds,
                          ],
                        ),
                      ],
                    ),
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
                                      child: Text(
                                        lessonNo.toString(),
                                        style: appStyle.fonts.B_12R.apply(
                                          color: secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(-4, 0),
                                child: Card(
                                  shadowColor: Colors.transparent,
                                  color: bgColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                  child: Text(
                                    lesson.name,
                                    style: appStyle.fonts.B_16SB.apply(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        right: [
                          Text(
                            formattedTime,
                            style: appStyle.fonts.B_14R.apply(
                              color: appStyle.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: GestureDetector(
                        child: FirkaCard(
                          left: [],
                          center: [
                            Text(
                              data.l10n.view_lesson_btn,
                              style: appStyle.fonts.B_16R.apply(
                                color: appStyle.colors.textSecondary,
                              ),
                            ),
                          ],
                          color: appStyle.colors.buttonSecondaryFill,
                        ),
                        onTap: () {
                          showLessonBottomSheet(
                            context,
                            data,
                            lesson,
                            lessonNo,
                            accent,
                            secondary,
                            bgColor,
                            test,
                          );
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
  BuildContext context,
  AppInitialization data,
  Grade grade,
) async {
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
      final gradeCreationDate = grade.creationDate;
      final formattedDate = DateFormat(
        'yyyy. MMMM d., EEEE',
        data.l10n.localeName,
      ).format(gradeCreationDate);

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
                    Row(children: [GradeWidget(grade)]),
                    SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grade.topic ?? grade.type.description!,
                            style: appStyle.fonts.H_18px.apply(
                              color: appStyle.colors.textPrimary,
                            ),
                          ),
                          grade.mode?.description != null
                              ? SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 1.45,
                                  child: Text(
                                    grade.mode!.description!,
                                    style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textSecondary,
                                    ),
                                  ),
                                )
                              : SizedBox(),
                          SizedBox(height: 20),
                          LessonWidget(
                            data,
                            [],
                            [],
                            null,
                            Lesson(
                              uid: "-2",
                              date: "",
                              start: grade.creationDate,
                              end: grade.creationDate,
                              name: grade.subject.name,
                              type: NameUidDesc(
                                uid: "",
                                name: "",
                                description: "",
                              ),
                              state: NameUidDesc(
                                uid: "",
                                name: "",
                                description: "",
                              ),
                              canStudentEditHomework: false,
                              isHomeworkComplete: false,
                              attachments: [],
                              isDigitalLesson: false,
                              digitalSupportDeviceTypeList: [],
                              createdAt: timeNow(),
                              subject: grade.subject,
                              lastModifiedAt: timeNow(),
                            ),
                            null,
                            null,
                            placeholderMode: true,
                          ),
                          FirkaCard(
                            left: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${data.l10n.tt_added}$formattedDate",
                                    style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "${data.l10n.grade_teacherName}${grade.teacher}",
                                    style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "${data.l10n.grade_strValue}${grade.strValue}",
                                    style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 1.1,
                            child: GestureDetector(
                              child: FirkaCard(
                                left: [],
                                center: [
                                  Text(
                                    data.l10n.view_subject_btn,
                                    style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textSecondary,
                                    ),
                                  ),
                                ],
                                color: appStyle.colors.buttonSecondaryFill,
                              ),
                              onTap: () {
                                activeSubjectUid = grade.subject.uid;
                                subjectName = grade.subject.name;
                                subjectId = grade.subject.uid;
                                subjectCategory =
                                    grade.subject.category.name ?? "";
                                subjectInfo = [];
                                Navigator.pop(context);
                                context.go(
                                  '/grades/subject/${grade.subject.uid}',
                                );
                              },
                            ),
                          ),
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

Future<void> showHomeworkBottomSheet(
  BuildContext context,
  AppInitialization data,
  Homework homework,
) async {
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
      final formattedDate = DateFormat(
        'yyyy. MMMM d.',
        data.l10n.localeName,
      ).format(homework.dueDate);

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
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                data.l10n.homework,
                                style: appStyle.fonts.H_18px.apply(
                                  color: appStyle.colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formattedDate,
                            style: appStyle.fonts.B_16R.apply(
                              color: appStyle.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    LessonWidget(
                      data,
                      [],
                      [],
                      null,
                      Lesson(
                        uid: "-1",
                        date: "",
                        start: homework.startDate,
                        end: homework.dueDate,
                        name: homework.subjectName,
                        type: NameUidDesc(uid: "", name: "", description: ""),
                        state: NameUidDesc(uid: "", name: "", description: ""),
                        canStudentEditHomework: false,
                        isHomeworkComplete: false,
                        attachments: [],
                        isDigitalLesson: false,
                        digitalSupportDeviceTypeList: [],
                        createdAt: timeNow(),
                        subject: homework.subject,
                        lastModifiedAt: timeNow(),
                      ),
                      null,
                      null,
                      placeholderMode: true,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FirkaShadow(
                        shadow: true,
                        child: Card(
                          color: appStyle.colors.card,
                          shadowColor:
                              context.watch<ThemeCubit>().state.isLightMode
                              ? null
                              : Colors.transparent,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 20.0,
                              ),
                              child: Html(
                                data: homework.description,
                                style: {
                                  "*": Style(
                                    color: appStyle.colors.textPrimary,
                                    fontSize: FontSize(16),
                                    fontFamily: appStyle.fonts.B_16R.fontFamily,
                                    fontWeight: FontWeight.w900,
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    textAlign: TextAlign.start,
                                  ),
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    FutureBuilder<bool>(
                      future: isHomeworkDone(data.isar, homework.uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox(); // or a loading indicator
                        }

                        final done = snapshot.data!;

                        return Column(
                          children: [
                            if (!done)
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 1.1,
                                child: GestureDetector(
                                  child: FirkaCard(
                                    left: [],
                                    center: [
                                      Text(
                                        data.l10n.mark_as_done,
                                        style: appStyle.fonts.B_16SB.apply(
                                          color: appStyle.colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    color: appStyle.colors.accent,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    markAsDone(data.isar, homework.uid);
                                  },
                                ),
                              ),
                            if (done)
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 1.1,
                                child: GestureDetector(
                                  child: FirkaCard(
                                    left: [],
                                    center: [
                                      Text(
                                        data.l10n.mark_as_not_done,
                                        style: appStyle.fonts.B_16SB.apply(
                                          color: appStyle.colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    color: appStyle.colors.accent,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    markAsNotDone(data.isar, homework.uid);
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: GestureDetector(
                        child: FirkaCard(
                          left: [],
                          center: [
                            Text(
                              data.l10n.view_subject_btn,
                              style: appStyle.fonts.B_16R.apply(
                                color: appStyle.colors.textSecondary,
                              ),
                            ),
                          ],
                          color: appStyle.colors.buttonSecondaryFill,
                        ),
                        onTap: () {
                          activeSubjectUid = homework.subject.uid;
                          subjectName = homework.subjectName;
                          subjectId = homework.subject.uid;
                          subjectCategory = "";
                          subjectInfo = [];
                          Navigator.pop(context);
                          context.push('/home/subject/${homework.subject.uid}');
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

Future<void> showGradeCalculatorBottomSheet(
  BuildContext context,
  AppInitialization data,
  Subject subject, {
  void Function(int grade, int weight)? onAdd,
}) async {
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: _GradeCalculatorSheetContent(
                  data: data,
                  subject: subject,
                  onAdd: onAdd,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _GradeCalculatorSheetContent extends StatefulWidget {
  final AppInitialization data;
  final Subject subject;
  final void Function(int grade, int weight)? onAdd;

  const _GradeCalculatorSheetContent({
    required this.data,
    required this.subject,
    this.onAdd,
  });

  @override
  State<_GradeCalculatorSheetContent> createState() =>
      _GradeCalculatorSheetContentState();
}

class _GradeCalculatorSheetContentState
    extends State<_GradeCalculatorSheetContent> {
  int selectedGrade = 3;
  int weightPercent = 100;
  final List<(int grade, int weight)> entries = [];

  double get _weightedAverage {
    if (entries.isEmpty) return 0;
    double sum = 0;
    double weightTotal = 0;
    for (final e in entries) {
      final w = e.$2 / 100.0;
      weightTotal += w;
      sum += e.$1 * w;
    }
    return weightTotal > 0 ? sum / weightTotal : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: appStyle.colors.a15p,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.data.l10n.grade_calculator,
                style: appStyle.fonts.H_H2.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: appStyle.colors.buttonSecondaryFill,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: appStyle.colors.shadowColor,
                      blurRadius: appStyle.colors.shadowBlur.toDouble(),
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: appStyle.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: appStyle.colors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: appStyle.colors.shadowColor,
                blurRadius: appStyle.colors.shadowBlur.toDouble(),
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3, 4, 5].map((grade) {
              final isSelected = selectedGrade == grade;
              final gradeColor = getGradeColor(grade.toDouble());
              return GestureDetector(
                onTap: () => setState(() => selectedGrade = grade),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? appStyle.colors.buttonSecondaryFill
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: gradeColor.withAlpha(38),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$grade',
                      style: appStyle.fonts.H_14px.copyWith(
                        fontSize: 18,
                        color: gradeColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: appStyle.colors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: appStyle.colors.shadowColor,
                      blurRadius: appStyle.colors.shadowBlur.toDouble(),
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: appStyle.colors.accent,
                    inactiveTrackColor: appStyle.colors.card,
                    thumbColor: appStyle.colors.accent,
                    overlayColor: appStyle.colors.a10p,
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: weightPercent.toDouble(),
                    min: 1,
                    max: 500,
                    divisions: 499,
                    onChanged: (v) => setState(() => weightPercent = v.round()),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              width: 56,
              child: Text(
                '$weightPercent%',
                style: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appStyle.colors.accent,
              foregroundColor: appStyle.colors.textPrimary,
              elevation: 1,
              shadowColor: appStyle.colors.shadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                entries.add((selectedGrade, weightPercent));
              });
              widget.onAdd?.call(selectedGrade, weightPercent);
            },
            child: Text(
              widget.data.l10n.grade_calculator_add,
              style: appStyle.fonts.H_18px.apply(
                color: appStyle.colors.textPrimary,
              ),
            ),
          ),
        ),
        if (entries.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(
            '${widget.data.l10n.subject_avg}: ${_weightedAverage.toStringAsFixed(2)}',
            style: appStyle.fonts.B_14R.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> showSubjectBottomSheetSettings(
  BuildContext context,
  AppInitialization data,
  Subject subject, {
  void Function(int grade, int weight)? onAddFromCalculator,
}) async {
  final parentContext = context;
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    builder: (BuildContext sheetContext) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(sheetContext),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: appStyle.colors.a15p,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      data.l10n.subject,
                      style: appStyle.fonts.H_H2.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        showGradeCalculatorBottomSheet(
                          parentContext,
                          data,
                          subject,
                          onAdd: onAddFromCalculator,
                        );
                      },
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: appStyle.colors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            FirkaIconWidget(
                              FirkaIconType.majesticons,
                              Majesticon.calculatorSolid,
                              size: 24,
                              color: appStyle.colors.accent,
                            ),
                            SizedBox(width: 12),
                            Text(
                              data.l10n.grade_calculator,
                              style: appStyle.fonts.B_16SB.apply(
                                color: appStyle.colors.textPrimary,
                              ),
                            ),
                          ],
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
