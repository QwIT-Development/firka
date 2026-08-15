import "package:flutter/widgets.dart";
import "package:isar_community/isar.dart";

import "package:firka/core/bloc/settings_cubit.dart";
import "package:firka_common/core/grade_helper.dart" as grade_helper;
import "package:firka_common/data/database.dart";
import "package:firka_common/data/models/app_settings_model.dart";
import "package:firka_common/data/models/token_model.dart";
import "package:firka_common/ui/theme/style.dart";

import "setting.dart";
import "settings_schema.dart";

/// Isar id for the selected Kréta account, kept outside SettingsRegistry since
/// it's not a bounded typed value. Distinct from appIcon's id 0 on purpose:
/// the original code reused id 0 for both, silently clobbering one another.
const _selectedAccountId = 1025;

/// Live, repository-bound access to every setting, e.g. `Settings.bellDelay.value`.
/// Set once at startup once the real SettingsRepository exists. Distinct from
/// SettingsRegistry, which only holds the typed key definitions (id, bounds,
/// default) and has no notion of a current value.
// ignore: non_constant_identifier_names
late SettingsRepository Settings;

/// A single setting bound to its repository. Generated accessors on
/// SettingsRepository (see settings_schema.gen.dart) return one of these per
/// setting, so callers read `.value` and write via `.set`/`.setSilently`
/// instead of the more verbose `repo.get(Settings.x)` / `repo.set(Settings.x, v)`.
class SilentlySettable<T> {
  final SettingsRepository _repo;
  final Setting<T> _setting;

  const SilentlySettable(this._repo, this._setting);

  T get value => _repo.get(_setting);

  Future<void> set(T value) => _repo.set(_setting, value);

  Future<void> setSilently(T value) => _repo.setSilently(_setting, value);
}

/// Owns every setting's current value and its Isar persistence.
/// Replaces the per-item load/save methods that used to live on each SettingsItem subclass.
class SettingsRepository {
  final Isar isar;
  SettingsCubit? cubit;
  IsarCollection<AppSettingsModel> get box => isar.appSettingsModels;
  final _values = <Id, dynamic>{};
  final _effects = <Id, List<Future<void> Function(dynamic)>>{};

  SettingsRepository(this.isar, [this.cubit]);

  T get<T>(Setting<T> setting) =>
      (_values[setting.id] ?? setting.defaultValue) as T;

  Future<void> set<T>(Setting<T> setting, T value) async {
    await setSilently(setting, value);

    for (final effect in _effects[setting.id] ?? const []) {
      await effect(value);
    }
  }

  /// Persists without running registered onChange effects. For code that IS
  /// itself an effect syncing a setting from an external source (e.g. the
  /// backend's live activity preferences) and would otherwise recursively
  /// trigger its own onChange handler.
  Future<void> setSilently<T>(Setting<T> setting, T value) async {
    _values[setting.id] = value;

    final row = AppSettingsModel()..id = setting.id;
    switch (value) {
      case bool v:
        row.valueBool = v;
      case double v:
        row.valueDouble = v;
      case Enum v:
        row.valueIndex = v.index;
      case String v:
        row.valueString = v;
    }
    await isar.writeTxn(() async {
      await box.put(row);
    });

    cubit?.notifyChanged();
  }

  void onChange<T>(Setting<T> setting, Future<void> Function(T value) effect) {
    (_effects[setting.id] ??= []).add((value) => effect(value as T));
  }

  Future<void> loadAll() async {
    for (final setting in SettingsRegistry.all) {
      final row = await box.get(setting.id);
      _values[setting.id] = switch (setting) {
        BoolSetting() => row?.valueBool ?? setting.defaultValue,
        DoubleSetting() => row?.valueDouble ?? setting.defaultValue,
        EnumSetting(:final values) =>
          row?.valueIndex != null
              ? values[row!.valueIndex!]
              : setting.defaultValue,
        StringSetting() => row?.valueString ?? setting.defaultValue,
      };
    }
  }

  int roundGrade(num grade) {
    return grade_helper.roundGrade(
      grade,
      t1: get(SettingsRegistry.rounding1),
      t2: get(SettingsRegistry.rounding2),
      t3: get(SettingsRegistry.rounding3),
      t4: get(SettingsRegistry.rounding4),
    );
  }

  Color getGradeColor(num grade) {
    return switch (roundGrade(grade)) {
      2 => appStyle.colors.grade2,
      3 => appStyle.colors.grade3,
      4 => appStyle.colors.grade4,
      5 => appStyle.colors.grade5,
      _ => appStyle.colors.grade1,
    };
  }

  int get selectedAccountKey =>
      box.getSync(_selectedAccountId)?.valueIndex ?? 0;

  Future<void> setSelectedAccountKey(int key) async {
    await isar.writeTxn(() async {
      await box.put(
        AppSettingsModel()
          ..id = _selectedAccountId
          ..valueIndex = key,
      );
    });
  }

  TokenModel? getSelectedToken() {
    return isarInit.tokenModels.getSync(selectedAccountKey) ??
        isarInit.tokenModels.where().findFirstSync();
  }
}
