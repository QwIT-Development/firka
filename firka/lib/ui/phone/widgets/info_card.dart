import 'package:firka/app/app_state.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/data/models/homework_cache_model.dart';
import 'package:firka/ui/components/common_bottom_sheets.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/ui/components/grade.dart';
import 'package:firka/ui/components/grade_helpers.dart';
import 'package:firka/ui/shared/class_icon.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  static Widget buildSubject(Color color, Subject subject) {
    return FilledCircle(
      diameter: 32,
      color: color.withAlpha(38),
      child: ClassIconWidget(
        uid: subject.uid,
        className: subject.name,
        category: subject.category.name!,
        color: color,
        size: 20,
      ),
    );
  }

  factory InfoCard.test(Test test) {
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
      texts: [test.theme.firstUpper(), test.subject.name.firstUpper()],
      right: [buildSubject(color, test.subject)],
    );
  }

  factory InfoCard.testDesc(Test test) {
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
      texts: [test.theme.firstUpper(), test.method.description.firstUpper()],
      right: [buildSubject(color, test.subject)],
    );
  }

  factory InfoCard.messageItem(MessageItem item) {
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

  factory InfoCard.homework(Homework homework) {
    return InfoCard(
      icon: FilledCircle(
        diameter: 36,
        color: appStyle.colors.accent.withAlpha(38),
        child: FutureBuilder<bool>(
          future: isHomeworkDone(initData.isar, homework.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox();
            }
            final done = snapshot.data!;
            return done
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
                  );
          },
        ),
      ),
      texts: [initData.l10n.homework, homework.subjectName],
      right: [buildSubject(appStyle.colors.accent, homework.subject)],
      onTap: (context) => showHomeworkBottomSheet(context, initData, homework),
    );
  }

  factory InfoCard.gradeSubj(
    Grade grade, {
    void Function(BuildContext)? onTap,
  }) {
    String? value = grade.numericValue == null ? grade.strValue : null;
    return InfoCard(
      icon: GradeWidget(grade),
      texts: [
        (value ??
                grade.topic ??
                grade.mode?.description ??
                grade.type.description!)
            .firstUpper(),
        grade.subject.name.firstUpper(),
      ],
      right: [buildSubject(appStyle.colors.accent, grade.subject)],
      onTap:
          onTap ?? (context) => showGradeBottomSheet(context, initData, grade),
    );
  }

  factory InfoCard.gradeDesc(
    Grade grade, {
    void Function(BuildContext)? onTap,
  }) {
    List<String> texts = [
      (grade.mode?.description ?? grade.type.description!).firstUpper(),
    ];

    if (grade.topic != null) {
      texts = [grade.topic!.firstUpper(), ...texts];
    }

    return InfoCard(
      icon: GradeWidget(grade),
      texts: texts,
      right: [buildSubject(appStyle.colors.accent, grade.subject)],
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
