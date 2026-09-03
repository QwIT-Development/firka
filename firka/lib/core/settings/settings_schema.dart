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

  @BoolSetting(id: 1019, defaultValue: false)
  bool get liveActivityEnabled;

  @BoolSetting(id: 1020, defaultValue: false)
  bool get liveActivityPrivacyEverDeclined;

  @BoolSetting(id: 1021, defaultValue: true)
  bool get morningNotificationEnabled;

  @DoubleSetting(
    id: 1022,
    defaultValue: 120,
    min: 30,
    max: 240,
    precision: 0,
    step: 15,
  )
  double get morningNotificationTime;

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
}
