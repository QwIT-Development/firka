import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

enum FirkaIconType {
  Majesticons,
  MajesticonsLocal,
}

class FirkaIconWidget extends StatelessWidget {
  final FirkaIconType iconType;
  final Object iconData;
  final Color color;
  final double? size;

  const FirkaIconWidget(this.iconType, this.iconData,
      {super.key, this.color = Colors.white, this.size});

  @override
  Widget build(BuildContext context) {
    switch (iconType) {
      case FirkaIconType.Majesticons:
        return Majesticon(iconData as Uint8List, color: color, size: size);
      case FirkaIconType.MajesticonsLocal:
        return SvgPicture.asset(
          'assets/majesticons/${iconData as String}.svg',
          color: color,
          height: size,
        );
    }
  }
}
