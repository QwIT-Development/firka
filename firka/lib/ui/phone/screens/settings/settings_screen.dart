import 'dart:collection';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/db/models/token_model.dart';
import 'package:firka/helpers/image_preloader.dart';
import 'package:firka/helpers/ui/firka_button.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/screens/login/login_screen.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../helpers/firka_bundle.dart';
import '../../../../helpers/firka_state.dart';
import '../../../../helpers/settings.dart';
import '../../widgets/login_webview.dart';

class SettingsScreen extends StatefulWidget {
  final AppInitialization data;
  final LinkedHashMap<String, SettingsItem> items;

  const SettingsScreen(this.data, this.items, {super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends FirkaState<SettingsScreen> {
  _SettingsScreenState();

  bool settingAppIcon = false;
  late String activeIcon;

  @override
  void initState() {
    super.initState();

    activeIcon = widget.data.settings
        .group("settings")
        .subGroup("customization")
        .subGroup("icon_picker")
        .iconString("icon_picker");
  }

  List<Widget> createWidgetTree(
      Iterable<SettingsItem> items, SettingsStore settings,
      {bool forceRender = false}) {
    var widgets = List<Widget>.empty(growable: true);

    for (var item in items) {
      if (!forceRender && !item.visibilityProvider()) continue;
      if (item is SettingsGroup) {
        widgets.addAll(createWidgetTree(item.children.values, settings));

        continue;
      }
      if (item is SettingsPadding) {
        widgets.add(SizedBox(
          width: item.padding,
          height: item.padding,
        ));

        continue;
      }
      if (item is SettingsBackHeader) {
        widgets.add(Column(
          children: [
            Row(
              children: [
                Transform.translate(
                  offset: const Offset(-4, 0),
                  child: GestureDetector(
                    child: FirkaIconWidget(
                        FirkaIconType.majesticons, Majesticon.chevronLeftLine,
                        color: appStyle.colors.textSecondary),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-4, 1),
                  child: Text(
                    item.title,
                    style: appStyle.fonts.B_16R
                        .apply(color: appStyle.colors.textPrimary),
                  ),
                )
              ],
            ),
            SizedBox(height: 13),
          ],
        ));

        continue;
      }
      if (item is SettingsHeader) {
        widgets.add(Text(
          item.title,
          style: appStyle.fonts.H_H1.apply(color: appStyle.colors.textPrimary),
        ));

        continue;
      }
      if (item is SettingsMediumHeader) {
        widgets.add(Text(
          item.title,
          style: appStyle.fonts.H_H2.apply(color: appStyle.colors.textPrimary),
        ));

        continue;
      }
      if (item is SettingsHeaderSmall) {
        widgets.add(Text(
          item.title,
          style:
              appStyle.fonts.H_14px.apply(color: appStyle.colors.textPrimary),
        ));

        continue;
      }
      if (item is SettingsSubGroup) {
        List<Widget> cardWidgets = [];

        if (item.iconType != null && item.iconData != null) {
          cardWidgets.add(FirkaIconWidget(
            item.iconType!,
            item.iconData!,
            color: appStyle.colors.accent,
          ));
          cardWidgets.add(SizedBox(width: 8));
        }

        cardWidgets.add(Text(item.title,
            style: appStyle.fonts.B_16SB
                .apply(color: appStyle.colors.textPrimary)));

        widgets.add(GestureDetector(
          onTap: () {
            if (item.redirectTo != null && item.redirectTo == "discord"){
              launchUrlString("https://discord.com/invite/firka-1111649116020285532");
              return; 
            } else if (item.redirectTo != null && item.redirectTo == "privacy"){
              launchUrlString("https://firka.app/privacy");
              return; 
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DefaultAssetBundle(
                          bundle: FirkaBundle(),
                          child: SettingsScreen(widget.data, item.children))));
            }
          },
    child: item.redirectTo != null
        ? FirkaCard(left: cardWidgets, right: [RotationTransition(turns: AlwaysStoppedAnimation(-45/360), child: FirkaIconWidget(FirkaIconType.majesticons, Majesticon.arrowRightSolid, size: 24, color: appStyle.colors.textSecondary))],)
        : FirkaCard(left: cardWidgets),
            
        ));

        continue;
      }

      if (item is SettingsDouble) {
        var v = item.toRoundedString();

        widgets.add(GestureDetector(
          child: FirkaCard(left: [
            item.iconType != null
                ? Row(
                    children: [
                      FirkaIconWidget(item.iconType!, item.iconData!,
                          color: appStyle.colors.accent),
                      SizedBox(width: 4),
                    ],
                  )
                : SizedBox(),
            Text(item.title,
                style: appStyle.fonts.B_16SB
                    .apply(color: appStyle.colors.textPrimary))
          ], right: [
            Text(v == "0.0" ? "0" : v,
                style: appStyle.fonts.B_16R
                    .apply(color: appStyle.colors.textPrimary))
          ]),
          onTap: () async {
            showSetDoubleSheet(context, item, widget.data, setState);
          },
        ));

        continue;
      }
      if (item is SettingsBoolean) {
        widgets.add(FirkaCard(
          left: [
            item.iconType != null
                ? Row(
                    children: [
                      FirkaIconWidget(item.iconType!, item.iconData!,
                          color: appStyle.colors.accent),
                      SizedBox(width: 4),
                    ],
                  )
                : SizedBox(),
            Text(item.title,
                style: appStyle.fonts.B_16SB
                    .apply(color: appStyle.colors.textPrimary))
          ],
          right: [
            Switch(
                value: item.value,
                // activeColor: appStyle.colors.accent,
                thumbColor: WidgetStateProperty.fromMap({
                  WidgetState.selected: appStyle.colors.buttonSecondaryFill,
                  WidgetState.any: appStyle.colors.accent
                }),
                trackColor: WidgetStateProperty.fromMap({
                  WidgetState.selected: appStyle.colors.accent,
                  WidgetState.any: appStyle.colors.a10p
                }),
                trackOutlineColor: WidgetStateProperty.fromMap({
                  WidgetState.selected: appStyle.colors.accent,
                  WidgetState.any: appStyle.colors.a15p
                }),
                onChanged: (v) async {
                  setState(() {
                    item.value = v;
                  });

                  await widget.data.isar.writeTxn(() async {
                    await item.save(widget.data.isar.appSettingsModels);
                  });

                  await item.postUpdate();
                })
          ],
        ));

        continue;
      }
      if (item is SettingsItemsRadio) {
        for (var i = 0; i < item.values.length; i++) {
          var k = item.values[i];

          if (item.values[item.activeIndex] == k) {
            widgets.add(FirkaCard(height: 52 + 12, left: [
              Text(k,
                  style: appStyle.fonts.B_16R
                      .apply(color: appStyle.colors.textPrimary))
            ], right: [
              SizedBox(
                width: 16,
                height: 16,
                child: Checkbox(
                    value: true,
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      return appStyle.colors.secondary;
                    }),
                    onChanged: (_) async {
                      setState(() {
                        item.activeIndex = i;
                      });

                      await widget.data.isar.writeTxn(() async {
                        await item.save(widget.data.isar.appSettingsModels);
                      });

                      await item.postUpdate();
                      logger.finest('Settings saved');
                    }),
              ),
              SizedBox(width: 8),
            ]));
          } else {
            widgets.add(GestureDetector(
              child: FirkaCard(height: 52 + 12, left: [
                Text(k,
                    style: appStyle.fonts.B_16R
                        .apply(color: appStyle.colors.textPrimary))
              ], right: [
                SizedBox(height: 16 + 8),
              ]),
              onTap: () async {
                setState(() {
                  item.activeIndex = i;
                });

                await widget.data.isar.writeTxn(() async {
                  await item.save(widget.data.isar.appSettingsModels);
                });

                await item.postUpdate();
              },
            ));
          }
        }

        continue;
      }

      if (item is SettingsAppIconPreview) {
        widgets.add(Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: PreloadedImageProvider(
                    FirkaBundle(), ('assets/images/background.webp')),
                fit: BoxFit.cover),
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
                      borderRadius:
                          const BorderRadius.all(Radius.circular(16.0)),
                      child: Image(
                        image: PreloadedImageProvider(FirkaBundle(),
                            "assets/images/icons/$activeIcon.webp"),
                        width: 74,
                        height: 74,
                      ),
                    ),
                    Text(
                      settings.appIcons[activeIcon]!,
                      style: appStyle.fonts.H_12px
                          .apply(color: appStyle.colors.card),
                    )
                  ],
                )
              ],
            ),
          ),
        ));

        continue;
      }
      if (item is SettingsAppIconPicker) {
        List<Widget> pWidgets = [];

        for (var group in item.iconGroups.keys) {
          if (widget.data.settings
              .group("settings")
              .subGroup("customization")
              .subGroup("icon_picker")
              .boolean("child_protection")) {
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

            groupIcons.add(Column(
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
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12.0)),
                              child: Image(
                                image: PreloadedImageProvider(FirkaBundle(),
                                    "assets/images/icons/$icon.webp"),
                                width: 48,
                                height: 48,
                              ),
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16.0)),
                          child: Image(
                            image: PreloadedImageProvider(FirkaBundle(),
                                "assets/images/icons/$icon.webp"),
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
                  settings.appIcons[icon]!,
                  style: appStyle.fonts.B_12R.apply(
                      color: active
                          ? appStyle.colors.textPrimary
                          : appStyle.colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ));
          }

          pWidgets.add(Text(
            group,
            style:
                appStyle.fonts.H_14px.apply(color: appStyle.colors.textPrimary),
          ));

          if (group == widget.data.l10n.s_ci_icon_g6) {
            pWidgets.add(Text(widget.data.l10n.s_ci_icon_g6_desc,
                style: appStyle.fonts.B_16R
                    .apply(color: appStyle.colors.textSecondary)));
          }

          if (group == widget.data.l10n.s_ci_icon_g7 ||
              group == widget.data.l10n.s_ci_icon_g8) {
            var settingsWidgets = createWidgetTree([
              widget.data.settings
                      .group("settings")
                      .subGroup("customization")
                      .subGroup("icon_picker")["child_protection"]
                  as SettingsBoolean
            ], settings, forceRender: true);

            pWidgets.add(SizedBox(height: 12));
            for (var w in settingsWidgets) {
              pWidgets.add(w);
            }
          }

          pWidgets.add(SizedBox(height: 12));
          pWidgets.add(SizedBox(
            height: (groupIcons.length / 4).ceil() * 100,
            child: GridView.count(
              crossAxisCount: 4,
              physics: NeverScrollableScrollPhysics(),
              children: groupIcons,
            ),
          ));
        }

        widgets.add(SizedBox(
          height: MediaQuery.of(context).size.height / 1.7,
          child: SingleChildScrollView(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pWidgets,
          )),
        ));

        widgets.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              child: FirkaButton(
                  text: widget.data.l10n.cancel,
                  bgColor: appStyle.colors.buttonSecondaryFill,
                  fontStyle: appStyle.fonts.B_16R
                      .apply(color: appStyle.colors.textSecondary)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            GestureDetector(
              child: FirkaButton(
                  text: widget.data.l10n.save,
                  bgColor: appStyle.colors.accent,
                  fontStyle: appStyle.fonts.B_16R
                      .apply(color: appStyle.colors.textSecondaryLight)),
              onTap: () async {
                if (settingAppIcon) return;
                settingAppIcon = true;

                widget.data.settings
                    .group("settings")
                    .subGroup("customization")
                    .subGroup("icon_picker")
                    .setIconString("icon_picker", activeIcon);

                await widget.data.isar.writeTxn(() async {
                  await widget.data.settings
                      .save(widget.data.isar.appSettingsModels);
                });

                await Future.delayed(Duration(seconds: 1));

                const channel = MethodChannel('firka.app/main');
                await channel.invokeMethod('set_icon', {
                  "icon": activeIcon == "original" ? null : activeIcon,
                  "icons": settings.appIcons.keys
                      .where((e) => e != "original")
                      .join(",")
                });
              },
            )
          ],
        ));

        continue;
      }
      if (item is SettingsKretenAccountPicker) {
        for (var i = 0; i < widget.data.tokens.length; i++) {
          final token = widget.data.tokens[i];
          final jwt = JWT.decode(token.idToken!);
          String studentRole;
          if (jwt.payload["role"] == "Tanulo") {
            studentRole = "Tanuló";
          } else {
            studentRole = jwt.payload["role"];
          }
          widgets.add(GestureDetector(
            child: SizedBox(
              height: 52,
              child: FirkaCard(
                left: [
                  Text(
                    jwt.payload["name"],
                    style: appStyle.fonts.B_16R
                        .apply(color: appStyle.colors.textPrimary),
                  ),
                  SizedBox(width: 8),
                  Text(
                    studentRole,
                    style: appStyle.fonts.B_16R
                        .apply(color: appStyle.colors.textTertiary),
                  )
                ],
                right: [
                  i != item.accountIndex
                      ? SizedBox()
                      : Checkbox(
                          value: true,
                          fillColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                            return appStyle.colors.secondary;
                          }),
                          onChanged: (_) async {
                            setState(() {
                              // item.activeIndex = i;
                            });

                            await widget.data.isar.writeTxn(() async {
                              await item
                                  .save(widget.data.isar.appSettingsModels);
                            });

                            await item.postUpdate();
                            logger.finest('Settings saved');
                          })
                ],
              ),
            ),
            onTap: () async {
              if (i != item.accountIndex) {
                await widget.data.isar.writeTxn(() async {
                  item.accountIndex = i;

                  await item.save(widget.data.isar.appSettingsModels);
                });

                await item.postUpdate();

                runApp(InitializationScreen());
              }
            },
          ));
          widgets.add(SizedBox(height: 8));
        }

        widgets.add(GestureDetector(
          child: FirkaCard(left: [
            Text(
              widget.data.l10n.s_acc_add,
              style: appStyle.fonts.B_16R
                  .apply(color: appStyle.colors.textPrimary),
            )
          ]),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return LoginWebviewWidget(widget.data);
              },
            );
          },
        ));
        widgets.add(SizedBox(height: 20));
        widgets.add(GestureDetector(
          child: FirkaCard(left: [
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
                  style: appStyle.fonts.B_16R
                      .apply(color: appStyle.colors.textPrimary),
                ),
              ],
            )
          ]),
          onTap: () async {
            final active = widget.data.client.model.studentIdNorm!;

            await widget.data.isar.writeTxn(() async {
              await widget.data.isar.tokenModels.delete(active);

              item.accountIndex = 0;
              await item.save(widget.data.isar.appSettingsModels);
            });

            final accounts =
                await widget.data.isar.tokenModels.where().findAll();

            if (accounts.isEmpty) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => LoginScreen(widget.data)),
                (route) => false,
              );
            } else {
              widget.data.tokens = accounts;
              runApp(InitializationScreen());
            }
          },
        ));
        continue;
      }
      if (item is SettingsLogs) {
        final logFileRegex = RegExp(r'^(\d{4})_(\d{2})_(\d{2})\.log$');

        for (final entity in widget.data.appDir.listSync()) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last;
          final m = logFileRegex.firstMatch(name);
          if (m == null) continue;

          widgets.add(GestureDetector(
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
                    style: appStyle.fonts.B_16R
                        .apply(color: appStyle.colors.textPrimary),
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
                final tempDir = await Directory.systemTemp.createTemp('firka');
                final gzPath =
                    p.join(tempDir.path, '${p.basename(entity.path)}.gz');
                final gzFile =
                    await File(gzPath).writeAsBytes(gzBytes, flush: true);

                final params = ShareParams(
                  text: name,
                  files: [XFile(gzFile.path, mimeType: 'application/gzip')],
                );

                await SharePlus.instance.share(params);

                await gzFile.delete();
                await tempDir.delete();
              } catch (ex) {
                if (ex is Error) {
                  logger.shout("Failed to compress log file", ex.toString(),
                      ex.stackTrace);
                } else {
                  logger.shout("Failed to compress log file", ex.toString());
                }

                logger.info("Sharing regular log file instead: ${entity.path}");
                final params = ShareParams(
                  text: name,
                  files: [XFile(entity.path, mimeType: 'text/plain')],
                );

                await SharePlus.instance.share(params);
              }
            },
          ));
          widgets.add(SizedBox(height: 8));
        }
        continue;
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    var body = createWidgetTree(widget.items.values, widget.data.settings);

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
                            children: body)),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}

