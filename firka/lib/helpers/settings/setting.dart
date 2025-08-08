import 'dart:collection';

import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:isar/isar.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

class SettingsStore {
  LinkedHashMap<String, SettingsItem> items = LinkedHashMap.of({});

  SettingsStore() {
    items["settings"] = SettingsGroup(
        0_001,
        LinkedHashMap.of({
          "application": SettingsSubGroup(1_001, FirkaIconType.Majesticons,
              Majesticon.settingsCogSolid, "Alkalmazás", []),
          "customization": SettingsSubGroup(2_001, FirkaIconType.Majesticons,
              Majesticon.flower2Solid, "Személyre szabás", []),
          "notifications": SettingsSubGroup(1_001, FirkaIconType.Majesticons,
              Majesticon.bellSolid, "Értesítések", []),
          "extras": SettingsSubGroup(1_001, FirkaIconType.Majesticons,
              Majesticon.lightningBoltSolid, "Extrák", []),
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

  SettingsItem(this.key);

  void save(IsarCollection<AppSettingsModel> model) {}

  void load(IsarCollection<AppSettingsModel> model) {}
}

class SettingsGroup implements SettingsItem {
  @override
  Id key;
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
  FirkaIconType? iconType;
  Object? iconData;
  String title;
  List<SettingsItem> children;

  SettingsSubGroup(
      this.key, this.iconType, this.iconData, this.title, this.children);

  @override
  void load(IsarCollection<AppSettingsModel> model) {
    for (var item in children) {
      item.load(model);
    }
  }

  @override
  void save(IsarCollection<AppSettingsModel> model) {
    for (var item in children) {
      item.save(model);
    }
  }
}

class SettingsHeader implements SettingsItem {
  @override
  Id key;
  String title;

  SettingsHeader(this.key, this.title);

  @override
  void load(IsarCollection<AppSettingsModel> model) {}

  @override
  void save(IsarCollection<AppSettingsModel> model) {}
}

class SettingsSubtitle implements SettingsItem {
  @override
  Id key;
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
  String title;
  bool value = false;
  bool defaultValue;

  SettingsBoolean(this.key, this.title, this.defaultValue);

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

class SettingsDouble implements SettingsItem {
  @override
  Id key;
  String title;
  double value = 0;
  double defaultValue;

  SettingsDouble(this.key, this.title, this.defaultValue);

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
  String title;
  String value = "";
  String defaultValue;

  SettingsString(this.key, this.title, this.defaultValue);

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
