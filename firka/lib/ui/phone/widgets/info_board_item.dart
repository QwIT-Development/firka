import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/ui/model/style.dart';
import 'package:flutter/material.dart';

import '../../../helpers/api/model/notice_board.dart';

// TODO: Finish
class InfoBoardItemWidget extends StatelessWidget {
  final InfoBoardItem item;

  const InfoBoardItemWidget(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return FirkaCard(left: [
      Row(
        children: [
          Container(
            decoration: ShapeDecoration(
                color: appStyle.colors.accent,
                shape: CircleBorder(
                  eccentricity: 1,
                  // borderRadius: BorderRadius.circular(6)),
                )),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      item.author[0],
                      style: appStyle.fonts.H_18px.copyWith(
                          fontSize: 20, color: appStyle.colors.textPrimary),
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 1.4,
                child: Text(
                  item.title,
                  style: appStyle.fonts.B_14SB
                      .apply(color: appStyle.colors.textPrimary),
                ),
              ),
              Text(
                item.author,
                style: appStyle.fonts.B_14R
                    .apply(color: appStyle.colors.textSecondary),
              )
            ],
          )
        ],
      )
    ]);
  }
}
