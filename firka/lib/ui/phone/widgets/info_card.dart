import 'package:firka/app/app_state.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka_common/core/grade_helper.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/homework_cache_model.dart';
import 'package:firka_common/data/models/message_cache_model.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/models/test_cache_model.dart';
import 'package:firka/ui/components/common_bottom_sheets.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/ui/components/grade.dart';
import 'package:firka/ui/shared/class_icon.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka_common/data/util.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:kreta_api/kreta_api.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

class InfoCard extends StatelessWidget {
  final void Function(BuildContext)? onTap;
  final Widget icon;
  final List<String> texts;
  final List<Widget> right;

  final List<TextStyle> textSyles = [
    appStyle.fonts.B_16SB.apply(color: appStyle.colors.textPrimary),
    appStyle.fonts.B_14R.apply(color: appStyle.colors.textSecondary),
  ];

  InfoCard({
    required this.icon,
    required this.texts,
    this.right = const [],
    this.onTap,
    super.key,
  });

  static Widget buildSubject(Color color, SubjectCacheModel subject) {
    return FilledCircle(
      diameter: 32,
      color: color.withAlpha(38),
      child: ClassIconWidget(subject: subject, color: color, size: 20),
    );
  }

  factory InfoCard.test(TestCacheModel test) {
    final color = appStyle.colors.accent;

    final subject = test.lesson.loadAndGet()!.subject.loadAndGet()!;

    return InfoCard(
      icon: FilledCircle(
        diameter: 36,
        color: color.withAlpha(38),
        child: FirkaIconWidget(
          FirkaIconType.majesticons,
          Majesticon.editPen4Solid,
          color: color,
          size: 24,
        ),
      ),
      texts: [
        test.topic?.firstUpper() ?? test.method,
        subject.name.firstUpper(),
      ],
      right: [buildSubject(color, subject)],
      onTap: (context) => showTestBottomSheet(context, initData, test),
    );
  }

  factory InfoCard.testDesc(TestCacheModel test) {
    if (test.topic == null) {
      return InfoCard.test(test);
    }

    final subject = test.lesson.loadAndGet()!.subject.loadAndGet()!;

    final color = appStyle.colors.accent;

    return InfoCard(
      icon: FilledCircle(
        diameter: 36,
        color: color.withAlpha(38),
        child: FirkaIconWidget(
          FirkaIconType.majesticons,
          Majesticon.editPen4Solid,
          color: color,
          size: 24,
        ),
      ),
      texts: [test.topic!.firstUpper(), test.method.firstUpper()],
      right: [buildSubject(color, subject)],
      onTap: (context) => showTestBottomSheet(context, initData, test),
    );
  }

  factory InfoCard.messageItem(MessageCacheModel item) {
    return InfoCard(
      icon: FilledCircle(
        diameter: 36,
        color: appStyle.colors.accent,
        child: Text(
          item.author[0],
          style: appStyle.fonts.H_H2.apply(color: appStyle.colors.textPrimary),
        ),
      ),
      texts: [item.title, item.author],
      onTap: (context) => context.push('/message', extra: item),
    );
  }

  factory InfoCard.omission(List<OmissionCacheModel> omissions) {
    String title = "-";
    Color color = appStyle.colors.accent;
    FirkaIconType iconType = FirkaIconType.majesticons;
    Object iconData = "check";
    for (final state in [
      (
        OmissionState.pending,
        appStyle.colors.warningAccent,
        FirkaIconType.majesticons,
        Majesticon.timerSolid,
      ),
      (
        OmissionState.unexcused,
        appStyle.colors.errorAccent,
        FirkaIconType.majesticons,
        Majesticon.restrictedLine,
      ),
      (
        OmissionState.excused,
        appStyle.colors.accent,
        FirkaIconType.majesticonsLocal,
        "check",
      ),
    ]) {
      final count = omissions.where((o) => o.state == state.$1).length;

      if (count == 0) {
        continue;
      }

      title = initData.l10n.omissions_count(state.$1.name, count);
      color = state.$2;
      iconType = state.$3;
      iconData = state.$4;
      break;
    }
    return InfoCard(
      icon: FilledCircle(
        diameter: 36,
        color: color.withAlpha(38),
        child: FirkaIconWidget(iconType, iconData, color: color, size: 24),
      ),
      texts: [
        title,
        DateFormat.MMMMd(
          initData.l10n.localeName,
        ).format(omissions.first.createdAt).firstUpper(),
      ],
      onTap: (context) =>
          showOmissionBottomSheet(context, initData, title, omissions),
    );
  }

