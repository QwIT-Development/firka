import "dart:io";

import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";
import "package:firka/core/settings/settings_ui.dart";
import "package:firka/l10n/app_localizations.dart";
import "package:firka/services/live_activity_service.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:flutter/foundation.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

bool always() => true;

bool never() => false;

bool isDeveloper() => isDebug() || Settings.developerOptsEnabled.value;

bool isAndroid() => Platform.isAndroid;

bool isIOS() => Platform.isIOS;

bool isLiveActivityEnabled() =>
    Platform.isIOS && Settings.liveActivityEnabled.value;

bool isMorningNotificationEnabled() =>
    Platform.isIOS && Settings.morningNotificationEnabled.value;

bool isWearOsSupportEnabled() =>
    Platform.isAndroid && Settings.wearOsSupport.value;

bool isPushNotificationsEnabled() => Settings.notifyAll.value;

bool isDebug() => kDebugMode;

bool isDebugIOS() => kDebugMode && Platform.isIOS;

Map<String, String> appIconLabels(AppLocalizations l10n) => {
  "ace": l10n.ic_ace,
  "ace_f": l10n.ic_ace_f,
  "bi": l10n.ic_bi,
  "bi_f": l10n.ic_bi_f,
  "cactus": l10n.ic_cactus,
  "cc": l10n.ic_cc,
  "enby": l10n.ic_enby,
  "enby_f": l10n.ic_enby_f,
  "fidesz": l10n.ic_fidesz,
  "filc": l10n.ic_filc,
  "filco": l10n.ic_filco,
  "galaxy": l10n.ic_galaxy,
  "gay": l10n.ic_gay,
  "gay_f": l10n.ic_gay_f,
  "half_firka_2": l10n.ic_half_firka_2,
  "kreta": l10n.ic_kreta,
  "lesb": l10n.ic_lesb,
  "lesb_f": l10n.ic_lesb_f,
  "lgbtq": l10n.ic_lgbtq,
  "lgbtq_f": l10n.ic_lgbtq_f,
  "lgbtqp": l10n.ic_lgbtqp,
  "lgbtqp_f": l10n.ic_lgbtqp_f,
  "mkkp": l10n.ic_mkkp,
  "nuke": l10n.ic_nuke,
  "modern": l10n.ic_modern,
  "o1g": l10n.ic_o1g,
  "old": l10n.ic_old,
  "original": l10n.ic_original,
  "paper": l10n.ic_paper,
  "pear": l10n.ic_pear,
  "pixel": l10n.ic_pixel,
  "pixelized": l10n.ic_pixelized,
  "pride": l10n.ic_pride,
  "proto": l10n.ic_proto,
  "refilc": l10n.ic_refilc,
  "refulc": l10n.ic_refulc,
  "repont": l10n.ic_repont,
  "szivacs": l10n.ic_szivacs,
  "tisza": l10n.ic_tisza,
  "trans": l10n.ic_trans,
  "trans_f": l10n.ic_trans_f,
  "void_icon": l10n.ic_void_icon,
  "xmas1": l10n.ic_xmas1,
  "xmas2": l10n.ic_xmas2,
  "xmas3": l10n.ic_xmas3,
};

/// Extracted so home_timetable.dart's quick-settings sheet can show just these
/// rows directly, the same way it did when this lived inline in the old tree.
List<SettingsUiNode> timetableToastTree(AppLocalizations l10n) => [
  SettingsUiMediumHeader(l10n.tt_settings_toast, always),
  SettingsUiPadding(16, always),
  SettingsUiBoolean(
    FirkaIconType.majesticons,
    Majesticon.clockSolid,
    l10n.tt_settings_toast_lesson_nos,
    SettingsRegistry.ttToastLessonNo,
    always,
  ),
  SettingsUiBoolean(
    FirkaIconType.majesticons,
    Majesticon.editPen4Solid,
    l10n.tt_settings_toast_lesson_tests,
    SettingsRegistry.ttToastTestsAndHw,
    always,
  ),
  SettingsUiBoolean(
    FirkaIconType.majesticons,
    Majesticon.usersSolid,
    l10n.tt_settings_toast_lesson_substitution,
    SettingsRegistry.ttToastSubstitution,
    always,
  ),
  SettingsUiBoolean(
    FirkaIconType.majesticons,
    Majesticon.viewRowsLine,
    l10n.tt_settings_toast_lesson_breaks,
    SettingsRegistry.ttToastBreaks,
    always,
  ),
  SettingsUiBoolean(
    FirkaIconType.majesticons,
    Majesticon.calendarSolid,
    l10n.tt_settings_toast_lesson_ab_timetable,
    SettingsRegistry.ttToastABTimetable,
    always,
  ),
];

