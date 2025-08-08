import 'dart:collection';

import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:isar/isar.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

const bellRing = 1_001;
const rounding1 = 1_002;
const rounding2 = 1_003;
const rounding3 = 1_004;
const rounding4 = 1_005;
const classAvgOnGraph = 1_006;
const leftHandedMode = 1_007;
const language = 1_008;

class SettingsStore {
  LinkedHashMap<String, SettingsItem> items = LinkedHashMap.of({});

  SettingsStore() {
    items["settings"] = SettingsGroup(
        0,
        LinkedHashMap.of({
          "settings_header": SettingsHeader(0, "Beállítások"),
          "settings_padding": SettingsPadding(0, 20),
          "application": SettingsSubGroup(
              0,
              FirkaIconType.Majesticons,
              Majesticon.settingsCogSolid,
              "Alkalmazás",
              LinkedHashMap.of({
                // TODO: Make a back arrow widget
                "settings_header": SettingsHeader(0, "Általános"),
                "settings_padding": SettingsPadding(0, 23),

                "bell_delay": SettingsDouble(
                    bellRing, null, null, "Csengő eltolódása", 0),
                "rounding_1": SettingsDouble(rounding1, null, null,
                    "Alapértelmezett kerekítés 1 -> 2", 0.5),
                "rounding_2": SettingsDouble(rounding2, null, null,
                    "Alapértelmezett kerekítés 2 -> 3", 0.5),
                "rounding_3": SettingsDouble(rounding3, null, null,
                    "Alapértelmezett kerekítés 3 -> 4", 0.5),
                "rounding_4": SettingsDouble(rounding4, null, null,
                    "Alapértelmezett kerekítés 4 -> 5", 0.5),
                "class_avg_on_graph": SettingsBoolean(classAvgOnGraph, null,
                    null, "Osztályátlag a grafikonon", true),
                "navbar": SettingsSubGroup(
                  0,
                  null, // TODO: icon
                  null,
                  "Navigációs sáv",
                  LinkedHashMap.of({}),
                ),
                "left_handed_mode": SettingsBoolean(
                    leftHandedMode, null, null, "Balkezes mód", false),
                "language_header": SettingsHeaderSmall(0, "Nyelv"),
                "language": SettingsItemsRadio(language, null, null,
                    ["Autómatikus", "Magyar", "Angol", "Német"], 0)
              })),
          "customization": SettingsSubGroup(
              0,
              FirkaIconType.Majesticons,
              Majesticon.flower2Solid,
              "Személyre szabás",
              LinkedHashMap.of({})),
          "notifications": SettingsSubGroup(0, FirkaIconType.Majesticons,
              Majesticon.bellSolid, "Értesítések", LinkedHashMap.of({})),
          "extras": SettingsSubGroup(0, FirkaIconType.Majesticons,
              Majesticon.lightningBoltSolid, "Extrák", LinkedHashMap.of({})),
          "settings_other_padding": SettingsPadding(0, 20),
          "settings_other_header": SettingsHeaderSmall(0, "Egyéb"),
        }));

    items;
  }

  LinkedHashMap<String, SettingsItem> group(String key) {
    return (items[key] as SettingsGroup).children;
  }

  Future<void> save(IsarCollection<AppSettingsModel> model) async {
    for (var item in items.values) {
      item.save(model);
    }
  }

  Future<void> load(IsarCollection<AppSettingsModel> model) async {
    for (var item in items.values) {
      item.load(model);
    }
  }
}

extension SettingExt on LinkedHashMap<String, SettingsItem> {
  LinkedHashMap<String, SettingsItem> group(String key) {
    return (this[key] as SettingsGroup).children;
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

  SettingsItem(this.key, this.iconType, this.iconData);

  void save(IsarCollection<AppSettingsModel> model) {}

  void load(IsarCollection<AppSettingsModel> model) {}
}

class SettingsGroup implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  LinkedHashMap<String, SettingsItem> children;

  SettingsGroup(this.key, this.children);

  @override
  void load(IsarCollection<AppSettingsModel> model) {
    for (var item in children.values) {
      item.load(model);
    }
  }

