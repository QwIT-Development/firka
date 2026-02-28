import 'package:flutter/material.dart';

class ChartInteractionScope extends StatefulWidget {
  const ChartInteractionScope({super.key, required this.child});

  final Widget child;

  static ValueNotifier<bool> of(BuildContext context) {
    final data = context
        .dependOnInheritedWidgetOfExactType<_ChartInteractionScopeData>();
    assert(data != null, 'ChartInteractionScope not found in context');
    return data!.isChartInteracting;
  }

  @override
  State<ChartInteractionScope> createState() => _ChartInteractionScopeState();
}

class _ChartInteractionScopeState extends State<ChartInteractionScope> {
  final ValueNotifier<bool> _isChartInteracting = ValueNotifier(false);

  @override
  void dispose() {
    _isChartInteracting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ChartInteractionScopeData(
      isChartInteracting: _isChartInteracting,
      child: widget.child,
    );
  }
}

class _ChartInteractionScopeData extends InheritedWidget {
  const _ChartInteractionScopeData({
    required this.isChartInteracting,
    required super.child,
  });

  final ValueNotifier<bool> isChartInteracting;

  @override
  bool updateShouldNotify(_ChartInteractionScopeData oldWidget) =>
      isChartInteracting != oldWidget.isChartInteracting;
}