void showSetDoubleSheet(BuildContext context, SettingsDouble setting,
    AppInitialization data, void Function(VoidCallback fn) setStateOuter) {
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
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 18.0, right: 16.0, bottom: 30.0, top: 20.0),
                        child: Column(
                          children: [
                            Center(
                                child: Text(
                              setting.title,
                              style: appStyle.fonts.B_16R
                                  .apply(color: appStyle.colors.textPrimary),
                            )),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 40),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    // TODO: Make a firka slider
                                    child: Slider(
                                        min: setting.minValue,
                                        value: setting.value,
                                        max: setting.maxValue,
                                        thumbColor: appStyle.colors.accent,
                                        activeColor: appStyle.colors.secondary,
                                        inactiveColor: appStyle.colors.a15p,
                                        onChanged: (v) async {
                                          setState(() {
                                            setting.value = v;
                                            setting.value =
                                                setting.toRoundedDouble();
                                          });

                                          await data.isar.writeTxn(() async {
                                            await setting.save(
                                                data.isar.appSettingsModels);

                                            setStateOuter(() {});
                                          });
                                          await setting.postUpdate();
                                        }),
                                  ),
                                  Text(setting.toRoundedString(),
                                      style: appStyle.fonts.B_16R.apply(
                                          color: appStyle.colors.textPrimary))
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ));
    },
  );
}

void showSettingsSheet(BuildContext context, double height,
    AppInitialization data, LinkedHashMap<String, SettingsItem> items) {
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(
      maxHeight: height,
    ),
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
