import 'package:firka/ui/phone/widgets/info_card.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:firka_common/ui/shared/grade_small_card.dart';
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

Future<void> showFirkaBottomSheet(
  BuildContext context,
  List<Widget> children,
) async {
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    builder: (BuildContext context) => Align(
      alignment: AlignmentGeometry.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(20) - EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: appStyle.colors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              heightFactor: 0,
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(top: 18),
                width: 40,
                height: 4,
                foregroundDecoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(2),
                  ),
                  color: appStyle.colors.shadowColor,
                ),
              ),
            ),
            SizedBox(height: 40),
            ...children,
          ],
        ),
      ),
    ),
  );
}

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

  Widget? statsForNerds;

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
  showFirkaBottomSheet(context, [
    Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                "assets/icons/subtract.svg",
                color: bgColor,
                width: 24,
                height: 24,
              ),
              Text(
                lessonNo.toString(),
                style: appStyle.fonts.B_16R.apply(color: secondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        FilledCircle(
          diameter: 40,
          color: bgColor,
          child: ClassIconWidget(
            uid: lesson.uid,
            className: lesson.name,
            category: subjectName,
            color: accent,
            size: 26,
          ),
        ),
      ],
    ),
    SizedBox(height: 20),
    Row(
      children: [
        Text(
          "${lesson.name} ${statsForNerdsEnabled ? "(${lesson.classGroup?.name ?? ''})" : ""}",
          style: appStyle.fonts.H_18px.apply(
            color: appStyle.colors.textPrimary,
          ),
        ),
      ],
    ),
    SizedBox(height: 2),
    Text(
      lesson.teacher ?? 'N/A',
      style: appStyle.fonts.B_14R.apply(
        color: appStyle.colors.textSecondary,
        decoration: lesson.substituteTeacher != null
            ? TextDecoration.lineThrough
            : TextDecoration.none,
      ),
    ),
    if (lesson.substituteTeacher != null)
      Text(
        lesson.substituteTeacher!,
        style: appStyle.fonts.B_14R.apply(color: appStyle.colors.textSecondary),
      ),
    SizedBox(height: 8),
    Text(
      '${lesson.start.format(data.l10n, FormatMode.hmm)} - ${lesson.end.format(data.l10n, FormatMode.hmm)}',
      style: appStyle.fonts.B_14R.apply(color: appStyle.colors.textSecondary),
    ),
    SizedBox(height: 20),
    FirkaCard(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(14),
      left: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              data.l10n.lesson_subject,
              style: appStyle.fonts.H_14px.apply(
                color: appStyle.colors.textPrimary,
              ),
            ),
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
            ?statsForNerds,
          ],
        ),
      ],
    ),
    SizedBox(height: 6),
    if (test != null) InfoCard.testDesc(test),
    SizedBox(height: 16),
    GestureDetector(
      child: FirkaCard(
        margin: EdgeInsets.all(0),
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
        subjectCategory = lesson.subject!.category.name;
        subjectInfo = [];
        Navigator.pop(context);
        context.push('/timetable/subject/${lesson.subject!.uid}');
      },
    ),
  ]);
}

Future<void> showTestBottomSheet(
  BuildContext context,
  AppInitialization data,
  Lesson lesson,
  int? lessonNo,
  Color accent,
  Color secondary,
  Color bgColor,
  Test test,
) async {
  final date = lesson.start;
  final formattedDate =
      "${date.format(data.l10n, FormatMode.grades)}, ${DateFormat.EEEE(data.l10n.localeName).format(date).firstUpper()}";

  final statsForNerdsEnabled = data.settings
      .group("settings")
      .subGroup("developer")
      .boolean("stats_for_nerds");

  showFirkaBottomSheet(context, [
    FilledCircle(
      diameter: 40,
      color: appStyle.colors.a15p,
      child: FirkaIconWidget(
        FirkaIconType.majesticons,
        Majesticon.editPen4Solid,
        size: 26.0,
        color: appStyle.colors.accent,
      ),
    ),
    SizedBox(height: 20),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(
          "${test.theme} ${statsForNerdsEnabled ? "(${lesson.classGroup?.name ?? ''})" : ""}",
          style: appStyle.fonts.H_18px.apply(
            color: appStyle.colors.textPrimary,
          ),
        ),
        Text(
          test.method.description,
          style: appStyle.fonts.B_16R.apply(
            color: appStyle.colors.textSecondary,
          ),
        ),
      ],
    ),
    SizedBox(height: 20),
    FirkaCard.single(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 16),
      margin: EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${data.l10n.date}: $formattedDate",
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
    SizedBox(height: 10),
    LessonWidget(data, lessonNo, lesson, null),
  ]);
}

