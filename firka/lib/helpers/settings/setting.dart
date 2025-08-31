import 'dart:collection';
import 'dart:core';
import 'dart:io';

import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../main.dart';
import '../../ui/phone/screens/home/home_screen.dart';
import '../firka_bundle.dart';
// import 'package:restart_app/restart_app.dart';

const bellRing = 1001;
const rounding1 = 1002;
const rounding2 = 1003;
const rounding3 = 1004;
const rounding4 = 1005;
const classAvgOnGraph = 1006;
const leftHandedMode = 1007;
const language = 1008;
const appIcon = 1009;
const childProtection = 1010;
const betaWarning = 1011;

const ttToastLessonNo = 1012;
const ttToastTestsAndHw = 1013;
const ttToastBreaks = 1014;

const statsForNerds = 1015;
const developerOptsEnabled = 1016;

bool always() {
  return true;
}

bool never() {
  return false;
}

bool isDeveloper() {
  return isDebug() ||
      initData.settings.group("settings").boolean("developer_enabled");
}

bool isAndroid() {
  return Platform.isAndroid;
}

bool isDebug() {
  return kDebugMode;
}

class SettingsStore {
  LinkedHashMap<String, SettingsItem> items = LinkedHashMap.of({});

  Map<String, String> appIcons = {};

