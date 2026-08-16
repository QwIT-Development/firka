import "package:isar_community/isar.dart";

part "user_theme_model.g.dart";

@collection
class UserThemeModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String themeId;

  late String name;

  /// `own` or `downloaded`. Built-in is not persisted.
  late String origin;

  late List<int> swatchArgb;

  UserThemeModel();
}
