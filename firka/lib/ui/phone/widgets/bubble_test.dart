import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../model/style.dart';

class BubbleTest extends StatelessWidget {
  const BubbleTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset(
          "assets/images/bubble.svg",
          color: appStyle.colors.buttonSecondaryFill,
          width: 24,
          height: 24,
        ),
        Transform.translate(
          offset: Offset(3, 6),
          child: FirkaIconWidget(
            FirkaIconType.majesticons,
            Majesticon.editPen4Line,
            color: appStyle.colors.accent,
            size: 14,
          ),
        ),
      ],
    );
  }
}
