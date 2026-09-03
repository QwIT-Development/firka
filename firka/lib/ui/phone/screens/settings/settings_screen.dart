import 'dart:async';

import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:firka/core/bloc/app_icon_picker_cubit.dart';
import 'package:firka/core/bloc/theme_cubit.dart';
import 'package:firka/core/settings/setting.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/core/settings/settings_ui.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/core/state/firka_state.dart';

import 'settings_account_picker.dart';
import 'settings_app_icon_picker.dart';
import 'settings_bool_row.dart';
import 'settings_fcm_status.dart';
import 'settings_metrics.dart';
import 'settings_license_page.dart';
import 'settings_logs.dart';
import 'settings_personalization_view.dart';

class SettingsScreen extends StatefulWidget {
  final AppInitialization data;
  final List<SettingsUiNode> items;

  const SettingsScreen(this.data, this.items, {super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends FirkaState<SettingsScreen> {
  _SettingsScreenState();

  late List<TokenModel> tokens;
  late final AppIconPickerCubit appIconPickerCubit;
  StreamSubscription<ThemeState>? _themeSub;

  @override
  void initState() {
    super.initState();

    tokens = isarInit.tokenModels.where().sortByUpdatedAtMsDesc().findAllSync();
    appIconPickerCubit = AppIconPickerCubit(Settings.appIcon.value);
    _themeSub = widget.data.themeCubit.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _themeSub?.cancel();
    appIconPickerCubit.close();
    super.dispose();
  }

  String _roundedDoubleString(double value, DoubleSetting setting) {
    return setting.precision == 0
        ? value.toString().split(".")[0]
        : value.toStringAsPrecision(setting.precision) == "0.0"
        ? "0"
        : value.toStringAsPrecision(setting.precision);
  }

  List<Widget> createWidgetTree(
    Iterable<SettingsUiNode> items,
    SettingsRepository settings, {
    bool forceRender = false,
  }) {
    var widgets = List<Widget>.empty(growable: true);
    final scale = settingsScale(context);

    for (var item in items) {
      if (!forceRender && !item.visible()) continue;
      if (item is SettingsUiGroup) {
        widgets.addAll(createWidgetTree(item.children, settings));

        continue;
      }
      if (item is SettingsUiPadding) {
        widgets.add(SizedBox(width: item.padding, height: item.padding));

        continue;
      }
      if (item is SettingsUiBackHeader) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.chevronLeftLine,
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-8, 1),
                        child: Text(
                          item.title,
                          style: appStyle.fonts.B_16R.apply(
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5),
            ],
          ),
        );

        continue;
      }
      if (item is SettingsUiHeader) {
        widgets.add(
          Text(
            headingText(item.title),
            style: appStyle.fonts.H_H1.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        );

        continue;
      }
      if (item is SettingsUiMediumHeader) {
        widgets.add(
          Text(
            headingText(item.title),
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        );

        continue;
      }
      if (item is SettingsUiHeaderSmall) {
        widgets.add(
          Text(
            item.title,
            style: appStyle.fonts.H_14px.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        );

        continue;
      }
      if (item is SettingsUiSubGroup) {
        List<Widget> cardWidgets = [];

        if (item.iconType != null && item.iconData != null) {
          cardWidgets.add(
            FirkaIconWidget(
              item.iconType!,
              item.iconData!,
              color: appStyle.colors.accent,
            ),
          );
          cardWidgets.add(SizedBox(width: 12 * scale));
        }

        cardWidgets.add(
          item.subtitle == null
              ? Text(
                  item.title,
                  style: appStyle.fonts.B_16SB.apply(
                    color: appStyle.colors.textPrimary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Text(
                      item.title,
                      style: appStyle.fonts.B_16SB
                          .apply(color: appStyle.colors.textPrimary)
                          .copyWith(height: 1.1),
                    ),
                    Text(
                      item.subtitle!,
                      style: appStyle.fonts.B_14R
                          .apply(color: appStyle.colors.textSecondary)
                          .copyWith(height: 1.1),
                    ),
                  ],
                ),
        );

        widgets.add(
          GestureDetector(
            onTap: () {
              if (item.children.isEmpty && item.redirectTo == null) return;
              if (item.redirectTo != null && item.redirectTo == "discord") {
                launchUrlString(
                  "https://discord.com/invite/firka-1111649116020285532",
                );
                return;
              } else if (item.redirectTo != null &&
                  item.redirectTo == "privacy") {
                launchUrlString("https://firka.app/privacy");
                return;
              } else {
                context.push('/settings', extra: item.children);
              }
            },
            child: item.redirectTo != null
                ? FirkaCard(
                    height: settingsItemHeight * scale,
                    rounding: settingsItemRounding * scale,
                    left: cardWidgets,
                    right: [
                      RotationTransition(
                        turns: AlwaysStoppedAnimation(-45 / 360),
                        child: FirkaIconWidget(
                          FirkaIconType.majesticons,
                          Majesticon.arrowRightSolid,
                          size: 24,
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : FirkaCard(
                    height: settingsItemHeight * scale,
                    rounding: settingsItemRounding * scale,
                    left: cardWidgets,
                  ),
          ),
        );

        continue;
      }

      if (item is SettingsUiDouble) {
        final value = settings.get(item.setting);
        var v = _roundedDoubleString(value, item.setting);

        widgets.add(
          GestureDetector(
            child: FirkaCard(
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
                          SizedBox(width: 4),
                        ],
                      )
                    : SizedBox(),
                Text(
                  item.title,
                  style: appStyle.fonts.B_16SB.apply(
                    color: appStyle.colors.textPrimary,
                  ),
                ),
              ],
              right: [
                Text(
                  v == "0.0" ? "0" : v,
                  style: appStyle.fonts.B_16R.apply(
                    color: appStyle.colors.textPrimary,
                  ),
                ),
              ],
            ),
            onTap: () async {
              showSetDoubleSheet(context, item, value, widget.data, setState);
            },
          ),
        );

        continue;
      }
      if (item is SettingsUiBoolean) {
        widgets.add(buildBoolRow(context, item, settings, setState));

        continue;
      }
      if (item is SettingsUiEnum) {
        final activeIndex = settings.get(item.setting).index;
        for (var i = 0; i < item.optionLabels.length; i++) {
          var k = item.optionLabels[i];

          if (i == activeIndex) {
            widgets.add(
              FirkaCard(
                height: settingsItemHeight * scale,
              rounding: settingsItemRounding * scale,
                left: [
                  Text(
                    k,
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ],
                right: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Checkbox(
                      value: true,
                      fillColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        return appStyle.colors.secondary;
                      }),
                      onChanged: (_) async {
                        await settings.set(
                          item.setting,
                          item.setting.values[i],
                        );
                        setState(() {});
                        logger.finest('Settings saved');
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            );
          } else {
            widgets.add(
              GestureDetector(
                child: FirkaCard(
                  height: settingsItemHeight * scale,
              rounding: settingsItemRounding * scale,
                  left: [
                    Text(
                      k,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                  right: [SizedBox(height: 16 + 8)],
                ),
                onTap: () async {
                  await settings.set(item.setting, item.setting.values[i]);
                  setState(() {});
                },
              ),
            );
          }
        }

        continue;
      }
      if (item is SettingsUiLicensePage) {
        widgets.add(SettingsLicensePageView(data: widget.data));
        continue;
      }

      if (item is SettingsUiAppIconPreview) {
        widgets.add(SettingsAppIconPreviewView(data: widget.data));

        continue;
      }
      if (item is SettingsUiPersonalization) {
        widgets.add(
          SettingsPersonalizationView(
            data: widget.data,
            item: item,
          ),
        );

        continue;
      }
      if (item is SettingsUiAppIconPicker) {
        widgets.add(
          SettingsAppIconPickerView(
            data: widget.data,
            item: item,
            settings: settings,
            setStateOuter: setState,
          ),
        );

        continue;
      }
      if (item is SettingsUiKretaAccountPicker) {
        widgets.add(
          SettingsAccountPickerView(
            data: widget.data,
            tokens: tokens,
            setStateOuter: setState,
          ),
        );
        continue;
      }
      if (item is SettingsUiButton) {
        widgets.add(
          GestureDetector(
            child: FirkaCard(
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
                          SizedBox(width: 8),
                        ],
                      )
                    : SizedBox(),
                Text(
                  item.title,
                  style: appStyle.fonts.B_16SB.apply(
                    color: appStyle.colors.textPrimary,
                  ),
                ),
              ],
            ),
            onTap: () async {
              await item.onTap();
            },
          ),
        );

        continue;
      }
      if (item is SettingsUiLogs) {
        widgets.add(SettingsLogsView(data: widget.data));
        continue;
      }
      if (item is SettingsUiFcmStatus) {
        widgets.add(SettingsFcmStatusView(data: widget.data));
        continue;
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    var body = createWidgetTree(widget.items, widget.data.settings);

    return BlocProvider.value(
      value: appIconPickerCubit,
      child: DefaultAssetBundle(
        bundle: FirkaBundle(),
        child: Scaffold(
          backgroundColor: appStyle.colors.background,
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showSetDoubleSheet(
  BuildContext context,
  SettingsUiDouble item,
  double initialValue,
  AppInitialization data,
  void Function(VoidCallback fn) setStateOuter,
) {
  final setting = item.setting;
  double currentValue = initialValue;

  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.13,
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, setState) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: appStyle.colors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 18.0,
                    right: 16.0,
                    bottom: 30.0,
                    top: 20.0,
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          item.title,
                          style: appStyle.fonts.B_16R.apply(
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 40,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              // TODO: Make a firka slider
                              child: Slider(
                                min: setting.min,
                                value: currentValue,
                                max: setting.max,
                                divisions: setting.step != null
                                    ? ((setting.max - setting.min) /
                                              setting.step!)
                                          .round()
                                    : null,
                                thumbColor: appStyle.colors.accent,
                                activeColor: appStyle.colors.secondary,
                                inactiveColor: appStyle.colors.a15p,
                                onChanged: (v) async {
                                  var next = setting.step != null
                                      ? (v / setting.step!).round() *
                                            setting.step!
                                      : v;
                                  next = double.parse(
                                    setting.precision == 0
                                        ? next.toString().split(".")[0]
                                        : next.toStringAsPrecision(
                                                setting.precision,
                                              ) ==
                                              "0.0"
                                        ? "0"
                                        : next.toStringAsPrecision(
                                            setting.precision,
                                          ),
                                  );

                                  setState(() {
                                    currentValue = next;
                                  });

                                  await data.settings.set(setting, next);
                                  setStateOuter(() {});
                                },
                              ),
                            ),
                            Text(
                              setting.precision == 0
                                  ? currentValue.toString().split(".")[0]
                                  : currentValue.toStringAsPrecision(
                                          setting.precision,
                                        ) ==
                                        "0.0"
                                  ? "0"
                                  : currentValue.toStringAsPrecision(
                                      setting.precision,
                                    ),
                              style: appStyle.fonts.B_16R.apply(
                                color: appStyle.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showSettingsSheet(
  BuildContext context,
  double height,
  AppInitialization data,
  List<SettingsUiNode> items,
) {
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(maxHeight: height),
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SettingsScreen(data, items),
            ),
          ),
        ],
      );
    },
  );
}
