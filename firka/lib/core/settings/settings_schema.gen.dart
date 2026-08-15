// GENERATED CODE - DO NOT MODIFY BY HAND

part of "settings_schema.dart";

class SettingsRegistry {
  static const bellDelay = DoubleSetting(
    id: 1001,
    defaultValue: 0,
    min: 0,
    max: 120,
  );
  static const rounding1 = DoubleSetting(
    id: 1002,
    defaultValue: 0.5,
    min: 0.1,
    max: 0.99,
    precision: 2,
  );
  static const rounding2 = DoubleSetting(
    id: 1003,
    defaultValue: 0.5,
    min: 0.1,
    max: 0.99,
    precision: 2,
  );
  static const rounding3 = DoubleSetting(
    id: 1004,
    defaultValue: 0.5,
    min: 0.1,
    max: 0.99,
    precision: 2,
  );
  static const rounding4 = DoubleSetting(
    id: 1005,
    defaultValue: 0.5,
    min: 0.1,
    max: 0.99,
    precision: 2,
  );
  static const classAvgOnGraph = BoolSetting(id: 1006, defaultValue: true);
  static const leftHandedMode = BoolSetting(id: 1007, defaultValue: false);
  static const language = EnumSetting(
    id: 1008,
    defaultValue: AppLanguage.auto,
    values: AppLanguage.values,
  );
  static const appIcon = StringSetting(id: 0, defaultValue: "original");
  static const childProtection = BoolSetting(id: 1010, defaultValue: true);
  static const betaWarning = BoolSetting(id: 1011, defaultValue: false);
  static const ttToastLessonNo = BoolSetting(id: 1012, defaultValue: true);
  static const ttToastTestsAndHw = BoolSetting(id: 1013, defaultValue: true);
  static const ttToastBreaks = BoolSetting(id: 1014, defaultValue: true);
  static const statsForNerds = BoolSetting(id: 1015, defaultValue: false);
  static const developerOptsEnabled = BoolSetting(
    id: 1016,
    defaultValue: false,
  );
  static const themeBrightness = EnumSetting(
    id: 1017,
    defaultValue: ThemeBrightness.auto,
    values: ThemeBrightness.values,
  );
  static const ttToastSubstitution = BoolSetting(id: 1018, defaultValue: true);
  static const liveActivityEnabled = BoolSetting(id: 1019, defaultValue: false);
  static const liveActivityPrivacyEverDeclined = BoolSetting(
    id: 1020,
    defaultValue: false,
  );
  static const morningNotificationEnabled = BoolSetting(
    id: 1021,
    defaultValue: true,
  );
  static const morningNotificationTime = DoubleSetting(
    id: 1022,
    defaultValue: 120,
    min: 30,
    max: 240,
    precision: 0,
    step: 15,
  );
  static const ttToastABTimetable = BoolSetting(id: 1023, defaultValue: true);
  static const wearOsSupport = BoolSetting(id: 1024, defaultValue: false);

  static const all = <Setting>[
    bellDelay,
    rounding1,
    rounding2,
    rounding3,
    rounding4,
    classAvgOnGraph,
    leftHandedMode,
    language,
    appIcon,
    childProtection,
    betaWarning,
    ttToastLessonNo,
    ttToastTestsAndHw,
    ttToastBreaks,
    statsForNerds,
    developerOptsEnabled,
    themeBrightness,
    ttToastSubstitution,
    liveActivityEnabled,
    liveActivityPrivacyEverDeclined,
    morningNotificationEnabled,
    morningNotificationTime,
    ttToastABTimetable,
    wearOsSupport,
  ];
}

extension SettingsAccessors on SettingsRepository {
  SilentlySettable<double> get bellDelay =>
      SilentlySettable(this, SettingsRegistry.bellDelay);
  SilentlySettable<double> get rounding1 =>
      SilentlySettable(this, SettingsRegistry.rounding1);
  SilentlySettable<double> get rounding2 =>
      SilentlySettable(this, SettingsRegistry.rounding2);
  SilentlySettable<double> get rounding3 =>
      SilentlySettable(this, SettingsRegistry.rounding3);
  SilentlySettable<double> get rounding4 =>
      SilentlySettable(this, SettingsRegistry.rounding4);
  SilentlySettable<bool> get classAvgOnGraph =>
      SilentlySettable(this, SettingsRegistry.classAvgOnGraph);
  SilentlySettable<bool> get leftHandedMode =>
      SilentlySettable(this, SettingsRegistry.leftHandedMode);
  SilentlySettable<AppLanguage> get language =>
      SilentlySettable(this, SettingsRegistry.language);
  SilentlySettable<String> get appIcon =>
      SilentlySettable(this, SettingsRegistry.appIcon);
  SilentlySettable<bool> get childProtection =>
      SilentlySettable(this, SettingsRegistry.childProtection);
  SilentlySettable<bool> get betaWarning =>
      SilentlySettable(this, SettingsRegistry.betaWarning);
  SilentlySettable<bool> get ttToastLessonNo =>
      SilentlySettable(this, SettingsRegistry.ttToastLessonNo);
  SilentlySettable<bool> get ttToastTestsAndHw =>
      SilentlySettable(this, SettingsRegistry.ttToastTestsAndHw);
  SilentlySettable<bool> get ttToastBreaks =>
      SilentlySettable(this, SettingsRegistry.ttToastBreaks);
  SilentlySettable<bool> get statsForNerds =>
      SilentlySettable(this, SettingsRegistry.statsForNerds);
  SilentlySettable<bool> get developerOptsEnabled =>
      SilentlySettable(this, SettingsRegistry.developerOptsEnabled);
  SilentlySettable<ThemeBrightness> get themeBrightness =>
      SilentlySettable(this, SettingsRegistry.themeBrightness);
  SilentlySettable<bool> get ttToastSubstitution =>
      SilentlySettable(this, SettingsRegistry.ttToastSubstitution);
  SilentlySettable<bool> get liveActivityEnabled =>
      SilentlySettable(this, SettingsRegistry.liveActivityEnabled);
  SilentlySettable<bool> get liveActivityPrivacyEverDeclined =>
      SilentlySettable(this, SettingsRegistry.liveActivityPrivacyEverDeclined);
  SilentlySettable<bool> get morningNotificationEnabled =>
      SilentlySettable(this, SettingsRegistry.morningNotificationEnabled);
  SilentlySettable<double> get morningNotificationTime =>
      SilentlySettable(this, SettingsRegistry.morningNotificationTime);
  SilentlySettable<bool> get ttToastABTimetable =>
      SilentlySettable(this, SettingsRegistry.ttToastABTimetable);
  SilentlySettable<bool> get wearOsSupport =>
      SilentlySettable(this, SettingsRegistry.wearOsSupport);
}
