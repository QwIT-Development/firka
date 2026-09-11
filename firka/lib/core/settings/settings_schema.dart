import "setting.dart";
import "settings_repository.dart";

part "settings_schema.gen.dart";

enum AppLanguage { auto, hu, en, de }

enum ThemeBrightness { auto, light, dark }

enum TitleFont {
  montserrat,
  monoton,
  pirataOne,
  justMeAgainDownHere,
  figtree,
  firaCode,
  vollkorn,
}

enum TitleCapitalization { lower, normal, upper }

/// How often the background wakeup push (that triggers a silent data refresh
/// + local notification) should fire. Backed by FCM topics `wakeup-hourly`/
/// `wakeup-2hourly` sent by the `fcm-notifier` backend service.
enum NotifyWakeupInterval { hourly, twoHourly }

enum NotificationDeliveryMethod { auto, fcm, alarm }

abstract class SettingsSchema {
  @DoubleSetting(id: 1001, defaultValue: 0, min: 0, max: 120)
  double get bellDelay;

  @DoubleSetting(id: 1002, defaultValue: 0.5, min: 0.1, max: 0.99, precision: 2)
  double get rounding1;

  @DoubleSetting(id: 1003, defaultValue: 0.5, min: 0.1, max: 0.99, precision: 2)
  double get rounding2;

  @DoubleSetting(id: 1004, defaultValue: 0.5, min: 0.1, max: 0.99, precision: 2)
  double get rounding3;

  @DoubleSetting(id: 1005, defaultValue: 0.5, min: 0.1, max: 0.99, precision: 2)
  double get rounding4;

  @BoolSetting(id: 1006, defaultValue: true)
  bool get classAvgOnGraph;

  @BoolSetting(id: 1007, defaultValue: false)
  bool get leftHandedMode;

  @EnumSetting(
    id: 1008,
    defaultValue: AppLanguage.auto,
    values: AppLanguage.values,
  )
  AppLanguage get language;

  // SettingsAppIconPicker has always persisted under a
  // hardcoded id of 0 instead of the appIcon constant.
  @StringSetting(id: 0, defaultValue: "original")
  String get appIcon;

  @BoolSetting(id: 1010, defaultValue: true)
  bool get childProtection;

  @BoolSetting(id: 1011, defaultValue: false)
  bool get betaWarning;

  @BoolSetting(id: 1012, defaultValue: true)
  bool get ttToastLessonNo;

  @BoolSetting(id: 1013, defaultValue: true)
  bool get ttToastTestsAndHw;

  @BoolSetting(id: 1014, defaultValue: true)
  bool get ttToastBreaks;

  @BoolSetting(id: 1015, defaultValue: false)
  bool get statsForNerds;

  @BoolSetting(id: 1016, defaultValue: false)
  bool get developerOptsEnabled;

  @EnumSetting(
    id: 1017,
    defaultValue: ThemeBrightness.auto,
    values: ThemeBrightness.values,
  )
  ThemeBrightness get themeBrightness;

  @BoolSetting(id: 1018, defaultValue: true)
  bool get ttToastSubstitution;

  @BoolSetting(id: 1023, defaultValue: true)
  bool get ttToastABTimetable;

  @BoolSetting(id: 1024, defaultValue: false)
  bool get wearOsSupport;

  // 1025 is reserved for the selected Kréta account outside SettingsRegistry.
  @EnumSetting(
    id: 1026,
    defaultValue: TitleFont.montserrat,
    values: TitleFont.values,
  )
  TitleFont get titleFont;

  @DoubleSetting(
    id: 1027,
    defaultValue: 700,
    min: 100,
    max: 900,
    precision: 0,
    step: 100,
  )
  double get titleWeight;

  @EnumSetting(
    id: 1028,
    defaultValue: TitleCapitalization.normal,
    values: TitleCapitalization.values,
  )
  TitleCapitalization get titleCapitalization;

  @StringSetting(id: 1029, defaultValue: "builtin-firka-firka")
  String get selectedThemeId;

  @StringSetting(id: 1030, defaultValue: "firka")
  String get selectedCoreThemeId;

  @StringSetting(id: 1031, defaultValue: "firka")
  String get selectedGradeThemeId;

  @BoolSetting(id: 1032, defaultValue: false)
  bool get mockBackendEnabled;

  @StringSetting(id: 1033, defaultValue: "http://10.0.0.144:8090")
  String get mockBackendUrl;

  @StringSetting(id: 1034, defaultValue: "{}")
  String get lastSeen;

  @BoolSetting(id: 1035, defaultValue: true)
  bool get surpriseGrades;

  @BoolSetting(id: 1036, defaultValue: true)
  bool get seasonalAppIcons;

  @BoolSetting(id: 1037, defaultValue: false)
  bool get uwuMode;

  @BoolSetting(id: 1038, defaultValue: true)
  bool get notifyAll;

  @BoolSetting(id: 1039, defaultValue: true)
  bool get notifyGrades;

  @BoolSetting(id: 1040, defaultValue: true)
  bool get notifyHomeworkTests;

  @BoolSetting(id: 1041, defaultValue: true)
  bool get notifyAbsences;

  @BoolSetting(id: 1042, defaultValue: true)
  bool get notifyLessons;

