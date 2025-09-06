import 'package:flutter/material.dart';

import '../../ui/model/style.dart';

enum Attach { none, bottom, top }

class FirkaCard extends StatelessWidget {
  final List<Widget> left;
  final List<Widget>? center;
  final double? height;
  final List<Widget>? right;
  final bool shadow;
  final Widget? extra;
  final Attach? attached;
  final Color? color;

  const FirkaCard(
      {required this.left,
      this.shadow = true,
      this.center,
      this.right,
      this.extra,
      this.attached,
      this.color,
      this.height,
      super.key});

  @override
  Widget build(BuildContext context) {
    var right = this.right ?? [];

    var attached = this.attached != null ? this.attached! : Attach.none;
    final defaultRounding = 16.0;
    final attachedRounding = 8.0;

    if (extra != null) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: height,
        child: Card(
          color: color ?? appStyle.colors.card,
          shadowColor: shadow ? null : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(attached == Attach.top
                    ? attachedRounding
                    : defaultRounding),
                topRight: Radius.circular(attached == Attach.top
                    ? attachedRounding
                    : defaultRounding),
                bottomLeft: Radius.circular(attached == Attach.bottom
                    ? attachedRounding
                    : defaultRounding),
                bottomRight: Radius.circular(attached == Attach.bottom
                    ? attachedRounding
                    : defaultRounding)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: left),
                    Row(children: center ?? []),
                    Row(children: right),
                  ],
                ),
                extra ?? SizedBox(),
              ],
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: height,
        child: Card(
          color: color ?? appStyle.colors.card,
          shadowColor: shadow ? null : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(attached == Attach.top
                    ? attachedRounding
                    : defaultRounding),
                topRight: Radius.circular(attached == Attach.top
                    ? attachedRounding
                    : defaultRounding),
                bottomLeft: Radius.circular(attached == Attach.bottom
                    ? attachedRounding
                    : defaultRounding),
                bottomRight: Radius.circular(attached == Attach.bottom
                    ? attachedRounding
                    : defaultRounding)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: left),
                Row(children: center ?? []),
                Row(children: right),
              ],
            ),
          ),
        ),
      );
    }
  }
}
