import "package:firka/core/settings/settings_schema.dart";

extension TitleFontInfo on TitleFont {
  String get fontFamily => switch (this) {
    TitleFont.montserrat => "Montserrat",
    TitleFont.monoton => "Monoton",
    TitleFont.pirataOne => "Pirata One",
    TitleFont.justMeAgainDownHere => "Just Me Again Down Here",
    TitleFont.figtree => "Figtree",
    TitleFont.firaCode => "Fira Code",
    TitleFont.vollkorn => "Vollkorn",
  };

  String get displayName => fontFamily;

  bool get supportsWeight => switch (this) {
    TitleFont.montserrat ||
    TitleFont.figtree ||
    TitleFont.firaCode ||
    TitleFont.vollkorn => true,
    TitleFont.monoton ||
    TitleFont.pirataOne ||
    TitleFont.justMeAgainDownHere => false,
  };
}
