import "package:firka/ui/theme/style.dart";
import "package:flutter/material.dart";

class SettingsToggle extends StatelessWidget {
  static const _designWidth = 40.0;
  static const _designHeight = 24.0;
  static const _designKnob = 20.0;

  final bool value;
  final double scale;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    required this.value,
    required this.onChanged,
    this.scale = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width = _designWidth * scale;
    final height = _designHeight * scale;
    final knob = _designKnob * scale;
    final inset = (height - knob) / 2;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: value ? appStyle.colors.accent : appStyle.colors.a15p,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: BoxDecoration(
                    color: value
                        ? appStyle.colors.buttonSecondaryFill
                        : appStyle.colors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
