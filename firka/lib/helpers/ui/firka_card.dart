import 'package:flutter/material.dart';

import '../../ui/model/style.dart';

class FirkaCard extends StatelessWidget {
  final List<Widget> left;
  final List<Widget>? right;
  final Widget? extra;

  const FirkaCard({required this.left, this.right, this.extra, super.key});

  @override
  Widget build(BuildContext context) {
    var right = this.right ?? [];

    if (extra != null) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Card(
          color: appStyle.colors.card,
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
        width: MediaQuery.of(context).size.width,
        child: Card(
          color: appStyle.colors.card,
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