  @override
  void save(IsarCollection<AppSettingsModel> model) {
    for (var item in children.values) {
      item.save(model);
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
  String title;
  LinkedHashMap<String, SettingsItem> children;

  SettingsSubGroup(
      this.key, this.iconType, this.iconData, this.title, this.children);

  @override
  void load(IsarCollection<AppSettingsModel> model) {
    for (var item in children.values) {
      item.load(model);
    }
  }

  @override
  void save(IsarCollection<AppSettingsModel> model) {
    for (var item in children.values) {
      item.save(model);
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
  double padding;

  SettingsPadding(this.key, this.padding);

  @override
  void load(IsarCollection<AppSettingsModel> model) {}

  @override
  void save(IsarCollection<AppSettingsModel> model) {}
}

class SettingsHeader implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  String title;

  SettingsHeader(this.key, this.title);

  @override
  void load(IsarCollection<AppSettingsModel> model) {}

  @override
  void save(IsarCollection<AppSettingsModel> model) {}
}

class SettingsHeaderSmall implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  String title;

  SettingsHeaderSmall(this.key, this.title);

  @override
  void load(IsarCollection<AppSettingsModel> model) {}

  @override
  void save(IsarCollection<AppSettingsModel> model) {}
}

class SettingsSubtitle implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  String title;

  SettingsSubtitle(this.key, this.title);

  @override
  void load(IsarCollection<AppSettingsModel> model) {}

  @override
  void save(IsarCollection<AppSettingsModel> model) {}
}

class SettingsBoolean implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  String title;
  bool value = false;
  bool defaultValue;

  SettingsBoolean(
      this.key, this.iconType, this.iconData, this.title, this.defaultValue);

  @override
  void load(IsarCollection<AppSettingsModel> model) {
    var v = model.getSync(key);
    if (v == null || v.valueBool == null) {
      value = defaultValue;
    } else {
      value = v.valueBool!;
    }
  }

  @override
  void save(IsarCollection<AppSettingsModel> model) {
    var v = AppSettingsModel();
    v.id = key;
    v.valueBool = value;

    model.put(v);
  }
}

class SettingsItemsRadio implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  List<String> values;
  int activeIndex = 0;
  int defaultIndex;

  SettingsItemsRadio(
      this.key, this.iconType, this.iconData, this.values, this.defaultIndex);

  @override
  void load(IsarCollection<AppSettingsModel> model) {
    var v = model.getSync(key);
    if (v == null || v.valueIndex == null) {
      activeIndex = v!.valueIndex!;
    } else {
      activeIndex = defaultIndex;
    }
  }

  @override
  void save(IsarCollection<AppSettingsModel> model) {
    var v = AppSettingsModel();
    v.id = key;
    v.valueIndex = activeIndex;

    model.put(v);
  }
}

class SettingsDouble implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  String title;
  double value = 0;
  double defaultValue;

  SettingsDouble(
      this.key, this.iconType, this.iconData, this.title, this.defaultValue);

  @override
  void load(IsarCollection<AppSettingsModel> model) {
    var v = model.getSync(key);
    if (v == null || v.valueDouble == null) {
      value = defaultValue;
    } else {
      value = v.valueDouble!;
    }
  }

  @override
  void save(IsarCollection<AppSettingsModel> model) {
    var v = AppSettingsModel();
    v.id = key;
    v.valueDouble = value;

    model.put(v);
  }
}

class SettingsString implements SettingsItem {
  @override
  Id key;
  @override
  FirkaIconType? iconType;
  @override
  Object? iconData;
  String title;
  String value = "";
  String defaultValue;

  SettingsString(
      this.key, this.iconType, this.iconData, this.title, this.defaultValue);

  @override
  void load(IsarCollection<AppSettingsModel> model) {
    var v = model.getSync(key);
    if (v == null || v.valueString == null) {
      value = defaultValue;
    } else {
      value = v.valueString!;
    }
  }

  @override
  void save(IsarCollection<AppSettingsModel> model) {
    var v = AppSettingsModel();
    v.id = key;
    v.valueString = value;

    model.put(v);
  }
}
