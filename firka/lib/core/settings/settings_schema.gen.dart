// GENERATED CODE - DO NOT MODIFY BY HAND

part of "settings_schema.dart";

class SettingsRegistry {
  static const bellDelay = DoubleSetting(id: 1001, defaultValue: 0, min: 0, max: 120);
  static const rounding1 = DoubleSetting(id: 1002, defaultValue: 0.5, min: 0.1, max: 0.99, precision: 2);
  static const rounding2 = DoubleSetting(id: 1003, defaultValue: 0.5, min: 0.1, max: 0.99, precision: 2);
  static const rounding3 = DoubleSetting(id: 1004, defaultValue: 0.5, min: 0.1, max: 0.99, precision: 2);
  static const rounding4 = DoubleSetting(id: 1005, defaultValue: 0.5, min: 0.1, max: 0.99, precision: 2);
  static const classAvgOnGraph = BoolSetting(id: 1006, defaultValue: true);
  static const leftHandedMode = BoolSetting(id: 1007, defaultValue: false);
  static const language = EnumSetting(id: 1008, defaultValue: AppLanguage.auto, values: AppLanguage.values);
  static const appIcon = StringSetting(id: 0, defaultValue: "original");
  static const childProtection = BoolSetting(id: 1010, defaultValue: true);
  static const betaWarning = BoolSetting(id: 1011, defaultValue: false);
  static const ttToastLessonNo = BoolSetting(id: 1012, defaultValue: true);
  static const ttToastTestsAndHw = BoolSetting(id: 1013, defaultValue: true);
  static const ttToastBreaks = BoolSetting(id: 1014, defaultValue: true);
  static const statsForNerds = BoolSetting(id: 1015, defaultValue: false);
  static const developerOptsEnabled = BoolSetting(id: 1016, defaultValue: false);
  static const themeBrightness = EnumSetting(id: 1017, defaultValue: ThemeBrightness.auto, values: ThemeBrightness.values);
  static const ttToastSubstitution = BoolSetting(id: 1018, defaultValue: true);
  static const liveActivityEnabled = BoolSetting(id: 1019, defaultValue: false);
  static const liveActivityPrivacyEverDeclined = BoolSetting(id: 1020, defaultValue: false);
  static const morningNotificationEnabled = BoolSetting(id: 1021, defaultValue: true);
  static const morningNotificationTime = DoubleSetting(id: 1022, defaultValue: 120, min: 30, max: 240, precision: 0, step: 15);
  static const ttToastABTimetable = BoolSetting(id: 1023, defaultValue: true);
  static const wearOsSupport = BoolSetting(id: 1024, defaultValue: false);
  static const titleFont = EnumSetting(id: 1026, defaultValue: TitleFont.montserrat, values: TitleFont.values);
  static const titleWeight = DoubleSetting(id: 1027, defaultValue: 700, min: 100, max: 900, precision: 0, step: 100);
  static const titleCapitalization = EnumSetting(id: 1028, defaultValue: TitleCapitalization.normal, values: TitleCapitalization.values);
  static const selectedThemeId = StringSetting(id: 1029, defaultValue: "builtin-firka-firka");
  static const selectedCoreThemeId = StringSetting(id: 1030, defaultValue: "firka");
  static const selectedGradeThemeId = StringSetting(id: 1031, defaultValue: "firka");
  static const mockBackendEnabled = BoolSetting(id: 1032, defaultValue: false);
  static const mockBackendUrl = StringSetting(id: 1033, defaultValue: "http://10.0.0.144:8090");
  static const lastSeen = StringSetting(id: 1034, defaultValue: "{}");
  static const surpriseGrades = BoolSetting(id: 1035, defaultValue: true);
  static const seasonalAppIcons = BoolSetting(id: 1036, defaultValue: true);
  static const uwuMode = BoolSetting(id: 1037, defaultValue: false);
  static const notifyAll = BoolSetting(id: 1038, defaultValue: true);
  static const notifyGrades = BoolSetting(id: 1039, defaultValue: true);
  static const notifyHomeworkTests = BoolSetting(id: 1040, defaultValue: true);
  static const notifyAbsences = BoolSetting(id: 1041, defaultValue: true);
  static const notifyLessons = BoolSetting(id: 1042, defaultValue: true);
  static const notifyMessages = BoolSetting(id: 1043, defaultValue: true);
  static const notifyMutedSubjects = StringSetting(id: 1044, defaultValue: "[]");

  static const all = <Setting>[
    bellDelay, rounding1, rounding2, rounding3, rounding4, classAvgOnGraph, leftHandedMode, language, appIcon, childProtection, betaWarning, ttToastLessonNo, ttToastTestsAndHw, ttToastBreaks, statsForNerds, developerOptsEnabled, themeBrightness, ttToastSubstitution, liveActivityEnabled, liveActivityPrivacyEverDeclined, morningNotificationEnabled, morningNotificationTime, ttToastABTimetable, wearOsSupport, titleFont, titleWeight, titleCapitalization, selectedThemeId, selectedCoreThemeId, selectedGradeThemeId, mockBackendEnabled, mockBackendUrl, lastSeen, surpriseGrades, seasonalAppIcons, uwuMode, notifyAll, notifyGrades, notifyHomeworkTests, notifyAbsences, notifyLessons, notifyMessages, notifyMutedSubjects,
  ];
}

