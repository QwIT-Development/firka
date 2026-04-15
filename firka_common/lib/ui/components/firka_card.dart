import 'package:flutter/material.dart';

import 'package:firka_common/ui/components/firka_shadow.dart';
import 'package:firka_common/ui/theme/style.dart';

enum Attach { none, bottom, top }

class FirkaCard extends StatelessWidget {
  final double padding;
  final double? height;
  final bool shadow;
  final Attach attached;
  final Color? color;
  final bool? isLightMode;
  final Widget child;

  factory FirkaCard({
    required List<Widget> left,
    double padding = 12,
    bool shadow = true,
    List<Widget> center = const [],
    List<Widget> right = const [],
    Widget? extra,
    Attach attached = Attach.none,
    Color? color,
    double? height,
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
      attached: attached,
      color: color,
      height: height,
      shadow: shadow,
      isLightMode: isLightMode,
      child: extra == null
          ? alignedRow
          : Column(children: [alignedRow, extra!]),
    );
  }

  const FirkaCard.single({
    this.padding = 0,
    this.shadow = true,
    this.attached = Attach.none,
    this.color,
    this.height,
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

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: height,
      child: FirkaShadow(
        shadow: shadow,
        isLightMode: isLight,
        child: Card(
          color: color ?? appStyle.colors.card,
          shadowColor: isLight && shadow ? null : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                attached == Attach.top ? attachedRounding : defaultRounding,
              ),
              bottom: Radius.circular(
                attached == Attach.bottom ? attachedRounding : defaultRounding,
              ),
            ),
          ),
          child: Padding(padding: EdgeInsets.all(this.padding), child: child),
        ),
      ),
    );
  }
}