  SettingsStore(AppLocalizations l10n) {
    items["settings"] = SettingsGroup(
        0,
        LinkedHashMap.of({
          "settings_header": SettingsHeader(0, l10n.s_settings, always),
          "settings_padding": SettingsPadding(0, 20, always),
          "application": SettingsSubGroup(
              0,
              FirkaIconType.majesticons,
              Majesticon.settingsCogSolid,
              l10n.s_a,
              LinkedHashMap.of({
                // TODO: Make a back arrow widget
                "settings_header": SettingsHeader(0, l10n.s_ag, always),
                "settings_padding": SettingsPadding(0, 23, always),

                "bell_delay": SettingsDouble(
                    bellRing,
                    FirkaIconType.majesticons,
                    Majesticon.bellSolid,
                    l10n.s_ag_bell_delay,
                    0,
                    0,
                    120,
                    0,
                    always),
                "rounding": SettingsSubGroup(
                    0,
                    FirkaIconType.majesticons,
                    Majesticon.ruler2Solid,
                    l10n.s_ag_rounding,
                    LinkedHashMap.of({
                      "1": SettingsDouble(rounding1, null, null, l10n.s_ag_r1,
                          0.1, 0.5, 0.99, 2, always),
                      "2": SettingsDouble(rounding2, null, null, l10n.s_ag_r2,
                          0.1, 0.5, 0.99, 2, always),
                      "3": SettingsDouble(rounding3, null, null, l10n.s_ag_r3,
                          0.1, 0.5, 0.99, 2, always),
                      "4": SettingsDouble(rounding4, null, null, l10n.s_ag_r4,
                          0.1, 0.5, 0.99, 2, always),
                    }),
                    always),
                "class_avg_on_graph": SettingsBoolean(classAvgOnGraph, null,
                    null, l10n.s_ag_class_avg_on_graph, true, never),
                "navbar": SettingsSubGroup(
                    0,
                    null, // TODO: icon
                    null,
                    l10n.s_ag_navbar,
                    LinkedHashMap.of({}),
                    never),
                "left_handed_mode": SettingsBoolean(leftHandedMode, null, null,
                    l10n.s_ag_left_handed_mode, false, never),
                "language_header":
                    SettingsHeaderSmall(0, l10n.s_ag_language_header, always),
                "language": SettingsItemsRadio(
                    language,
                    null,
                    null,
                    [
                      l10n.s_ag_language_auto,
                      l10n.s_ag_language_hu,
                      l10n.s_ag_language_en,
                      l10n.s_ag_language_de
                    ],
                    0,
                    always, () async {
                  Navigator.of(navigatorKey.currentContext!)
                      .popUntil((route) => false);

                  initLang(initData);
                  initData.settings = SettingsStore(initData.l10n);
                  await initData.settings.load(initData.isar.appSettingsModels);

                  Navigator.push(
                    navigatorKey.currentContext!,
                    MaterialPageRoute(
                        builder: (context) => DefaultAssetBundle(
                            bundle: FirkaBundle(),
                            child: HomeScreen(
                              initData,
                              false,
                              key: ValueKey('homeScreen'),
                            ))),
                  );
                })
              }),
              always),
          "customization": SettingsSubGroup(
              0,
              FirkaIconType.majesticons,
              Majesticon.flower2Solid,
              l10n.s_c,
              LinkedHashMap.of({
                "icon_header":
                    SettingsHeaderSmall(0, l10n.s_c_icon_header, always),
                "icon_preview": SettingsAppIconPreview(0, always),
                "icon_picker": SettingsSubGroup(
                    0,
                    null,
                    null,
                    l10n.s_c_replace_icon,
                    LinkedHashMap.of({
                      "icon_header":
                          SettingsHeader(0, l10n.s_ci_icon_header, always),
                      "warning_header":
                          SettingsHeader(0, l10n.s_ci_warning_header, isDebug),
                      "icon_subtitle":
                          SettingsSubtitle(0, l10n.s_ci_icon_subtitle, always),
                      "settings_padding": SettingsPadding(0, 24, always),
                      "icon_preview": SettingsAppIconPreview(0, always),
                      "settings_padding2": SettingsPadding(0, 24, always),
                      "child_protection": SettingsBoolean(
                          childProtection,
                          FirkaIconType.majesticons,
                          Majesticon.shieldSolid,
                          l10n.s_ci_child_protection,
                          true,
                          never),
                      "icon_picker": SettingsAppIconPicker(
                          0,
                          "original",
                          {
                            l10n.s_ci_icon_g1: [
                              "original",
                              "refilc",
                              "filc",
                              "galaxy",
                              "cactus",
                              "refulc",
                              "pixel"
                            ],
                            l10n.s_ci_icon_g2: [
                              "modern",
                              "paper",
                              "filco",
                              "o1g"
                            ],
                            l10n.s_ci_icon_g3: [
                              "kreta",
                              "cc",
                              "repont",
                              "void_icon",
                              "pixelized",
                              "fidesz",
                              "mkkp"
                            ],
                            l10n.s_ci_icon_g4: ["xmas1", "xmas2", "xmas3"],
                            l10n.s_ci_icon_g5: [
                              "lgbtq",
                              "lgbtqp",
                              "trans",
                              "enby",
                              "ace",
                              "gay",
                              "lesb",
                              "bi"
                            ],
                            l10n.s_ci_icon_g6: [
                              "lgbtq_f",
                              "lgbtqp_f",
                              "trans_f",
                              "enby_f",
                              "ace_f",
                              "gay_f",
                              "lesb_f",
                              "bi_f"
                            ]
                          },
                          always),
                    }),
                    isAndroid),
              }),
              always),
          "notifications": SettingsSubGroup(0, FirkaIconType.majesticons,
              Majesticon.bellSolid, "Értesítések", LinkedHashMap.of({}), never),
          "extras": SettingsSubGroup(
              0,
              FirkaIconType.majesticons,
              Majesticon.lightningBoltSolid,
              "Extrák",
              LinkedHashMap.of({}),
              never),
          "settings_other_padding": SettingsPadding(0, 20, never),
          "settings_other_header": SettingsHeaderSmall(0, "Egyéb", never),

          "developer": SettingsSubGroup(
              0,
              FirkaIconType.majesticonsLocal,
              "wrenchSolid",
              l10n.s_developer,
              LinkedHashMap.of({
                "stats_for_nerds": SettingsBoolean(
                    statsForNerds,
                    FirkaIconType.majesticonsLocal,
                    "wrenchSolid",
                    l10n.s_stats_for_nerds,
                    false,
                    always),
              }),
              isDeveloper),

          // misc
          "beta_warning": SettingsBoolean(
              betaWarning, null, null, "Beta warning", false, never),
          "timetable_toast": SettingsSubGroup(
              0,
              null,
              null,
              l10n.tt_settings_toast,
              LinkedHashMap.of({
                "header":
                    SettingsMediumHeader(0, l10n.tt_settings_toast, always),
                "padding": SettingsPadding(0, 16, always),
                "lesson_no": SettingsBoolean(
                    ttToastLessonNo,
                    FirkaIconType.majesticons,
                    Majesticon.clockSolid,
                    l10n.tt_settings_toast_lesson_nos,
                    true,
                    always),
                "tests_and_homework": SettingsBoolean(
                    ttToastTestsAndHw,
                    FirkaIconType.majesticons,
                    Majesticon.editPen4Solid,
                    l10n.tt_settings_toast_lesson_tests,
                    true,
                    always),
                "breaks": SettingsBoolean(
                    ttToastBreaks,
                    FirkaIconType.majesticons,
                    Majesticon.viewRowsLine,
                    l10n.tt_settings_toast_lesson_breaks,
                    true,
                    always),
              }),
              never),
          "developer_enabled": SettingsBoolean(
              developerOptsEnabled, null, null, "Developer", false, never),
        }),
        always);

    appIcons = {
      "ace": l10n.ic_ace,
      "ace_f": l10n.ic_ace_f,
      "bi": l10n.ic_bi,
      "bi_f": l10n.ic_bi_f,
      "cactus": l10n.ic_cactus,
      "cc": l10n.ic_cc,
      "enby": l10n.ic_enby,
      "enby_f": l10n.ic_enby_f,
      "fidesz": l10n.ic_fidesz,
      "filc": l10n.ic_filc,
      "filco": l10n.ic_filco,
      "galaxy": l10n.ic_galaxy,
      "gay": l10n.ic_gay,
      "gay_f": l10n.ic_gay_f,
      "kreta": l10n.ic_kreta,
      "lesb": l10n.ic_lesb,
      "lesb_f": l10n.ic_lesb_f,
      "lgbtq": l10n.ic_lgbtq,
      "lgbtq_f": l10n.ic_lgbtq_f,
      "lgbtqp": l10n.ic_lgbtqp,
      "lgbtqp_f": l10n.ic_lgbtqp_f,
      "mkkp": l10n.ic_mkkp,
      "modern": l10n.ic_modern,
      "o1g": l10n.ic_o1g,
      "original": l10n.ic_original,
      "paper": l10n.ic_paper,
      "pixel": l10n.ic_pixel,
      "pixelized": l10n.ic_pixelized,
      "refilc": l10n.ic_refilc,
      "refulc": l10n.ic_refulc,
      "repont": l10n.ic_repont,
      "trans": l10n.ic_trans,
      "trans_f": l10n.ic_trans_f,
      "void_icon": l10n.ic_void_icon,
      "xmas1": l10n.ic_xmas1,
      "xmas2": l10n.ic_xmas2,
      "xmas3": l10n.ic_xmas3
    };
  }