  factory InfoCard.homework(HomeworkCacheModel homework) {
    final subject = homework.subject.loadAndGet()!;
    return InfoCard(
      icon: FilledCircle(
        diameter: 36,
        color: appStyle.colors.accent.withAlpha(38),
        child: homework.isDone
            ? FirkaIconWidget(
                FirkaIconType.majesticonsLocal,
                "homeWithMark",
                color: appStyle.colors.accent,
                size: 24,
              )
            : FirkaIconWidget(
                FirkaIconType.majesticons,
                Majesticon.homeSolid,
                color: appStyle.colors.accent,
                size: 24,
              ),
      ),
      texts: [initData.l10n.homework, subject.name],
      right: [buildSubject(appStyle.colors.accent, subject)],
      onTap: (context) => showHomeworkBottomSheet(context, initData, homework),
    );
  }

  factory InfoCard.gradeSubj(
    GradeCacheModel grade, {
    void Function(BuildContext)? onTap,
  }) {
    String? value = grade.numericValue == null ? grade.textValue : null;
    return InfoCard(
      icon: GradeWidget(grade),
      texts: [
        (value ?? grade.topic ?? grade.mode ?? grade.type).firstUpper(),
        grade.subject.loadAndGet()!.name.firstUpper(),
      ],
      right: [
        buildSubject(
          grade.numericValue != null
              ? getGradeColor(grade.numericValue!)
              : appStyle.colors.accent,
          grade.subject.loadAndGet()!,
        ),
      ],
      onTap:
          onTap ?? (context) => showGradeBottomSheet(context, initData, grade),
    );
  }

  factory InfoCard.gradeGhost(
    int gradeValue,
    int gradeWeigth, {
    void Function(BuildContext)? onTap,
  }) {
    return InfoCard(
      icon: GradeWidget.gradeValue(gradeValue, gradeWeight: gradeWeigth),
      texts: ["${initData.l10n.ghost_grade} ($gradeWeigth%)"],
      right: [],
      onTap: onTap,
    );
  }

  factory InfoCard.gradeDesc(
    GradeCacheModel grade, {
    void Function(BuildContext)? onTap,
  }) {
    List<String> texts = [(grade.mode ?? grade.type).firstUpper()];

    if (grade.topic != null) {
      texts = [grade.topic!.firstUpper(), ...texts];
    }

    return InfoCard(
      icon: GradeWidget(grade),
      texts: texts,
      right: [
        buildSubject(appStyle.colors.accent, grade.subject.loadAndGet()!),
      ],
      onTap:
          onTap ?? (context) => showGradeBottomSheet(context, initData, grade),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Text> children = [];
    int i = 0;
    for (var text in texts) {
      children.add(
        Text(text, style: textSyles[i], overflow: TextOverflow.ellipsis),
      );
      if (i < textSyles.length) {
        i++;
      }
    }
    return GestureDetector(
      child: FirkaCard.single(
        height: 68,
        padding: EdgeInsets.symmetric(horizontal: 16),
        margin: EdgeInsets.all(0),
        child: Row(
          spacing: 12,
          children: [
            icon,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: children,
              ),
            ),
            ...right,
          ],
        ),
      ),
      onTap: () {
        if (onTap == null) return;
        onTap!.call(context);
      },
    );
  }
}
