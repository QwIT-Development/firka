import 'dart:async';

import 'package:flutter/material.dart';

import 'package:firka_common/ui/theme/style.dart';

class DelayedSpinnerWidget extends StatefulWidget {
  final Color? color;

  const DelayedSpinnerWidget({super.key, this.color});

  @override
  State<DelayedSpinnerWidget> createState() => _DelayedSpinner();
}

class _DelayedSpinner extends State<DelayedSpinnerWidget> {
  Timer? timer;
  bool showSpinner = false;

  @override
  void initState() {
    super.initState();

    timer = Timer(const Duration(milliseconds: 50), () {
      setState(() {
        showSpinner = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showSpinner) {
      return CircularProgressIndicator(
        color: widget.color ?? appStyle.colors.accent,
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    super.dispose();

    timer?.cancel();
  }
}
