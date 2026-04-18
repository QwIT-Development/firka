import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/ui/theme/style.dart';

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
          offset: Offset(2, 4),
          child: FirkaIconWidget(
            FirkaIconType.majesticons,
            Majesticon.editPen4Solid,
            color: appStyle.colors.accent,
            size: 16,
          ),
        ),
      ],
    );
  }
}
