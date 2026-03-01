import 'package:kreta_api/kreta_api.dart';
import 'package:firka/data/models/homework_cache_model.dart';
import 'package:firka/ui/components/common_bottom_sheets.dart';
import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

class HomeworkWidget extends StatelessWidget {
  final AppInitialization data;
  final Homework item;

  const HomeworkWidget(this.data, this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: FirkaCard(
        left: [
          Row(
            children: [
              FutureBuilder<bool>(
                future: isHomeworkDone(data.isar, item.uid),
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
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<bool>(
                    future: isHomeworkDone(data.isar, item.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox();
                      }
                      final done = snapshot.data!;
                      return done
                          ? Text(
                              data.l10n.homework,
                              style: appStyle.fonts.B_16SB.apply(
                                color: appStyle.colors.textPrimary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            )
                          : Text(
                              data.l10n.homework,
                              style: appStyle.fonts.B_16SB.apply(
                                color: appStyle.colors.textPrimary,
                              ),
                            );
                    },
                  ),
                  Text(
                    item.subjectName,
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        showHomeworkBottomSheet(context, data, item);
      },
    );
  }
}
