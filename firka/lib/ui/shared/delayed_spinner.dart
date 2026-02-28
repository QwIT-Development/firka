import 'dart:async';

import 'package:flutter/material.dart';

import 'package:firka/core/state/firka_state.dart';
import 'package:firka/ui/theme/style.dart';

class DelayedSpinnerWidget extends StatefulWidget {
  const DelayedSpinnerWidget({super.key});

  @override
  State<DelayedSpinnerWidget> createState() => _DelayedSpinner();
}

class _DelayedSpinner extends FirkaState<DelayedSpinnerWidget> {
  Timer? timer;
  bool showSpinner = false;

  @override
  void initState() {
    super.initState();

    timer = Timer(Duration(milliseconds: 50), () {
      setState(() {
        showSpinner = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showSpinner) {
      return CircularProgressIndicator(color: appStyle.colors.accent);
    } else {
      return SizedBox();
    }
  }

  @override
  void dispose() {
    super.dispose();

    timer?.cancel();
  }
}
