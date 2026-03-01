import 'package:firka/ui/components/firka_card.dart';
import 'package:flutter/material.dart';

import 'package:kreta_api/kreta_api.dart';

// TODO: Finish
class NoticeBoardItemWidget extends StatelessWidget {
  final NoticeBoardItem item;

  const NoticeBoardItemWidget(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return FirkaCard(left: [Text(item.title)]);
  }
}
