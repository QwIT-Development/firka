import 'package:firka/core/firka_bundle.dart';
import 'package:firka/core/image_preloader.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Generates a [ColorFilter] that recolors Dave mascot's green accents
/// (#A7DC22) to [targetColor] while preserving all black and white paths/pixels.
ColorFilter? getDaveColorFilter([Color? targetColor]) {
  final color = targetColor ?? appStyle.colors.accent;

  // If the target color is already the default Firka green (#A7DC22), no filter needed.
  if ((color.toARGB32() & 0x00FFFFFF) == 0x00A7DC22) {
    return null;
  }

  // Source green color: #A7DC22 -> R=167, G=220, B=34
  const double gSrc = 220.0 / 255.0;
  const double bSrc = 34.0 / 255.0;
  const double denom = gSrc - bSrc; // 186.0 / 255.0

  final double rTgt = color.r;
  final double gTgt = color.g;
  final double bTgt = color.b;

  final double m01 = (rTgt - bSrc) / denom;
  final double m02 = 1.0 - m01;

  final double m11 = (gTgt - bSrc) / denom;
  final double m12 = 1.0 - m11;

  final double m21 = (bTgt - bSrc) / denom;
  final double m22 = 1.0 - m21;

  return ColorFilter.matrix(<double>[
    0.0, m01, m02, 0.0, 0.0,
    0.0, m11, m12, 0.0, 0.0,
    0.0, m21, m22, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]);
}

class DaveMascot extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final String asset;
  final bool isError;
  final BoxFit fit;

  const DaveMascot({
    super.key,
    this.width,
    this.height,
    this.color,
    this.asset = 'assets/images/logos/dave.svg',
    this.isError = false,
    this.fit = BoxFit.contain,
  });

  const DaveMascot.icon({
    super.key,
    this.width = 24,
    this.height = 24,
    this.color,
    this.asset = 'assets/icons/dave.svg',
    this.isError = false,
    this.fit = BoxFit.contain,
  });

  const DaveMascot.error({
    super.key,
    this.width = 50,
    this.height = 50,
    this.color,
    this.asset = 'assets/images/logos/dave_error.png',
    this.isError = true,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final filter = getDaveColorFilter(color);

    if (isError) {
      Widget image = Image(
        image: PreloadedImageProvider(
          FirkaBundle(),
          'assets/images/logos/dave_error.png',
        ),
        width: width,
        height: height,
        fit: fit,
      );

      if (filter != null) {
        image = ColorFiltered(
          colorFilter: filter,
          child: image,
        );
      }

      return Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          shape: ContinuousRectangleBorder(),
        ),
        child: image,
      );
    }

    Widget svg = SvgPicture.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
    );

    if (filter != null) {
      svg = ColorFiltered(
        colorFilter: filter,
        child: svg,
      );
    }

    return svg;
  }
}
