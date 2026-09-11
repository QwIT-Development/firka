import "package:flutter/material.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";

class ColorSlider extends StatelessWidget {
  final double value;
  final LinearGradient trackGradient;
  final Color thumbColor;
  final ValueChanged<double> onChanged;

  const ColorSlider({
    required this.value,
    required this.trackGradient,
    required this.thumbColor,
    required this.onChanged,
    super.key,
  });

  static const _trackHeight = 52.0;
  static const _thumbSize = 28.0;
  static const _thumbRadius = _thumbSize / 2;
  static const _edgePad = 16.0;

  void _setFromLocalX(double localX, double width) {
    final start = _edgePad + _thumbRadius;
    final end = width - _edgePad - _thumbRadius;
    if (end <= start) return;
    final t = ((localX - start) / (end - start)).clamp(0.0, 1.0);
    onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    return FirkaCard.single(
      width: double.infinity,
      height: _trackHeight,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final start = _edgePad + _thumbRadius;
            final end = width - _edgePad - _thumbRadius;
            final thumbLeft = start + value * (end - start) - _thumbRadius;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _setFromLocalX(d.localPosition.dx, width),
              onHorizontalDragUpdate: (d) =>
                  _setFromLocalX(d.localPosition.dx, width),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: BoxDecoration(gradient: trackGradient)),
                  Positioned(
                    left: thumbLeft,
                    top: (_trackHeight - _thumbSize) / 2,
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: thumbColor,
                        border: Border.all(
                          color: appStyle.colors.buttonSecondaryFill,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: appStyle.colors.shadowColor,
                            offset: const Offset(0, 1),
                            blurRadius: appStyle.isLight ? 3 : 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
