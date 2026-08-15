import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_ui.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:flutter/material.dart";

Widget buildBoolRow(
  SettingsUiBoolean item,
  SettingsRepository settings,
  void Function(VoidCallback fn) setStateOuter,
) {
  final value = settings.get(item.setting);

  return FirkaCard(
    height: 52 + 12,
    left: [
      item.iconType != null
          ? Row(
              children: [
                FirkaIconWidget(
                  item.iconType!,
                  item.iconData!,
                  color: appStyle.colors.accent,
                ),
                SizedBox(width: 4),
              ],
            )
          : SizedBox(),
      Text(
        item.title,
        style: appStyle.fonts.B_16SB.apply(color: appStyle.colors.textPrimary),
      ),
    ],
    right: [
      Switch(
        value: value,
        thumbColor: WidgetStateProperty.fromMap({
          WidgetState.selected: appStyle.colors.buttonSecondaryFill,
          WidgetState.any: appStyle.colors.accent,
        }),
        trackColor: WidgetStateProperty.fromMap({
          WidgetState.selected: appStyle.colors.accent,
          WidgetState.any: appStyle.colors.a10p,
        }),
        trackOutlineColor: WidgetStateProperty.fromMap({
          WidgetState.selected: appStyle.colors.accent,
          WidgetState.any: appStyle.colors.a15p,
        }),
        onChanged: (v) async {
          await settings.set(item.setting, v);
          setStateOuter(() {});
        },
      ),
    ],
  );
}