  @BoolSetting(id: 1043, defaultValue: true)
  bool get notifyMessages;

  @StringSetting(id: 1044, defaultValue: "[]")
  String get notifyMutedSubjects;

  @EnumSetting(
    id: 1045,
    defaultValue: NotifyWakeupInterval.hourly,
    values: NotifyWakeupInterval.values,
  )
  NotifyWakeupInterval get notifyWakeupInterval;

  @BoolSetting(id: 1046, defaultValue: false)
  bool get fcmDebugNotifyOnMessage;

  @EnumSetting(
    id: 1047,
    defaultValue: NotificationDeliveryMethod.auto,
    values: NotificationDeliveryMethod.values,
  )
  NotificationDeliveryMethod get notificationDeliveryMethod;

  // Custom grade colors stored as 0xAARRGGBB hex strings.
  // Defaults match the firka grade theme.
  @StringSetting(id: 1048, defaultValue: "0xFF22CCAD")
  String get customGradeColor5;

  @StringSetting(id: 1049, defaultValue: "0xFF92EA3B")
  String get customGradeColor4;

  @StringSetting(id: 1050, defaultValue: "0xFFF9CF00")
  String get customGradeColor3;

  @StringSetting(id: 1051, defaultValue: "0xFFFFA046")
  String get customGradeColor2;

  @StringSetting(id: 1052, defaultValue: "0xFFFF54A1")
  String get customGradeColor1;

  // Custom theme colors stored as 0xAARRGGBB hex strings.
  // Defaults match the firka core theme.
  @StringSetting(id: 1053, defaultValue: "0xFFA7DC22")
  String get customAccentColorLight;

  @StringSetting(id: 1054, defaultValue: "0xFFA7DC22")
  String get customAccentColorDark;

  @StringSetting(id: 1055, defaultValue: "0xFFFAFFF0")
  String get customBackgroundColorLight;

  @StringSetting(id: 1056, defaultValue: "0xFF0D1202")
  String get customBackgroundColorDark;

  @StringSetting(id: 1057, defaultValue: "0xFFF3FBDE")
  String get customCardColorLight;

  @StringSetting(id: 1058, defaultValue: "0xFF141905")
  String get customCardColorDark;

  @StringSetting(id: 1059, defaultValue: "0xFFFEFFFD")
  String get customButtonColorLight;

  @StringSetting(id: 1060, defaultValue: "0xFF20290B")
  String get customButtonColorDark;

  @StringSetting(id: 1061, defaultValue: "0xFF6E8F1B")
  String get customSecondaryColorLight;

  @StringSetting(id: 1062, defaultValue: "0xFFCBEE71")
  String get customSecondaryColorDark;

  @StringSetting(id: 1063, defaultValue: "0xFF394C0A")
  String get customTextColorLight;

  @StringSetting(id: 1064, defaultValue: "0xFFEAF7CC")
  String get customTextColorDark;

  @StringSetting(id: 1065, defaultValue: "0xCC394C0A")
  String get customTextSecondaryColorLight;

  @StringSetting(id: 1066, defaultValue: "0xB3EAF7CC")
  String get customTextSecondaryColorDark;

  @StringSetting(id: 1067, defaultValue: "0x80394C0A")
  String get customTextTertiaryColorLight;

  @StringSetting(id: 1068, defaultValue: "0x80EAF7CC")
  String get customTextTertiaryColorDark;

  @StringSetting(id: 1069, defaultValue: "0x33647E22")
  String get customShadowColorLight;

  @StringSetting(id: 1070, defaultValue: "0x26CBEE71")
  String get customShadowColorDark;

  @StringSetting(id: 1071, defaultValue: "0xFF92EA3B")
  String get customSuccessColorLight;

  @StringSetting(id: 1072, defaultValue: "0xFF92EA3B")
  String get customSuccessColorDark;

  @StringSetting(id: 1073, defaultValue: "0xFFFFA046")
  String get customWarningAccentColorLight;

  @StringSetting(id: 1074, defaultValue: "0xFFFFA046")
  String get customWarningAccentColorDark;

  @StringSetting(id: 1075, defaultValue: "0xFF8F531B")
  String get customWarningTextColorLight;

  @StringSetting(id: 1076, defaultValue: "0xFFF0B37A")
  String get customWarningTextColorDark;

  @StringSetting(id: 1077, defaultValue: "0xFFFAEBDC")
  String get customWarningCardColorLight;

  @StringSetting(id: 1078, defaultValue: "0xFF201203")
  String get customWarningCardColorDark;

  @StringSetting(id: 1079, defaultValue: "0xFFFF54A1")
  String get customErrorAccentColorLight;

  @StringSetting(id: 1080, defaultValue: "0xFFFF54A1")
  String get customErrorAccentColorDark;

  @StringSetting(id: 1081, defaultValue: "0xFF8F1B4F")
  String get customErrorTextColorLight;

  @StringSetting(id: 1082, defaultValue: "0xFFF59EC5")
  String get customErrorTextColorDark;

  @StringSetting(id: 1083, defaultValue: "0xFFFADCE9")
  String get customErrorCardColorLight;

  @StringSetting(id: 1084, defaultValue: "0xFF1E030F")
  String get customErrorCardColorDark;
}
