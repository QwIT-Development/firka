import "package:isar_community/isar.dart";

/// A typed key for one persisted setting. Never constructed by hand outside
/// settings_schema.gen.dart; settings_schema.dart defines the full registry.
sealed class Setting<T> {
  final Id id;
  final T defaultValue;

  const Setting({required this.id, required this.defaultValue});
}

class BoolSetting extends Setting<bool> {
  const BoolSetting({required super.id, required super.defaultValue});
}

class DoubleSetting extends Setting<double> {
  final double min;
  final double max;
  final int precision;
  final double? step;

  const DoubleSetting({
    required super.id,
    required super.defaultValue,
    required this.min,
    required this.max,
    this.precision = 0,
    this.step,
  });
}

/// Persisted as the value's index into [values].
class EnumSetting<T extends Enum> extends Setting<T> {
  final List<T> values;

  const EnumSetting({
    required super.id,
    required super.defaultValue,
    required this.values,
  });
}

class StringSetting extends Setting<String> {
  const StringSetting({required super.id, required super.defaultValue});
}
