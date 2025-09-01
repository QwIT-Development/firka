import 'package:firka/helpers/ui/firka_card.dart';
import 'package:flutter/material.dart';

import '../../../helpers/api/model/notice_board.dart';

// TODO: Finish
class NoticeBoardItemWidget extends StatelessWidget {
  final NoticeBoardItem item;

  const NoticeBoardItemWidget(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return FirkaCard(left: [Text(item.title)]);
  }
}
