import 'package:flutter/material.dart';

import '../../ui/model/style.dart';

enum Attach { none, bottom, top }

class FirkaCard extends StatelessWidget {
  final List<Widget> left;
  final List<Widget>? right;
  final Widget? extra;
  final Attach? attached;

  const FirkaCard(
      {required this.left, this.right, this.extra, this.attached, super.key});

  @override
  Widget build(BuildContext context) {
    var right = this.right ?? [];

    var attached = this.attached != null ? this.attached! : Attach.none;
    final defaultRounding = 16.0;
    final attachedRounding = 8.0;

    if (extra != null) {
      return SizedBox(
        width: MediaQuery
            .of(context)
            .size
            .width,
        child: Card(
          color: appStyle.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                    attached == Attach.top
                        ? attachedRounding
                        : defaultRounding),
                topRight: Radius.circular(
                    attached == Attach.top
                        ? attachedRounding
                        : defaultRounding),
                bottomLeft: Radius.circular(
                    attached == Attach.bottom
                        ? attachedRounding
                        : defaultRounding),
                bottomRight: Radius.circular(
                    attached == Attach.bottom
                        ? attachedRounding
                        : defaultRounding)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: left),
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
        width: MediaQuery
            .of(context)
            .size
            .width,
        child: Card(
          color: appStyle.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                    attached == Attach.top
                        ? attachedRounding
                        : defaultRounding),
                topRight: Radius.circular(
                    attached == Attach.top
                        ? attachedRounding
                        : defaultRounding),
                bottomLeft: Radius.circular(
                    attached == Attach.bottom
                        ? attachedRounding
                        : defaultRounding),
                bottomRight: Radius.circular(
                    attached == Attach.bottom
                        ? attachedRounding
                        : defaultRounding)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: left),
                Row(children: right),
              ],
            ),
          ),
        ),
      );
    }
  }
}
