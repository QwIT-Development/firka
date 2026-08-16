import "package:flutter/material.dart";

class ThemeSwatchIcon extends StatelessWidget {
  final List<Color> swatch;
  final double size;

  const ThemeSwatchIcon({
    required this.swatch,
    this.size = 40,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = swatch.length >= 3
        ? swatch.take(3).toList()
        : [
            ...swatch,
            ...List.filled(3 - swatch.length, Colors.grey),
          ];

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwatchPainter(colors: colors),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  final List<Color> colors;

  _SwatchPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.29;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final d = r * 1.5;
    final left = Offset(cx - d / 2, cy - d * 0.29);
    final right = Offset(cx + d / 2, cy - d * 0.29);
    final bottom = Offset(cx, cy + d * 0.58);
    final centers = [left, right, bottom];

    // Soft per-circle halo.
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        centers[i],
        r,
        Paint()
          ..color = colors[i].withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }

    // Union blend: no white backdrop (that was leaking). First SrcOver, then
    // Multiply so overlaps mix; bottom on top with opacity to lighten.
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawCircle(left, r, Paint()..color = colors[0]);
    canvas.drawCircle(
      right,
      r,
      Paint()
        ..color = colors[1]
        ..blendMode = BlendMode.multiply,
    );
    canvas.restore();

    canvas.drawCircle(
      bottom,
      r,
      Paint()..color = colors[2].withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _SwatchPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}
