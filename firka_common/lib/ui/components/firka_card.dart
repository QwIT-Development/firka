import 'package:flutter/material.dart';

import 'package:firka_common/ui/theme/style.dart';

enum Attach { none, bottom, top }

class FirkaCard extends StatelessWidget {
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? borderColor;
  final double? height;
  final double? width;
  final bool shadow;
  final Attach attached;
  final Color? color;
  final bool? isLightMode;
  final Widget child;

  factory FirkaCard({
    required List<Widget> left,
    EdgeInsets padding = const EdgeInsets.all(12),
    EdgeInsets margin = const EdgeInsets.all(4),
    bool shadow = true,
    List<Widget> center = const [],
    List<Widget> right = const [],
    Widget? extra,
    Attach attached = Attach.none,
    Color? color,
    double? height,
    double? width,
    bool? isLightMode,
  }) {
    final leftRow = Row(children: left);

    final alignedRow = right.isEmpty && center.isEmpty
        ? leftRow
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              leftRow,
              Row(children: center),
              Row(children: right),
            ],
          );
    return FirkaCard.single(
      padding: padding,
      margin: margin,
      attached: attached,
      color: color,
      height: height,
      shadow: shadow,
      isLightMode: isLightMode,
      child: extra == null ? alignedRow : Column(children: [alignedRow, extra]),
    );
  }

  const FirkaCard.single({
    this.padding = const EdgeInsets.all(0),
    this.margin = const EdgeInsets.all(4),
    this.shadow = true,
    this.attached = Attach.none,
    this.borderColor,
    this.color,
    this.height,
    this.width,
    this.isLightMode,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRounding = 16.0;
    final attachedRounding = 8.0;
    final isLight =
        isLightMode ?? Theme.of(context).brightness == Brightness.light;

    return Container(
      height: height,
      width: width,
      padding: padding,
      margin: margin,
      decoration: ShapeDecoration(
        shadows: shadow
            ? [
                BoxShadow(
                  color: appStyle.colors.shadowColor,
                  offset: const Offset(0, 1),
                  blurRadius: isLight ? 2.0 : 0,
                ),
              ]
            : [],
        shape: RoundedRectangleBorder(
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              attached == Attach.top ? attachedRounding : defaultRounding,
            ),
            bottom: Radius.circular(
              attached == Attach.bottom ? attachedRounding : defaultRounding,
            ),
          ),
        ),
        color: color ?? appStyle.colors.card,
      ),
      child: child,
    );
  }
}
