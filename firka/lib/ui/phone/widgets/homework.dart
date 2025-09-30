import 'package:firka/helpers/api/model/homework.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/widget/firka_icon.dart';
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
              FirkaIconWidget(
                FirkaIconType.majesticons,
                Majesticon.homeSolid,
                color: appStyle.colors.accent,
                size: 24,
              ),
              SizedBox(
                width: 8,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.l10n.homework,
                      style: appStyle.fonts.B_16SB
                          .apply(color: appStyle.colors.textPrimary)),
                  Text(item.subjectName,
                      style: appStyle.fonts.B_16R
                          .apply(color: appStyle.colors.textPrimary))
                ],
              ),
            ],
          )
        ],
      ),
      onTap: () {
        // showGradeBottomSheet(context, widget.data, grade);
      },
    );
  }
}
