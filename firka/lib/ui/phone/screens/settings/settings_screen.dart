import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:firka/core/image_preloader.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/core/settings/setting.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/core/settings/settings_ui.dart';
import 'package:firka/ui/components/firka_button.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/services/live_activity_service.dart';
import 'package:firka/services/watch_sync_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../widgets/login_webview.dart';

class SettingsScreen extends StatefulWidget {
  final AppInitialization data;
  final List<SettingsUiNode> items;

  const SettingsScreen(this.data, this.items, {super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends FirkaState<SettingsScreen> {
  _SettingsScreenState();

  bool settingAppIcon = false;
  late String activeIcon;
  late List<TokenModel> tokens;

  @override
  void initState() {
    super.initState();

    activeIcon = Settings.appIcon.value;
    tokens = isarInit.tokenModels.where().sortByUpdatedAtMsDesc().findAllSync();
  }

  String _roundedDoubleString(double value, DoubleSetting setting) {
    return setting.precision == 0
        ? value.toString().split(".")[0]
        : value.toStringAsPrecision(setting.precision) == "0.0"
        ? "0"
        : value.toStringAsPrecision(setting.precision);
  }

  Widget _boolRow(SettingsUiBoolean item, SettingsRepository settings) {
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
                    package:
                        item.iconType == FirkaIconType.icons ||
                            item.iconType == FirkaIconType.majesticonsLocal
                        ? 'firka'
                        : null,
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
            setState(() {});
          },
        ),
      ],
    );
  }

  List<Widget> createWidgetTree(
    Iterable<SettingsUiNode> items,
    SettingsRepository settings, {
    bool forceRender = false,
  }) {
    var widgets = List<Widget>.empty(growable: true);

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
            children: [
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-4, 0),
                    child: GestureDetector(
                      child: FirkaIconWidget(
                        FirkaIconType.majesticons,
                        Majesticon.chevronLeftLine,
                        color: appStyle.colors.textSecondary,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-4, 1),
                    child: Text(
                      item.title,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 13),
            ],
          ),
        );

        continue;
      }
      if (item is SettingsUiHeader) {
        widgets.add(
          Text(
            item.title,
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
            item.title,
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
              package:
                  item.iconType == FirkaIconType.icons ||
                      item.iconType == FirkaIconType.majesticonsLocal
                  ? 'firka'
                  : null,
            ),
          );
          cardWidgets.add(SizedBox(width: 8));
        }

        cardWidgets.add(
          Text(
            item.title,
            style: appStyle.fonts.B_16SB.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        );

        widgets.add(
          GestureDetector(
            onTap: () {
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
                : FirkaCard(left: cardWidgets),
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
              height: 52 + 12,
              left: [
                item.iconType != null
                    ? Row(
                        children: [
                          FirkaIconWidget(
                            item.iconType!,
                            item.iconData!,
                            color: appStyle.colors.accent,
                            package:
                                item.iconType == FirkaIconType.icons ||
                                    item.iconType ==
                                        FirkaIconType.majesticonsLocal
                                ? 'firka'
                                : null,
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
        widgets.add(_boolRow(item, settings));

        continue;
      }
      if (item is SettingsUiEnum) {
        final activeIndex = settings.get(item.setting).index;
        for (var i = 0; i < item.optionLabels.length; i++) {
          var k = item.optionLabels[i];

          if (i == activeIndex) {
            widgets.add(
              FirkaCard(
                height: 52 + 12,
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
                  height: 52 + 12,
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
        widgets.add(
          FutureBuilder<List<LicenseEntry>>(
            future: LicenseRegistry.licenses.toList(),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<LicenseEntry>> snapshot,
                ) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: appStyle.colors.accent,
                      ),
                    );
                  }

                  final licenses = snapshot.data!;
                  final shownPackages = <String>{};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: licenses
                        .where(
                          (license) => license.packages.any(
                            (pkg) => !shownPackages.contains(pkg),
                          ),
                        )
                        .map((license) {
                          final packageName = license.packages.firstWhere(
                            (pkg) => !shownPackages.contains(pkg),
                            orElse: () => license.packages.first,
                          );
                          shownPackages.add(packageName);
                          final paragraphs = license.paragraphs
                              .map((p) => p.text)
                              .join('\n\n');

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: appStyle.colors.card,
                                          title: Text(
                                            packageName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Text(
                                              paragraphs,
                                              style: appStyle.fonts.B_15SB
                                                  .apply(
                                                    color: appStyle
                                                        .colors
                                                        .textPrimary,
                                                  ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text(
                                                widget.data.l10n.close,
                                                style: appStyle.fonts.B_14R
                                                    .apply(
                                                      color: appStyle
                                                          .colors
                                                          .textSecondary,
                                                    ),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: FirkaCard(
                                    left: [
                                      Text(
                                        packageName,
                                        style: appStyle.fonts.B_14R.apply(
                                          color: appStyle.colors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  );
                },
          ),
        );
        continue;
      }

      if (item is SettingsUiAppIconPreview) {
        widgets.add(
          Container(
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
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16.0),
                        ),
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
                        appIconLabels(widget.data.l10n)[activeIcon]!,
                        style: appStyle.fonts.H_12px.apply(
                          color: appStyle.colors.card,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        continue;
      }
      if (item is SettingsUiAppIconPicker) {
        List<Widget> pWidgets = [];

        for (var group in item.iconGroups.keys) {
          if (Settings.childProtection.value) {
            if (group == widget.data.l10n.s_ci_icon_g7) {
              continue;
            }
          } else {
            if (group == widget.data.l10n.s_ci_icon_g8) {
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
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
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
                      if (settingAppIcon) return;

                      setState(() {
                        activeIcon = icon;
                      });
                    },
                  ),
                  Text(
                    appIconLabels(widget.data.l10n)[icon]!,
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

          if (group == widget.data.l10n.s_ci_icon_g6) {
            pWidgets.add(
              Text(
                widget.data.l10n.s_ci_icon_g6_desc,
                style: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textSecondary,
                ),
              ),
            );
          }

          if (group == widget.data.l10n.s_ci_icon_g7 ||
              group == widget.data.l10n.s_ci_icon_g8) {
            pWidgets.add(SizedBox(height: 12));
            pWidgets.add(_boolRow(item.childProtection, settings));
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

        widgets.add(
          SizedBox(
            height: MediaQuery.of(context).size.height / 1.7,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pWidgets,
              ),
            ),
          ),
        );

        widgets.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                child: FirkaButton(
                  text: widget.data.l10n.cancel,
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
                  text: widget.data.l10n.save,
                  bgColor: appStyle.colors.accent,
                  fontStyle: appStyle.fonts.B_16R.apply(
                    color: appStyle.colors.textSecondaryLight,
                  ),
                ),
                onTap: () async {
                  if (settingAppIcon) return;
                  settingAppIcon = true;

                  await Settings.appIcon.set(activeIcon);

                  await Future.delayed(Duration(seconds: 1));

                  logger.info(
                    appIconLabels(
                      widget.data.l10n,
                    ).keys.where((e) => e != "original").join(","),
                  );

                  logger.info(activeIcon);

                  const channel = MethodChannel('firka.app/main');
                  logger.info(
                    await channel.invokeMethod('set_icon', {
                      "icon": activeIcon == "original" ? null : activeIcon,
                      "icons": appIconLabels(
                        widget.data.l10n,
                      ).keys.where((e) => e != "original").join(","),
                    }),
                  );
                },
              ),
            ],
          ),
        );

        continue;
      }
      if (item is SettingsUiKretaAccountPicker) {
        for (TokenModel token in tokens) {
          final jwt = JWT.decode(token.idToken!);
          final payload = jwt.payload as Map<String, dynamic>;
          String studentRole = payload["role"];
          if (studentRole == "Tanulo") {
            studentRole = "Tanuló";
          } else if (studentRole == "Gondviselo") {
            studentRole = "Gondviselő";
          }
          widgets.add(
            GestureDetector(
              child: SizedBox(
                height: 52,
                child: FirkaCard(
                  left: [
                    Text(
                      payload["name"],
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      studentRole,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textTertiary,
                      ),
                    ),
                  ],
                  right: [
                    token.key != widget.data.settings.selectedAccountKey
                        ? SizedBox()
                        : Checkbox(
                            value: true,
                            fillColor: WidgetStateProperty.resolveWith<Color>((
                              Set<WidgetState> states,
                            ) {
                              return appStyle.colors.secondary;
                            }),
                            onChanged: (_) async {
                              setState(() {});
                              logger.finest('Settings saved');
                            },
                          ),
                  ],
                ),
              ),
              onTap: () async {
                if (token.key == widget.data.settings.selectedAccountKey) {
                  return;
                }

                final previousAccountId = widget.data.client!.cache.token.key;
                if (Platform.isIOS) {
                  await LiveActivityService.onUserLogout();
                  try {
                    await WatchSyncHelper.clearSharedLanguageState();
                  } catch (e) {
                    logger.warning(
                      '[Settings] Failed to clear shared language state on account switch: $e',
                    );
                  }
                  if (previousAccountId != null) {
                    try {
                      await WatchSyncHelper.clearRefreshLeaseForAccount(
                        previousAccountId,
                      );
                    } catch (e) {
                      logger.warning(
                        '[Settings] Failed to clear refresh lease on account switch: $e',
                      );
                    }
                  }
                }

                await widget.data.settings.setSelectedAccountKey(token.key);
                await initializeApp();

                if (Platform.isIOS) {
                  var watchReachable = false;
                  try {
                    watchReachable = await WatchSyncHelper.isWatchReachable(
                      forceRefreshInstall: true,
                    );
                  } catch (e) {
                    logger.warning(
                      '[Settings] Failed to query Watch reachability on account switch: $e',
                    );
                  }

                  if (watchReachable) {
                    try {
                      await WatchSyncHelper.sendTokenModelToWatch(
                        token,
                        allowExpiredAccessToken: true,
                      );
                    } catch (e) {
                      logger.warning(
                        '[Settings] Failed to send switched account token to reachable Watch: $e',
                      );
                    }
                  } else {
                    try {
                      await WatchSyncHelper.saveTokenToiCloud(
                        token,
                        forceAccountSwitch: true,
                      );
                    } catch (e) {
                      logger.warning(
                        '[Settings] Failed to sync switched account token to iCloud: $e',
                      );
                    }
                  }
                }

                if (!mounted) return;
                final nav = Navigator.of(context);
                if (nav.canPop()) nav.pop();
                appRouter?.go('/home');
              },
            ),
          );
          widgets.add(SizedBox(height: 8));
        }

        widgets.add(
          GestureDetector(
            child: FirkaCard(
              left: [
                Text(
                  widget.data.l10n.s_acc_add,
                  style: appStyle.fonts.B_16R.apply(
                    color: appStyle.colors.textPrimary,
                  ),
                ),
              ],
            ),
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                enableDrag: false,
                builder: (BuildContext context) {
                  return LoginWebviewWidget(widget.data);
                },
              );
            },
          ),
        );
        widgets.add(SizedBox(height: 20));
        widgets.add(
          GestureDetector(
            child: FirkaCard(
              left: [
                Row(
                  children: [
                    FirkaIconWidget(
                      FirkaIconType.icons,
                      "group",
                      color: appStyle.colors.accent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      widget.data.l10n.s_acc_logout,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () async {
              try {
                if (Platform.isIOS) {
                  await LiveActivityService.onUserLogout();
                }

                final active = widget.data.client!.cache.token.key;
                if (Platform.isIOS) {
                  try {
                    await WatchSyncHelper.clearRefreshLeaseForAccount(active);
                  } catch (e) {
                    logger.warning(
                      '[Settings] Failed to clear refresh lease for active account: $e',
                    );
                  }
                  try {
                    await WatchSyncHelper.clearSharedLanguageState();
                  } catch (e) {
                    logger.warning(
                      '[Settings] Failed to clear shared language state on logout: $e',
                    );
                  }
                }

                await widget.data.isar.writeTxn(() async {
                  await widget.data.isar.tokenModels.delete(active);
                });
                await widget.data.settings.setSelectedAccountKey(0);

                final accounts = await widget.data.isar.tokenModels
                    .where()
                    .findAll();

                if (accounts.isEmpty) {
                  if (Platform.isIOS) {
                    try {
                      await WatchSyncHelper.clearICloudToken(notifyWatch: true);
                      await WatchSyncHelper.clearAllRefreshLeases();
                    } catch (e) {
                      logger.warning(
                        '[Settings] Failed to clear iCloud token: $e',
                      );
                    }
                  }
                } else {
                  if (Platform.isIOS) {
                    final nextToken = accounts.first;
                    var watchReachable = false;
                    try {
                      watchReachable = await WatchSyncHelper.isWatchReachable(
                        forceRefreshInstall: true,
                      );
                    } catch (e) {
                      logger.warning(
                        '[Settings] Failed to query Watch reachability after logout: $e',
                      );
                    }

                    if (watchReachable) {
                      try {
                        await WatchSyncHelper.sendTokenModelToWatch(
                          nextToken,
                          allowExpiredAccessToken: true,
                        );
                      } catch (e) {
                        logger.warning(
                          '[Settings] Failed to send next account token to reachable Watch after logout: $e',
                        );
                      }
                    } else {
                      try {
                        await WatchSyncHelper.saveTokenToiCloud(
                          nextToken,
                          forceAccountSwitch: true,
                        );
                      } catch (e) {
                        logger.warning(
                          '[Settings] Failed to sync next account token to iCloud after logout: $e',
                        );
                      }
                    }
                  }
                }

                await initializeApp();

                if (!mounted) return;
                final nav = Navigator.of(context);
                if (nav.canPop()) nav.pop();
                if (accounts.isEmpty) {
                  appRouter?.go('/login');
                } else {
                  appRouter?.go('/home');
                }
              } catch (e, st) {
                logger.shout('[Settings] Logout failed: $e', e, st);
                if (mounted) {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) nav.pop();
                }
                appRouter?.go('/login');
              }
            },
          ),
        );
        continue;
      }
      if (item is SettingsUiButton) {
        widgets.add(
          GestureDetector(
            child: FirkaCard(
              left: [
                item.iconType != null
                    ? Row(
                        children: [
                          FirkaIconWidget(
                            item.iconType!,
                            item.iconData!,
                            color: appStyle.colors.accent,
                            package:
                                item.iconType == FirkaIconType.icons ||
                                    item.iconType ==
                                        FirkaIconType.majesticonsLocal
                                ? 'firka'
                                : null,
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
        final logFileRegex = RegExp(r'^(\d{4})_(\d{2})_(\d{2})\.log$');

        for (final entity in widget.data.appDir.listSync()) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last;
          final m = logFileRegex.firstMatch(name);
          if (m == null) continue;

          widgets.add(
            GestureDetector(
              child: SizedBox(
                height: 52,
                child: FirkaCard(
                  left: [
                    FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.noteTextSolid,
                      color: appStyle.colors.accent,
                    ),
                    Text(
                      name,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () async {
                try {
                  logger.info("Compressing log file: ${entity.path}");
                  final original = File(entity.path);
                  final originalBytes = await original.readAsBytes();
                  final gzBytes = GZipCodec().encode(originalBytes);
                  final tempDir = await Directory.systemTemp.createTemp(
                    'firka',
                  );
                  final gzPath = p.join(
                    tempDir.path,
                    '${p.basename(entity.path)}.gz',
                  );
                  final gzFile = await File(
                    gzPath,
                  ).writeAsBytes(gzBytes, flush: true);

                  final params = ShareParams(
                    text: name,
                    files: [XFile(gzFile.path, mimeType: 'application/gzip')],
                  );

                  await SharePlus.instance.share(params);

                  await gzFile.delete();
                  await tempDir.delete();
                } catch (ex) {
                  if (ex is Error) {
                    logger.shout(
                      "Failed to compress log file",
                      ex.toString(),
                      ex.stackTrace,
                    );
                  } else {
                    logger.shout("Failed to compress log file", ex.toString());
                  }

                  logger.info(
                    "Sharing regular log file instead: ${entity.path}",
                  );
                  final params = ShareParams(
                    text: name,
                    files: [XFile(entity.path, mimeType: 'text/plain')],
                  );

                  await SharePlus.instance.share(params);
                }
              },
            ),
          );
          widgets.add(SizedBox(height: 8));
        }
        continue;
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    var body = createWidgetTree(widget.items, widget.data.settings);

    return DefaultAssetBundle(
      bundle: FirkaBundle(),
      child: Scaffold(
        backgroundColor: appStyle.colors.background,
        body: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: body,
                    ),
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
