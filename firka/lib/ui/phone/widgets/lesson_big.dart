import 'package:firka/core/extensions.dart';
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

class LessonBigWidget extends StatelessWidget {
  final AppInitialization data;
  final int lessonNo;
  final Lesson lesson;
  final Test? test;
  final bool active;

  const LessonBigWidget(
    this.data,
    this.lessonNo,
    this.lesson,
    this.test, {
    this.active = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isSubstituted = lesson.substituteTeacher != null;
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

    var subjectName = lesson.subject?.name.firstUpper() ?? 'N/A';

    var roomName = lesson.roomName ?? 'N/A';

    Widget extra = test == null
        ? Column(
            spacing: 4,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (timeNow().isAfter(lesson.start)
                            ? lesson.end
                                  .difference(timeNow())
                                  .timeLeft(initData.l10n)
                            : null) ??
                        lesson.start.format(data.l10n, FormatMode.hmm),
                    style: appStyle.fonts.B_14R.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                  Text(
                    lesson.end.format(initData.l10n, FormatMode.hmm),
                    style: appStyle.fonts.B_14R.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LinearProgressIndicator(
                  value:
                      timeNow().difference(lesson.start).inMilliseconds /
                      lesson.end.difference(lesson.start).inMilliseconds,
                  backgroundColor: appStyle.colors.a15p,
                  color: appStyle.colors.accent,
                  minHeight: 8,
                ),
              ),
            ],
          )
        : Container(
            height: 28,
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: appStyle.colors.background,
            ),
            child: Row(
              children: [
                FirkaIconWidget(
                  FirkaIconType.majesticons,
                  Majesticon.editPen4Solid,
                  size: 12,
                  color: appStyle.colors.accent,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    test!.theme ?? "",
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );

    return GestureDetector(
      onTap: () {
        showLessonBottomSheet(
          context,
          data,
          lesson,
          accent,
          secondary,
          bgColor,
          test,
        );
      },
      child: FirkaCard.single(
        height: 104,
        borderColor: active ? appStyle.colors.accent : null,
        margin: EdgeInsets.only(bottom: active ? 0 : 1),
        padding: EdgeInsets.only(left: 16, right: 16),
        color: isDismissed
            ? appStyle.colors.cardTranslucent
            : appStyle.colors.card,
        shadow: !isDismissed,
        child: Column(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.center,
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
                        style: appStyle.fonts.B_14SB.apply(color: secondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                FilledCircle(
                  diameter: 32,
                  color: bgColor,
                  child: ClassIconWidget(
                    uid: lesson.uid,
                    className: lesson.name,
                    category: subjectName,
                    color: accent,
                    size: 20,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 8,
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
                            if (isSubstituted)
                              Text(
                                lesson.substituteTeacher!,
                                style: appStyle.fonts.B_14R.apply(
                                  color: appStyle.colors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                              style: appStyle.fonts.B_14R.apply(
                                color: appStyle.colors.secondary,
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
                if (test != null) SizedBox(width: 8),
                if (test != null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lesson.start.toLocal().format(
                          data.l10n,
                          FormatMode.hmm,
                        ),
                        style: appStyle.fonts.B_14R.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            extra,
          ],
        ),
      ),
    );
  }
}
