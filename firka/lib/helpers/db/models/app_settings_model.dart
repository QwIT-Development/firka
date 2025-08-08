import 'package:isar/isar.dart';

part 'app_settings_model.g.dart';

@collection
class AppSettingsModel {
  Id? id;
  double? valueDouble;
  bool? valueBool;
  String? valueString;

  AppSettingsModel();
}