extension SettingsAccessors on SettingsRepository {
  SilentlySettable<double> get bellDelay => SilentlySettable(this, SettingsRegistry.bellDelay);
  SilentlySettable<double> get rounding1 => SilentlySettable(this, SettingsRegistry.rounding1);
  SilentlySettable<double> get rounding2 => SilentlySettable(this, SettingsRegistry.rounding2);
  SilentlySettable<double> get rounding3 => SilentlySettable(this, SettingsRegistry.rounding3);
  SilentlySettable<double> get rounding4 => SilentlySettable(this, SettingsRegistry.rounding4);
  SilentlySettable<bool> get classAvgOnGraph => SilentlySettable(this, SettingsRegistry.classAvgOnGraph);
  SilentlySettable<bool> get leftHandedMode => SilentlySettable(this, SettingsRegistry.leftHandedMode);
  SilentlySettable<AppLanguage> get language => SilentlySettable(this, SettingsRegistry.language);
  SilentlySettable<String> get appIcon => SilentlySettable(this, SettingsRegistry.appIcon);
  SilentlySettable<bool> get childProtection => SilentlySettable(this, SettingsRegistry.childProtection);
  SilentlySettable<bool> get betaWarning => SilentlySettable(this, SettingsRegistry.betaWarning);
  SilentlySettable<bool> get ttToastLessonNo => SilentlySettable(this, SettingsRegistry.ttToastLessonNo);
  SilentlySettable<bool> get ttToastTestsAndHw => SilentlySettable(this, SettingsRegistry.ttToastTestsAndHw);
  SilentlySettable<bool> get ttToastBreaks => SilentlySettable(this, SettingsRegistry.ttToastBreaks);
  SilentlySettable<bool> get statsForNerds => SilentlySettable(this, SettingsRegistry.statsForNerds);
  SilentlySettable<bool> get developerOptsEnabled => SilentlySettable(this, SettingsRegistry.developerOptsEnabled);
  SilentlySettable<ThemeBrightness> get themeBrightness => SilentlySettable(this, SettingsRegistry.themeBrightness);
  SilentlySettable<bool> get ttToastSubstitution => SilentlySettable(this, SettingsRegistry.ttToastSubstitution);
  SilentlySettable<bool> get liveActivityEnabled => SilentlySettable(this, SettingsRegistry.liveActivityEnabled);
  SilentlySettable<bool> get liveActivityPrivacyEverDeclined => SilentlySettable(this, SettingsRegistry.liveActivityPrivacyEverDeclined);
  SilentlySettable<bool> get morningNotificationEnabled => SilentlySettable(this, SettingsRegistry.morningNotificationEnabled);
  SilentlySettable<double> get morningNotificationTime => SilentlySettable(this, SettingsRegistry.morningNotificationTime);
  SilentlySettable<bool> get ttToastABTimetable => SilentlySettable(this, SettingsRegistry.ttToastABTimetable);
  SilentlySettable<bool> get wearOsSupport => SilentlySettable(this, SettingsRegistry.wearOsSupport);
  SilentlySettable<TitleFont> get titleFont => SilentlySettable(this, SettingsRegistry.titleFont);
  SilentlySettable<double> get titleWeight => SilentlySettable(this, SettingsRegistry.titleWeight);
  SilentlySettable<TitleCapitalization> get titleCapitalization => SilentlySettable(this, SettingsRegistry.titleCapitalization);
  SilentlySettable<String> get selectedThemeId => SilentlySettable(this, SettingsRegistry.selectedThemeId);
  SilentlySettable<String> get selectedCoreThemeId => SilentlySettable(this, SettingsRegistry.selectedCoreThemeId);
  SilentlySettable<String> get selectedGradeThemeId => SilentlySettable(this, SettingsRegistry.selectedGradeThemeId);
  SilentlySettable<bool> get mockBackendEnabled => SilentlySettable(this, SettingsRegistry.mockBackendEnabled);
  SilentlySettable<String> get mockBackendUrl => SilentlySettable(this, SettingsRegistry.mockBackendUrl);
  SilentlySettable<String> get lastSeen => SilentlySettable(this, SettingsRegistry.lastSeen);
  SilentlySettable<bool> get surpriseGrades => SilentlySettable(this, SettingsRegistry.surpriseGrades);
  SilentlySettable<bool> get seasonalAppIcons => SilentlySettable(this, SettingsRegistry.seasonalAppIcons);
  SilentlySettable<bool> get uwuMode => SilentlySettable(this, SettingsRegistry.uwuMode);
  SilentlySettable<bool> get notifyAll => SilentlySettable(this, SettingsRegistry.notifyAll);
  SilentlySettable<bool> get notifyGrades => SilentlySettable(this, SettingsRegistry.notifyGrades);
  SilentlySettable<bool> get notifyHomeworkTests => SilentlySettable(this, SettingsRegistry.notifyHomeworkTests);
  SilentlySettable<bool> get notifyAbsences => SilentlySettable(this, SettingsRegistry.notifyAbsences);
  SilentlySettable<bool> get notifyLessons => SilentlySettable(this, SettingsRegistry.notifyLessons);
  SilentlySettable<bool> get notifyMessages => SilentlySettable(this, SettingsRegistry.notifyMessages);
  SilentlySettable<String> get notifyMutedSubjects => SilentlySettable(this, SettingsRegistry.notifyMutedSubjects);
}