  LinkedHashMap<String, SettingsItem> group(String key) {
    return (items[key] as SettingsGroup).children;
  }

  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    for (var item in items.values) {
      await item.save(model);
    }

    initData.settingsUpdateNotifier.update();
  }

  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    for (var item in items.values) {
      await item.load(model);
    }
  }
}

extension SettingExt on LinkedHashMap<String, SettingsItem> {
  LinkedHashMap<String, SettingsItem> group(String key) {
    return (this[key] as SettingsGroup).children;
  }

  LinkedHashMap<String, SettingsItem> subGroup(String key) {
    return (this[key] as SettingsSubGroup).children;
  }

  String string(String key) {
    return (this[key] as SettingsString).value;
  }

  void setString(String key, String value) {
    (this[key] as SettingsString).value = value;
  }

  String iconString(String key) {
    return (this[key] as SettingsAppIconPicker).icon;
  }

  void setIconString(String key, String value) {
    (this[key] as SettingsAppIconPicker).icon = value;
  }

  double dbl(String key) {
    return (this[key] as SettingsDouble).value;
  }

  void setDbl(String key, double value) {
    (this[key] as SettingsDouble).value = value;
  }

  bool boolean(String key) {
    return (this[key] as SettingsBoolean).value;
  }

  void setBoolean(String key, bool value) {
    (this[key] as SettingsBoolean).value = value;
  }
}

class SettingsItem {
  Id key;
  FirkaIconType? iconType;
  Object? iconData;
  bool Function() visibilityProvider;
  Future<void> Function() postUpdate = () async {};

  SettingsItem(this.key, this.iconType, this.iconData, this.visibilityProvider);

  Future<void> save(IsarCollection<AppSettingsModel> model) async {}

  Future<void> load(IsarCollection<AppSettingsModel> model) async {}
}

class SettingsGroup implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  LinkedHashMap<String, SettingsItem> children;

  SettingsGroup(this.key, this.children, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    for (var item in children.values) {
      await item.load(model);
    }
  }

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    for (var item in children.values) {
      await item.save(model);
    }

    await postUpdate();

    initData.settingsUpdateNotifier.update();
  }
}