SettingsUiGroup buildSettingsTree(AppLocalizations l10n) {
  final childProtection = SettingsUiBoolean(
    FirkaIconType.majesticons,
    Majesticon.shieldSolid,
    l10n.s_ci_child_protection,
    SettingsRegistry.childProtection,
    never,
  );

  final appIconPickerTree = <SettingsUiNode>[
    SettingsUiHeader(l10n.s_ci_icon_header, always),
    SettingsUiHeader(l10n.s_ci_warning_header, isDebug),
    // s_ci_icon_subtitle is intentionally unrendered: the original renderer
    // never had a case for SettingsSubtitle either, so this was already dead.
    SettingsUiPadding(24, always),
    SettingsUiAppIconPreview(always),
    SettingsUiPadding(24, always),
    childProtection,
    SettingsUiAppIconPicker(
      {
        l10n.s_ci_icon_g1: const ["original", "proto", "pride"],
        l10n.s_ci_icon_g2: const ["pixel", "galaxy", "cactus"],
        l10n.s_ci_icon_g3: const ["old", "refilc", "filc", "szivacs"],
        l10n.s_ci_icon_g4: const [
          "modern",
          "cc",
          "paper",
          "filco",
          "o1g",
          "pear",
          "half_firka_2",
          "nuke",
          "refulc",
        ],
        l10n.s_ci_icon_g5: const [
          "kreta",
          "cc",
          "repont",
          "void_icon",
          "pixelized",
          "mkkp",
          "fidesz",
          "tisza",
        ],
        l10n.s_ci_icon_g6: const ["xmas1", "xmas2", "xmas3"],
        l10n.s_ci_icon_g7: const [
          "lgbtq",
          "lgbtqp",
          "trans",
          "enby",
          "ace",
          "gay",
          "lesb",
          "bi",
        ],
        l10n.s_ci_icon_g8: const [
          "lgbtq_f",
          "lgbtqp_f",
          "trans_f",
          "enby_f",
          "ace_f",
          "gay_f",
          "lesb_f",
          "bi_f",
        ],
      },
      childProtection,
      always,
    ),
  ];

  return SettingsUiGroup([
    SettingsUiBackHeader(l10n.s_a, always),
    SettingsUiHeader(l10n.s_settings, always),
    SettingsUiPadding(20, always),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.settingsCogSolid,
      l10n.s_ag,
      [
        SettingsUiBackHeader(l10n.s_settings, always),
        SettingsUiHeader(l10n.s_ag, always),
        SettingsUiPadding(23, always),
        SettingsUiDouble(
          FirkaIconType.majesticons,
          Majesticon.bellSolid,
          l10n.s_ag_bell_delay,
          SettingsRegistry.bellDelay,
          always,
        ),
        SettingsUiSubGroup(
          FirkaIconType.majesticons,
          Majesticon.ruler2Solid,
          l10n.s_ag_rounding,
          [
            SettingsUiBackHeader(l10n.s_ag_rounding, always),
            SettingsUiDouble(
              null,
              null,
              l10n.s_ag_r1,
              SettingsRegistry.rounding1,
              always,
            ),
            SettingsUiDouble(
              null,
              null,
              l10n.s_ag_r2,
              SettingsRegistry.rounding2,
              always,
            ),
            SettingsUiDouble(
              null,
              null,
              l10n.s_ag_r3,
              SettingsRegistry.rounding3,
              always,
            ),
            SettingsUiDouble(
              null,
              null,
              l10n.s_ag_r4,
              SettingsRegistry.rounding4,
              always,
            ),
          ],
          always,
        ),
        SettingsUiBoolean(
          null,
          null,
          l10n.s_ag_class_avg_on_graph,
          SettingsRegistry.classAvgOnGraph,
          never,
        ),
        SettingsUiSubGroup(null, null, l10n.s_ag_navbar, const [], never),
        SettingsUiBoolean(
          null,
          null,
          l10n.s_ag_left_handed_mode,
          SettingsRegistry.leftHandedMode,
          never,
        ),
        SettingsUiBoolean(
          null,
          null,
          l10n.s_ag_privacy_ever_declined,
          SettingsRegistry.liveActivityPrivacyEverDeclined,
          never,
        ),
        SettingsUiHeaderSmall(l10n.s_ag_language_header, always),
        SettingsUiEnum(SettingsRegistry.language, [
          l10n.s_ag_language_auto,
          l10n.s_ag_language_hu,
          l10n.s_ag_language_en,
          l10n.s_ag_language_de,
        ], always),
      ],
      always,
      null,
      l10n.s_a_desc,
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.flower2Solid,
      l10n.s_c,
      [
        SettingsUiPersonalization(appIconPickerTree, always),
      ],
      always,
      null,
      l10n.s_c_desc,
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.bellSolid,
      l10n.s_notifications,
      [
        SettingsUiBackHeader(l10n.s_settings, always),
        SettingsUiHeader(l10n.s_notifications, always),
        SettingsUiPadding(23, always),
        SettingsUiBoolean(
          FirkaIconType.majesticons,
          Majesticon.bellSolid,
          l10n.s_notif_push_enabled,
          SettingsRegistry.notifyAll,
          always,
        ),
        SettingsUiHeaderSmall(l10n.s_notif_wakeup_interval_header, isPushNotificationsEnabled),
        SettingsUiEnum(SettingsRegistry.notifyWakeupInterval, [
          l10n.s_notif_wakeup_hourly,
          l10n.s_notif_wakeup_two_hourly,
        ], isPushNotificationsEnabled),
        SettingsUiHeaderSmall(l10n.s_notif_categories_header, isPushNotificationsEnabled),
        SettingsUiBoolean(
          null,
          null,
          l10n.s_notif_grades,
          SettingsRegistry.notifyGrades,
          isPushNotificationsEnabled,
        ),
        SettingsUiBoolean(
          null,
          null,
          l10n.s_notif_homework_tests,
          SettingsRegistry.notifyHomeworkTests,
          isPushNotificationsEnabled,
        ),
        SettingsUiBoolean(
          null,
          null,
          l10n.s_notif_absences,
          SettingsRegistry.notifyAbsences,
          isPushNotificationsEnabled,
        ),
        SettingsUiBoolean(
          null,
          null,
          l10n.s_notif_lessons,
          SettingsRegistry.notifyLessons,
          isPushNotificationsEnabled,
        ),
        SettingsUiBoolean(
          null,
          null,
          l10n.s_notif_messages,
          SettingsRegistry.notifyMessages,
          isPushNotificationsEnabled,
        ),
      ],
      isAndroid,
      null,
      l10n.s_notifications_desc,
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.clockSolid,
      l10n.s_wear,
      [
        SettingsUiBackHeader(l10n.s_settings, always),
        SettingsUiHeader(l10n.s_wear, always),
        SettingsUiPadding(23, always),
        SettingsUiBoolean(
          FirkaIconType.majesticons,
          Majesticon.clockSolid,
          l10n.s_wear_os_support,
          SettingsRegistry.wearOsSupport,
          always,
        ),
      ],
      isAndroid,
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.bellSolid,
      l10n.s_n,
      [
        SettingsUiBackHeader(l10n.s_settings, always),
        SettingsUiHeader(l10n.s_n, always),
        SettingsUiPadding(23, always),
        SettingsUiBoolean(
          FirkaIconType.majesticons,
          Majesticon.bellSolid,
          l10n.s_n_morning,
          SettingsRegistry.morningNotificationEnabled,
          always,
        ),
        SettingsUiDouble(
          FirkaIconType.majesticons,
          Majesticon.clockSolid,
          l10n.s_n_morning_time,
          SettingsRegistry.morningNotificationTime,
          isMorningNotificationEnabled,
        ),
        SettingsUiBoolean(
          FirkaIconType.majesticons,
          Majesticon.clockSolid,
          l10n.s_n_live_activity,
          SettingsRegistry.liveActivityEnabled,
          always,
        ),
        SettingsUiButton(
          FirkaIconType.majesticons,
          Majesticon.bellSolid,
          l10n.s_n_test,
          isDebugIOS,
          () async => LiveActivityService.sendTestNotification(),
        ),
      ],
      isIOS,
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.lightningBoltSolid,
      l10n.s_extras,
      [
        SettingsUiBackHeader(l10n.s_settings, always),
        SettingsUiHeader(l10n.s_extras, always),
        SettingsUiPadding(23, always),
        SettingsUiBoolean(
          FirkaIconType.majesticons,
          Majesticon.questionCircleSolid,
          l10n.s_surprise_grades,
          SettingsRegistry.surpriseGrades,
          always,
        ),
        SettingsUiBoolean(
          FirkaIconType.majesticons,
          Majesticon.shootingStarSolid,
          l10n.s_seasonal_icons,
          SettingsRegistry.seasonalAppIcons,
          always,
        ),
        SettingsUiBoolean(
          FirkaIconType.majesticons,
          Majesticon.flower2Solid,
          l10n.s_uwu_mode,
          SettingsRegistry.uwuMode,
          always,
        ),
        SettingsUiSubGroup(
          FirkaIconType.majesticons,
          Majesticon.calendarSolid,
          l10n.s_calendar_sync,
          const [],
          always,
          null,
          l10n.s_todo,
        ),
        SettingsUiSubGroup(
          FirkaIconType.majesticons,
          Majesticon.bookmarkSolid,
          l10n.s_save_grades,
          const [],
          always,
          null,
          l10n.s_todo,
        ),
        SettingsUiPadding(20, always),
        SettingsUiHeaderSmall(l10n.s_welcome_msg, always),
        SettingsUiSubGroup(
          null,
          null,
          l10n.s_welcome_msg,
          const [],
          always,
          null,
          l10n.s_todo,
        ),
      ],
      always,
      null,
      l10n.s_extras_desc,
    ),
    SettingsUiPadding(20, always),
    SettingsUiHeaderSmall(l10n.s_other, always),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.mapMarkerAreaSolid,
      l10n.s_sticker_map,
      const [],
      always,
      null,
      l10n.s_todo,
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.qrCodeSolid,
      l10n.s_qr_reader,
      const [],
      always,
      null,
      l10n.s_todo,
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticonsLocal,
      "wrenchSolid",
      l10n.s_developer,
      [
        SettingsUiBackHeader(l10n.s_settings, always),
        SettingsUiBoolean(
          FirkaIconType.majesticonsLocal,
          "wrenchSolid",
          l10n.s_stats_for_nerds,
          SettingsRegistry.statsForNerds,
          always,
        ),
        SettingsUiLogs(always),
      ],
      isDeveloper,
    ),
    SettingsUiBoolean(
      null,
      null,
      l10n.s_beta_warning,
      SettingsRegistry.betaWarning,
      never,
    ),
    SettingsUiSubGroup(
      null,
      null,
      l10n.tt_settings_toast,
      timetableToastTree(l10n),
      never,
    ),
    SettingsUiPadding(20, always),
    SettingsUiHeaderSmall(l10n.s_about, always),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.chatSolid,
      "Discord",
      const [],
      always,
      "discord",
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.lockSolid,
      l10n.privacyLabel,
      const [],
      always,
      "privacy",
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.awardSolid,
      l10n.licensesLabel,
      [
        SettingsUiBackHeader(l10n.s_settings, always),
        SettingsUiMediumHeader(l10n.licensesLabel, always),
        SettingsUiHeaderSmall(l10n.licenseDescription, always),
        SettingsUiLicensePage(always),
      ],
      always,
    ),
    SettingsUiSubGroup(
      FirkaIconType.majesticons,
      Majesticon.phoneSolid,
      l10n.s_feedback,
      const [],
      always,
      null,
      l10n.s_todo,
    ),
    SettingsUiBoolean(
      null,
      null,
      l10n.s_developer,
      SettingsRegistry.developerOptsEnabled,
      never,
    ),
  ], always);
}

SettingsUiGroup buildProfileSettingsTree(AppLocalizations l10n) {
  return SettingsUiGroup([
    SettingsUiBackHeader(l10n.s_your_account, always),
    SettingsUiHeaderSmall(l10n.s_acc_kreta, always),
    SettingsUiPadding(8, always),
    SettingsUiKretaAccountPicker(always),
  ], never);
}
