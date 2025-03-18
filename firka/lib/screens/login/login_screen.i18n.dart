import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("en_US") +
      {
        "hu_HU": {
          "Firka": "Firka",
          "Error initializing app": "Error initializing app",
        },
        "en_US": {
          "Firka": "Firka",
          "Error initializing app": "Error al inicializar la aplicación",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
  Map<String?, String> allVersions() => localizeAllVersions(this, _t);
}
