import 'package:flutter/material.dart';

import '../../../../helpers/firka_state.dart';

class PageWithSubPages extends StatefulWidget {
  final int pageIndex;
  final List<Widget Function(void Function(int))> subPages;

  const PageWithSubPages(this.subPages, {Key? key, required this.pageIndex})
      : super(key: key);

  @override
  _PageWithSubPagesState createState() => _PageWithSubPagesState();
}

class _PageWithSubPagesState extends FirkaState<PageWithSubPages> {
  int _currentSubPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.subPages[_currentSubPage]((page) {
        setState(() {
          _currentSubPage = page;
        });
      }),
    );
  }
}
