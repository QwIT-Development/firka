import 'dart:collection';
import 'dart:core';

import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:isar/isar.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

const bellRing = 1001;
const rounding1 = 1002;
const rounding2 = 1003;
const rounding3 = 1004;
const rounding4 = 1005;
const classAvgOnGraph = 1006;
const leftHandedMode = 1007;
const language = 1008;

bool always() {
  return true;
}

bool never() {
  return false;
}

class SettingsStore {
  LinkedHashMap<String, SettingsItem> items = LinkedHashMap.of({});

  SettingsStore() {
    items["settings"] = SettingsGroup(
        0,
        LinkedHashMap.of({
          "settings_header": SettingsHeader(0, "Beállítások", always),
          "settings_padding": SettingsPadding(0, 20, always),
          "application": SettingsSubGroup(
              0,
              FirkaIconType.majesticons,
              Majesticon.settingsCogSolid,
              "Alkalmazás",
              LinkedHashMap.of({
                // TODO: Make a back arrow widget
                "settings_header": SettingsHeader(0, "Általános", always),
                "settings_padding": SettingsPadding(0, 23, always),

                "bell_delay": SettingsDouble(bellRing, null, null,
                    "Csengő eltolódása", 0, 0, 120, 0, always),
                "rounding": SettingsSubGroup(
                    0,
                    null,
                    null,
                    "Alapértelmezett kerekítés",
                    LinkedHashMap.of({
                      "1": SettingsDouble(rounding1, null, null, "1 → 2", 0.1,
                          0.5, 0.99, 2, always),
                      "2": SettingsDouble(rounding2, null, null, "2 → 3", 0.1,
                          0.5, 0.99, 2, always),
                      "3": SettingsDouble(rounding3, null, null, "3 → 4", 0.1,
                          0.5, 0.99, 2, always),
                      "4": SettingsDouble(rounding4, null, null, "4 → 5", 0.1,
                          0.5, 0.99, 2, always),
                    }),
                    always),
                "class_avg_on_graph": SettingsBoolean(classAvgOnGraph, null,
                    null, "Osztályátlag a grafikonon", true, never),
                "navbar": SettingsSubGroup(
                    0,
                    null, // TODO: icon
                    null,
                    "Navigációs sáv",
                    LinkedHashMap.of({}),
                    never),
                "left_handed_mode": SettingsBoolean(
                    leftHandedMode, null, null, "Balkezes mód", false, never),
                "language_header": SettingsHeaderSmall(0, "Nyelv", always),
                "language": SettingsItemsRadio(language, null, null,
                    ["Autómatikus", "Magyar", "Angol", "Német"], 0, always)
              }),
              always),
          "customization": SettingsSubGroup(
              0,
              FirkaIconType.majesticons,
              Majesticon.flower2Solid,
              "Személyre szabás",
              LinkedHashMap.of({}),
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
        }),
        always);

    items;
  }

  LinkedHashMap<String, SettingsItem> group(String key) {
    return (items[key] as SettingsGroup).children;
  }

  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    for (var item in items.values) {
      await item.save(model);
    }
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
  String title;

  SettingsHeader(this.key, this.title, this.visibilityProvider);

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
  String title;

  SettingsSubtitle(this.key, this.title, this.visibilityProvider);

  @override
  Future<void> load(IsarCollection<AppSettingsModel> model) async {}

  @override
  Future<void> save(IsarCollection<AppSettingsModel> model) async {}
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
  List<String> values;
  int activeIndex = 0;
  int defaultIndex;

  SettingsItemsRadio(this.key, this.iconType, this.iconData, this.values,
      this.defaultIndex, this.visibilityProvider);

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
  }
}