class SettingsSubGroup implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title;
  LinkedHashMap<String, SettingsItem> children;

  SettingsSubGroup(this.key, this.iconType, this.iconData, this.title,
      this.children, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    for (var item in children.values) {
      await item.load(model);
    }
  }

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    for (var item in children.values) {
      await item.save(model);
    }

    await postUpdate();

    initData.settingsUpdateNotifier.update();
  }
}

class SettingsPadding implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  double padding;

  SettingsPadding(this.key, this.padding, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {}

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {}
}

class SettingsHeader implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title;

  SettingsHeader(this.key, this.title, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {}

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {}
}

class SettingsMediumHeader implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title;

  SettingsMediumHeader(this.key, this.title, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {}

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {}
}

class SettingsHeaderSmall implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title;

  SettingsHeaderSmall(this.key, this.title, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {}

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {}
}

class SettingsSubtitle implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title;

  SettingsSubtitle(this.key, this.title, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {}

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {}
}

class SettingsAppIconPreview implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title = "";

  SettingsAppIconPreview(this.key, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {}

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {}
}

class SettingsAppIconPicker implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title = "";
  String icon = "";
  String defaultValue;
  Map<String, List<String>> iconGroups;

  SettingsAppIconPicker(
      this.key, this.defaultValue, this.iconGroups, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    var v = await model.get(key);
    if (v == null || v.valueString == null) {
      icon = defaultValue;
    } else {
      icon = v.valueString!;
    }
  }

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    var v = AppSettingsModel();
    v.id = key;
    v.valueString = icon;

    await model.put(v);

    initData.settingsUpdateNotifier.update();
  }
}

class SettingsBoolean implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title;
  bool value = false;
  bool defaultValue;

  SettingsBoolean(this.key, this.iconType, this.iconData, this.title,
      this.defaultValue, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    var v = await model.get(key);
    if (v == null || v.valueBool == null) {
      value = defaultValue;
    } else {
      value = v.valueBool!;
    }
  }

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    var v = AppSettingsModel();
    v.id = key;
    v.valueBool = value;

    await model.put(v);
    await postUpdate();

    initData.settingsUpdateNotifier.update();
  }
}

class SettingsItemsRadio implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate;
  List<String> values;
  int activeIndex = 0;
  int defaultIndex;

  SettingsItemsRadio(this.key, this.iconType, this.iconData, this.values,
      this.defaultIndex, this.visibilityProvider, this.postUpdate);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    var v = await model.get(key);
    if (v == null || v.valueIndex == null) {
      activeIndex = defaultIndex;
    } else {
      activeIndex = v.valueIndex!;
    }
  }

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    var v = AppSettingsModel();
    v.id = key;
    v.valueIndex = activeIndex;

    await model.put(v);
    await postUpdate();

    initData.settingsUpdateNotifier.update();
  }
}

class SettingsDouble implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title;
  double value = 0;
  double minValue = 0.0;
  double defaultValue;
  double maxValue = 0.0;
  int precision;

  SettingsDouble(
      this.key,
      this.iconType,
      this.iconData,
      this.title,
      this.minValue,
      this.defaultValue,
      this.maxValue,
      this.precision,
      this.visibilityProvider);

  double toRoundedDouble() {
    return double.parse(toRoundedString());
  }

  String toRoundedString() {
    return precision == 0
        ? value.toString().split(".")[0]
        : value.toStringAsPrecision(precision) == "0.0"
            ? "0"
            : value.toStringAsPrecision(precision);
  }

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    var v = await model.get(key);
    if (v == null || v.valueDouble == null) {
      value = defaultValue;
    } else {
      value = v.valueDouble!;
    }
  }

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    var v = AppSettingsModel();
    v.id = key;
    v.valueDouble = value;

    await model.put(v);
    await postUpdate();

    initData.settingsUpdateNotifier.update();
  }
}

class SettingsString implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  @override
  bool Function() visibilityProvider;
  @override
  Future<void> Function() postUpdate = () async {};
  String title;
  String value = "";
  String defaultValue;

  SettingsString(this.key, this.iconType, this.iconData, this.title,
      this.defaultValue, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    var v = await model.get(key);
    if (v == null || v.valueString == null) {
      value = defaultValue;
    } else {
      value = v.valueString!;
    }
  }

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    var v = AppSettingsModel();
    v.id = key;
    v.valueString = value;

    await model.put(v);
    await postUpdate();

    initData.settingsUpdateNotifier.update();
  }
}
