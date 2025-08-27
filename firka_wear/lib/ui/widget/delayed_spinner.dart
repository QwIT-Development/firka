import 'dart:async';

import 'package:flutter/material.dart';

class DelayedSpinnerWidget extends StatefulWidget {
  const DelayedSpinnerWidget({super.key});

  @override
  State<DelayedSpinnerWidget> createState() => _DelayedSpinner();
}

class _DelayedSpinner extends State<DelayedSpinnerWidget> {
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
      return CircularProgressIndicator();
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
