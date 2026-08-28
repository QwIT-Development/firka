import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_ui.dart";
import "package:firka/ui/phone/screens/settings/settings_metrics.dart";
import "package:firka/ui/phone/screens/settings/settings_toggle.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:flutter/material.dart";

Widget buildBoolRow(
  BuildContext context,
  SettingsUiBoolean item,
  SettingsRepository settings,
  void Function(VoidCallback fn) setStateOuter,
) {
  final value = settings.get(item.setting);
  final scale = settingsScale(context);

  return FirkaCard(
    height: settingsItemHeight * scale,
    rounding: settingsItemRounding * scale,
    left: [
      item.iconType != null
          ? Row(
              children: [
                FirkaIconWidget(
                  item.iconType!,
                  item.iconData!,
                  color: appStyle.colors.accent,
                ),
                SizedBox(width: 12 * scale),
              ],
            )
          : SizedBox(),
      Text(
        item.title,
        style: appStyle.fonts.B_16SB.apply(color: appStyle.colors.textPrimary),
      ),
    ],
    right: [
      SettingsToggle(
        value: value,
        scale: scale,
        onChanged: (v) async {
          await settings.set(item.setting, v);
          setStateOuter(() {});
        },
      ),
    ],
  );
}
