import 'package:firka/core/extensions.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:kreta_api/kreta_api.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/ui/components/common_bottom_sheets.dart';
import 'package:firka/ui/shared/class_icon.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'bubble_test.dart';

class LessonWidget extends StatelessWidget {
  final AppInitialization data;
  final int? lessonNo;
  final Lesson lesson;
  final Test? test;

  const LessonWidget(
    this.data,
    this.lessonNo,
    this.lesson,
    this.test, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showTests = data.settings
        .group("settings")
        .subGroup("timetable_toast")
        .boolean("tests_and_homework");

    final isSubstituted = lesson.substituteTeacher != null;
    final showSubstitutions =
        isSubstituted &&
        data.settings
            .group("settings")
            .subGroup("timetable_toast")
            .boolean("substitution");
    final showLessonNos =
        lessonNo != null &&
        data.settings
            .group("settings")
            .subGroup("timetable_toast")
            .boolean("lesson_no");
    final isDismissed = lesson.type.name == "UresOra";

    var accent = appStyle.colors.accent;
    var secondary = appStyle.colors.secondary;
    var bgColor = appStyle.colors.a15p;

    if (isSubstituted) {
      accent = appStyle.colors.warningAccent;
      secondary = appStyle.colors.warningText;
      bgColor = appStyle.colors.warning15p;
    }
    if (isDismissed) {
      accent = appStyle.colors.errorAccent;
      secondary = appStyle.colors.errorText;
      bgColor = appStyle.colors.error15p;
    }

    List<Widget> elements = [];

    var subjectName = lesson.subject?.name.firstUpper() ?? 'N/A';

    var roomName = lesson.roomName ?? 'N/A';

    elements.add(
      GestureDetector(
        onTap: () {
          if (lessonNo == null) return;
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
        child: FirkaCard.single(
          height: 64,
          margin: EdgeInsets.all(0),
          padding: EdgeInsets.only(left: 14, right: 16),
          color: isDismissed
              ? appStyle.colors.cardTranslucent
              : appStyle.colors.card,
          attached: showTests && test != null ? Attach.bottom : Attach.none,
          shadow: !isDismissed,
          child: Row(
            children: [
              !showLessonNos
                  ? SizedBox()
                  : SizedBox(
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
                            style: appStyle.fonts.B_12R.apply(color: secondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
              FilledCircle(
                diameter: 36,
                color: bgColor,
                child: ClassIconWidget(
                  uid: lesson.uid,
                  className: lesson.name,
                  category: subjectName,
                  color: accent,
                  size: 24,
                ),
              ),
              SizedOverflowBox(
                size: Size(12, 0),
                child: !showTests && test != null
                    ? Transform.translate(
                        offset: Offset(4, -20),
                        child: BubbleTest(),
                      )
                    : SizedBox(),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 12,
                  children: [
                    LimitedBox(
                      maxWidth: 155,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            subjectName,
                            style: appStyle.fonts.B_16SB.apply(
                              color: !isDismissed
                                  ? appStyle.colors.textPrimary
                                  : appStyle.colors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          showSubstitutions
                              ? Text(
                                  lesson.substituteTeacher!,
                                  style: appStyle.fonts.B_14R.apply(
                                    color: appStyle.colors.textSecondary,
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Card(
                        shadowColor: Colors.transparent,
                        color: appStyle.colors.a15p,
                        margin: EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            roomName,
                            style: appStyle.fonts.B_12R.apply(
                              color: appStyle.colors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lesson.start.toLocal().format(data.l10n, FormatMode.hmm),
                    style: appStyle.fonts.B_14R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                  Text(
                    lesson.end.toLocal().format(data.l10n, FormatMode.hmm),
                    style: appStyle.fonts.B_14R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (test != null && showTests) {
      var theme = test!.theme.firstUpper();
      var method = test!.method.description.firstUpper();

      elements.add(
        GestureDetector(
          onTap: () {
            showTestBottomSheet(
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
          child: FirkaCard.single(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: 16),
            margin: EdgeInsets.only(top: 4),
            attached: Attach.top,
            child: Row(
              children: [
                FirkaIconWidget(
                  FirkaIconType.majesticons,
                  Majesticon.editPen4Solid,
                  color: appStyle.colors.accent,
                  size: 20,
                ),
                SizedBox(width: 8),
                LimitedBox(
                  maxWidth: 160,
                  child: Text(
                    theme,
                    style: appStyle.fonts.B_16SB.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      method,
                      style: appStyle.fonts.B_14R.apply(
                        color: appStyle.colors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: elements,
    );
  }
}
