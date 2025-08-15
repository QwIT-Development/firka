import 'dart:collection';

import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../helpers/settings/setting.dart';

class SettingsScreen extends StatefulWidget {
  final AppInitialization data;
  final LinkedHashMap<String, SettingsItem> items;

  const SettingsScreen(this.data, this.items, {super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsScreenState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: appStyle.colors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  List<Widget> createWidgetTree(Iterable<SettingsItem> items) {
    var widgets = List<Widget>.empty(growable: true);

    for (var item in items) {
      if (item is SettingsGroup) {
        widgets.addAll(createWidgetTree(item.children.values));
      }
      if (item is SettingsPadding) {
        widgets.add(SizedBox(
          width: item.padding,
          height: item.padding,
        ));
      }
      if (item is SettingsHeader) {
        widgets.add(Text(
          item.title,
          style: appStyle.fonts.H_H1.apply(color: appStyle.colors.textPrimary),
        ));
      }
      if (item is SettingsHeaderSmall) {
        widgets.add(Text(
          item.title,
          style:
              appStyle.fonts.H_14px.apply(color: appStyle.colors.textPrimary),
        ));
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
            style: appStyle.fonts.B_14SB
                .apply(color: appStyle.colors.textPrimary)));

        widgets.add(GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        SettingsScreen(widget.data, item.children)));
          },
          child: FirkaCard(left: cardWidgets),
        ));
      }

      if (item is SettingsDouble) {
        var v = item.toRoundedString();

        widgets.add(GestureDetector(
          child: FirkaCard(left: [
            Text(item.title,
                style: appStyle.fonts.B_16SB
                    .apply(color: appStyle.colors.textPrimary))
          ], right: [
            Text(v == "0.0" ? "0" : v,
                style: appStyle.fonts.B_14R
                    .apply(color: appStyle.colors.textPrimary))
          ]),
          onTap: () async {
            showSetDoubleSheet(context, item, widget.data, setState);
          },
        ));
      }
      if (item is SettingsBoolean) {
        widgets.add(FirkaCard(
          left: [
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
                  WidgetState.any: Colors.transparent
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
                })
          ],
        ));
      }
      if (item is SettingsItemsRadio) {
        for (var i = 0; i < item.values.length; i++) {
          var k = item.values[i];

          if (item.values[item.activeIndex] == k) {
            widgets.add(FirkaCard(left: [
              Text(k,
                  style: appStyle.fonts.B_16R
                      .apply(color: appStyle.colors.textPrimary))
            ], right: [
              Checkbox(
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
                    debugPrint('Settings saved');
                  })
            ]));
          } else {
            widgets.add(GestureDetector(
              child: FirkaCard(left: [
                Text(k,
                    style: appStyle.fonts.B_16R
                        .apply(color: appStyle.colors.textPrimary))
              ], right: [
                SizedBox(height: 48),
              ]),
              onTap: () async {
                setState(() {
                  item.activeIndex = i;
                });

                await widget.data.isar.writeTxn(() async {
                  await item.save(widget.data.isar.appSettingsModels);
                });
              },
            ));
          }
        }
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    _updateSystemUI(); // Update system UI on every build, to compensate for the android system being dumb

    var body = createWidgetTree(widget.items.values);

    return Scaffold(
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
    );
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
                              style: appStyle.fonts.B_14R,
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
                                        }),
                                  ),
                                  Text(setting.toRoundedString(),
                                      style: appStyle.fonts.B_14R.apply(
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
