import 'package:firka/ui/widget/delayed_spinner.dart';
import 'package:flutter/material.dart';

abstract class StatelessAsyncWidget extends StatelessWidget {
  const StatelessAsyncWidget({super.key});

  Future<Widget> buildAsync(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
        future: buildAsync(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: DelayedSpinnerWidget());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return snapshot.data!;
          }
        });
  }
}
