import "package:firka/app/app_state.dart";
import "package:firka/core/bloc/app_icon_picker_cubit.dart";
import "package:firka/core/image_preloader.dart";
import "package:firka/core/settings.dart";
import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";
import "package:firka/core/settings/settings_ui.dart";
import "package:firka/core/firka_bundle.dart";
import "package:firka/ui/components/firka_button.dart";
import "package:firka/ui/theme/style.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "settings_bool_row.dart";

class SettingsAppIconPreviewView extends StatelessWidget {
  final AppInitialization data;

  const SettingsAppIconPreviewView({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final activeIcon = context.watch<AppIconPickerCubit>().state.activeIcon;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: PreloadedImageProvider(
            FirkaBundle(),
            ('assets/images/background.webp'),
          ),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  child: Image(
                    image: PreloadedImageProvider(
                      FirkaBundle(),
                      "assets/images/icons/$activeIcon.webp",
                    ),
                    width: 74,
                    height: 74,
                  ),
                ),
                Text(
                  appIconLabels(data.l10n)[activeIcon]!,
                  style: appStyle.fonts.H_12px.apply(
                    color: appStyle.colors.card,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsAppIconPickerView extends StatelessWidget {
  final AppInitialization data;
  final SettingsUiAppIconPicker item;
  final SettingsRepository settings;
  final void Function(VoidCallback fn) setStateOuter;

  const SettingsAppIconPickerView({
    required this.data,
    required this.item,
    required this.settings,
    required this.setStateOuter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AppIconPickerCubit>();
    final activeIcon = cubit.state.activeIcon;
    final saving = cubit.state.saving;

    List<Widget> pWidgets = [];

    for (var group in item.iconGroups.keys) {
      if (Settings.childProtection.value) {
        if (group == data.l10n.s_ci_icon_g7) {
          continue;
        }
      } else {
        if (group == data.l10n.s_ci_icon_g8) {
          continue;
        }
      }
      List<Widget> groupIcons = [];
      for (var icon in item.iconGroups[group]!) {
        var active = icon == activeIcon;

        groupIcons.add(
          Column(
            children: [
              GestureDetector(
                child: active
                    ? Container(
                        decoration: BoxDecoration(
                          color: appStyle.colors.accent,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12.0),
                            ),
                            child: Image(
                              image: PreloadedImageProvider(
                                FirkaBundle(),
                                "assets/images/icons/$icon.webp",
                              ),
                              width: 48,
                              height: 48,
                            ),
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16.0),
                        ),
                        child: Image(
                          image: PreloadedImageProvider(
                            FirkaBundle(),
                            "assets/images/icons/$icon.webp",
                          ),
                          width: 54,
                          height: 54,
                        ),
                      ),
                onTap: () {
                  if (saving) return;

                  cubit.select(icon);
                },
              ),
              Text(
                appIconLabels(data.l10n)[icon]!,
                style: appStyle.fonts.B_12R.apply(
                  color: active
                      ? appStyle.colors.textPrimary
                      : appStyle.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      pWidgets.add(
        Text(
          group,
          style: appStyle.fonts.H_14px.apply(
            color: appStyle.colors.textPrimary,
          ),
        ),
      );

      if (group == data.l10n.s_ci_icon_g6) {
        pWidgets.add(
          Text(
            data.l10n.s_ci_icon_g6_desc,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textSecondary,
            ),
          ),
        );
      }

      if (group == data.l10n.s_ci_icon_g7 || group == data.l10n.s_ci_icon_g8) {
        pWidgets.add(SizedBox(height: 12));
        pWidgets.add(
          buildBoolRow(item.childProtection, settings, setStateOuter),
        );
      }

      pWidgets.add(SizedBox(height: 12));
      pWidgets.add(
        SizedBox(
          height: (groupIcons.length / 4).ceil() * 100,
          child: GridView.count(
            crossAxisCount: 4,
            physics: NeverScrollableScrollPhysics(),
            children: groupIcons,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height / 1.7,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: pWidgets,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              child: FirkaButton(
                text: data.l10n.cancel,
                bgColor: appStyle.colors.buttonSecondaryFill,
                fontStyle: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textSecondary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            GestureDetector(
              child: FirkaButton(
                text: data.l10n.save,
                bgColor: appStyle.colors.accent,
                fontStyle: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textSecondaryLight,
                ),
              ),
              onTap: () async {
                if (saving) return;

                await cubit.save(
                  appIconLabels(
                    data.l10n,
                  ).keys.where((e) => e != "original").toList(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