Future<void> showGradeBottomSheet(
  BuildContext context,
  AppInitialization data,
  Grade grade,
) async {
  showFirkaBottomSheet(context, [
    grade.numericValue == null
        ? Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: appStyle.colors.a15p,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  grade.strValue,
                  style: appStyle.fonts.H_18px.apply(
                    color: appStyle.colors.accent,
                  ),
                ),
              ],
            ),
          )
        : GradeWidget(grade, size: 40),
    SizedBox(height: 20),
    Text(
      (grade.topic ?? grade.type.description).firstUpper(),
      style: appStyle.fonts.H_18px.apply(color: appStyle.colors.textPrimary),
    ),
    grade.mode != null
        ? Text(
            grade.mode!.description,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textSecondary,
            ),
          )
        : SizedBox(),
    SizedBox(height: 8),
    Text(
      grade.recordDate.format(data.l10n, FormatMode.yyyymmdd),
      style: appStyle.fonts.B_14R.apply(color: appStyle.colors.textSecondary),
    ),
    SizedBox(height: 20),
    GradeSmallCard([], grade.subject),
    SizedBox(height: 10),
    FirkaCard(
      margin: EdgeInsets.all(0),
      left: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${data.l10n.grade_teacherName}${grade.teacher}",
              style: appStyle.fonts.B_16R.apply(
                color: appStyle.colors.textPrimary,
              ),
            ),
            Text(
              "${data.l10n.tt_added}${grade.creationDate.format(data.l10n, FormatMode.yyyymmdd)}",
              style: appStyle.fonts.B_16R.apply(
                color: appStyle.colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    ),
    SizedBox(height: 20),
    GestureDetector(
      child: FirkaCard(
        margin: EdgeInsets.all(0),
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
        subjectCategory = grade.subject.category.name;
        subjectInfo = [];
        Navigator.pop(context);
        context.go('/grades/subject/${grade.subject.uid}');
      },
    ),
  ]);
}

Future<void> showHomeworkBottomSheet(
  BuildContext context,
  AppInitialization data,
  Homework homework,
) async {
  showFirkaBottomSheet(context, [
    Text(
      data.l10n.homework,
      style: appStyle.fonts.H_18px.apply(color: appStyle.colors.textPrimary),
    ),
    SizedBox(height: 4),
    Text(
      homework.dueDate.format(data.l10n, FormatMode.yyyymmdd),
      style: appStyle.fonts.B_14R.apply(color: appStyle.colors.textSecondary),
    ),
    SizedBox(height: 20),
    GradeSmallCard([], homework.subject),
    SizedBox(height: 20),
    Flexible(
      fit: FlexFit.loose,
      child: FirkaCard.single(
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.all(12),
        child: Html(
          data: homework.description,
          style: {
            "*": Style.fromTextStyle(
              appStyle.fonts.B_16R.apply(color: appStyle.colors.textPrimary),
            ),
          },
        ),
      ),
    ),
    SizedBox(height: 20),
    FutureBuilder<bool>(
      future: isHomeworkDone(data.isar, homework.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(); // or a loading indicator
        }

        final done = snapshot.data!;

        return Column(
          children: [
            GestureDetector(
              child: FirkaCard(
                margin: EdgeInsets.all(0),
                left: [],
                center: [
                  Text(
                    !done ? data.l10n.mark_as_done : data.l10n.mark_as_not_done,
                    style: appStyle.fonts.B_16SB.apply(
                      color: appStyle.colors.textPrimaryLight,
                    ),
                  ),
                ],
                color: appStyle.colors.accent,
              ),
              onTap: () {
                Navigator.pop(context);
                !done
                    ? markAsDone(data.isar, homework.uid)
                    : markAsNotDone(data.isar, homework.uid);
              },
            ),
          ],
        );
      },
    ),
    SizedBox(height: 8),
    GestureDetector(
      child: FirkaCard(
        margin: EdgeInsets.all(0),
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
  ]);
}

Future<void> showGradeCalculatorBottomSheet(
  BuildContext context,
  AppInitialization data,
  Subject subject, {
  void Function(int grade, int weight)? onAdd,
}) async {
  showFirkaBottomSheet(context, [
    _GradeCalculatorSheetContent(data: data, subject: subject, onAdd: onAdd),
  ]);
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
  int weightIndex = 1; // 0-based index into _snapPoints
  final List<(int grade, int weight)> entries = [];

  static const _snapPoints = [50, 100, 200, 300, 400, 500];

  int get weightPercent => _snapPoints[weightIndex];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
              return GestureDetector(
                onTap: () => setState(() => selectedGrade = grade),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? getGradeColor(grade.toDouble()).withAlpha(15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: GradeWidget.gradeValue(grade, size: 32)),
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
                    value: weightIndex.toDouble(),
                    min: 0,
                    max: (_snapPoints.length - 1).toDouble(),
                    divisions: _snapPoints.length - 1,
                    label: '${weightPercent}%',
                    onChanged: (v) => setState(() => weightIndex = v.round()),
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
                color: appStyle.colors.textPrimaryLight,
              ),
            ),
          ),
        ),
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
  showFirkaBottomSheet(context, [
    Text(
      data.l10n.subject,
      style: appStyle.fonts.H_H2.apply(color: appStyle.colors.textPrimary),
    ),
    SizedBox(height: 20),
    GestureDetector(
      onTap: () {
        Navigator.pop(context);
        showGradeCalculatorBottomSheet(
          context,
          data,
          subject,
          onAdd: onAddFromCalculator,
        );
      },
      child: FirkaCard.single(
        margin: EdgeInsets.all(0),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FirkaIconWidget(
              FirkaIconType.majesticons,
              Majesticon.calculatorSolid,
              size: 24,
              color: appStyle.colors.accent,
            ),
            SizedBox(width: 8),
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
  ]);
}
