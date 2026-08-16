import "package:flutter/material.dart";

import "package:firka/ui/theme/style.dart";

class FirkaIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  const FirkaIconButton({
    required this.child,
    this.onTap,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? appStyle.colors.buttonSecondaryFill,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: appStyle.colors.shadowColor,
            offset: const Offset(0, 1),
            blurRadius: appStyle.colors.shadowBlur.toDouble(),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return button;

    return GestureDetector(onTap: onTap, child: button);
  }
}
