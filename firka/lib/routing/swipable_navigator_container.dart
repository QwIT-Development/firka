import 'package:firka/routing/chart_interaction_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SwipableNavigatorContainer extends StatefulWidget {
  const SwipableNavigatorContainer({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<SwipableNavigatorContainer> createState() =>
      _SwipableNavigatorContainerState();
}

class _SwipableNavigatorContainerState
    extends State<SwipableNavigatorContainer> {
  late PageController _pageController;
  bool _isAnimating = false;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(SwipableNavigatorContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _syncToShellIndex();
    }
  }

  void _syncToShellIndex() {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      if (_pageController.hasClients &&
          _pageController.page?.round() !=
              widget.navigationShell.currentIndex) {
        _pageController.jumpToPage(widget.navigationShell.currentIndex);
      }
      return;
    }
    if (!_pageController.hasClients) return;
    if (_pageController.page?.round() == widget.navigationShell.currentIndex) {
      return;
    }
    _isAnimating = true;
    _pageController
        .animateToPage(
          widget.navigationShell.currentIndex,
          duration: const Duration(milliseconds: 175),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) _isAnimating = false;
        });
  }

  void _onPageChanged(int index) {
    if (_isAnimating) return;
    if (index != widget.navigationShell.currentIndex) {
      HapticFeedback.heavyImpact();
      widget.navigationShell.goBranch(index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChartInteracting = ChartInteractionScope.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: isChartInteracting,
      builder: (context, interacting, _) {
        return PageView(
          controller: _pageController,
          physics: interacting
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: widget.children,
        );
      },
    );
  }
}
