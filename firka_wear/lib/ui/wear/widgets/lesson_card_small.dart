import 'package:flutter/material.dart';
import 'package:kreta_api/kreta_api.dart';

import 'package:firka_wear/ui/components/firka_shadow.dart';
import 'package:firka_wear/ui/shared/class_icon.dart';
import 'package:firka_wear/ui/theme/style.dart';

class LessonCardSmall extends StatelessWidget {
  final String uid;
  final String subjectName;
  final String category;
  final String? roomName;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool shadow;

  const LessonCardSmall({
    required this.uid,
    required this.subjectName,
    required this.category,
    this.roomName,
    this.onTap,
    this.iconColor,
    this.shadow = true,
    super.key,
  });

  factory LessonCardSmall.fromLesson(
    Lesson lesson, {
    VoidCallback? onTap,
    Color? iconColor,
    bool shadow = true,
    Key? key,
  }) {
    return LessonCardSmall(
      uid: lesson.uid,
      subjectName: lesson.name,
      category: lesson.subject?.name ?? '',
      roomName: lesson.roomName,
      onTap: onTap,
      iconColor: iconColor,
      shadow: shadow,
      key: key,
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = 16.0;

    final content = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: ClassIconWidget(
                uid: uid,
                className: subjectName,
                category: category,
                color: iconColor ?? wearStyle.colors.accent,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: wearStyle.fonts.H_14px
                      .copyWith(height: 1.3)
                      .apply(color: wearStyle.colors.textPrimary),
                ),
                Text(
                  roomName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: wearStyle.fonts.B_12R
                      .copyWith(height: 1.3)
                      .apply(color: wearStyle.colors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final child = onTap == null
        ? content
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: content,
          );

    return SizedBox(
      width: double.infinity,
      child: FirkaShadow(
        shadow: shadow,
        radius: radius,
        child: Card(
          elevation: 0,
          shadowColor: Colors.transparent,
          color: wearStyle.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}
