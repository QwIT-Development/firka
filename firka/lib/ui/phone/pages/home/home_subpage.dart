import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/firka_state.dart';
import '../../../../helpers/update_notifier.dart';
import '../../../model/style.dart';

class PageWithSubPages extends StatefulWidget {
  final int pageIndex;
  final List<Widget Function(void Function(int))> subPages;
  final ValueNotifier<bool> subPageActive;
  final UpdateNotifier back;

  const PageWithSubPages(this.subPages, this.subPageActive, this.back,
      {Key? key, required this.pageIndex})
      : super(key: key);

  @override
  _PageWithSubPagesState createState() => _PageWithSubPagesState();
}

class _PageWithSubPagesState extends FirkaState<PageWithSubPages> {
  int _currentSubPage = 0;

  @override
  void initState() {
    super.initState();

    widget.back.addListener(_backListener);
  }

  void _backListener() {
    if (!mounted) return;

    setState(() {
      subPageActive.value = false;
      _currentSubPage = 0;
    });
  }

  @override
  void didUpdateWidget(PageWithSubPages oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.back.removeListener(_backListener);
    widget.back.addListener(_backListener);
  }

  @override
  void dispose() {
    super.dispose();

    widget.back.removeListener(_backListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: widget.subPages[_currentSubPage]((page) {
        subPageActive.value = _currentSubPage == 0;
        setState(() {
          _currentSubPage = page;
        });
      }),
    );
  }
}
