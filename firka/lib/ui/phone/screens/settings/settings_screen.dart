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
  State<SettingsScreen> createState() => _SettingsScreenState(data, items);
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppInitialization data;
  final LinkedHashMap<String, SettingsItem> items;

  _SettingsScreenState(this.data, this.items);

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
                    builder: (context) => SettingsScreen(data, item.children)));
          },
          child: FirkaCard(left: cardWidgets),
        ));
      }

      if (item is SettingsDouble) {
        var v = item.value.toStringAsPrecision(2);

        widgets.add(FirkaCard(left: [
          Text(item.title,
              style: appStyle.fonts.B_16SB
                  .apply(color: appStyle.colors.textPrimary))
        ], right: [
          Text(v == "0.0" ? "0" : v,
              style: appStyle.fonts.B_14R
                  .apply(color: appStyle.colors.textPrimary))
        ]));
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
                activeColor: appStyle.colors.accent,
                onChanged: (v) {
                  setState(() {
                    item.value = v;
                  });

                  data.isar.writeTxn(() async {
                    item.save(data.isar.appSettingsModels);
                  });
                })
          ],
        ));
      }
      if (item is SettingsItemsRadio) {
        for (var i = 0; i < item.values.length; i++) {
          var k = item.values[i];

          widgets.add(FirkaCard(left: [
            Text(k,
                style: appStyle.fonts.B_16R
                    .apply(color: appStyle.colors.textPrimary))
          ], right: [
            Checkbox(
                value: item.values[item.activeIndex] == k,
                fillColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                  return appStyle.colors.secondary;
                }),
                onChanged: (_) {
                  setState(() {
                    item.activeIndex = i;
                  });

                  data.isar.writeTxn(() async {
                    item.save(data.isar.appSettingsModels);
                  });
                })
          ]));
        }
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    _updateSystemUI(); // Update system UI on every build, to compensate for the android system being dumb

    var body = createWidgetTree(items.values);

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
