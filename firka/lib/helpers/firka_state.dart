import 'package:firka/main.dart';
import 'package:flutter/widgets.dart';

abstract class FirkaState<T extends StatefulWidget> extends State<T> {
  @override
  @mustCallSuper
  void initState() {
    super.initState();
    globalUpdate.addListener(_doUpdate);
  }

  void _doUpdate() {
    if (mounted) setState(() {});
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();

    globalUpdate.removeListener(_doUpdate);
    globalUpdate.addListener(_doUpdate);
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();

    globalUpdate.removeListener(_doUpdate);
  }
}
