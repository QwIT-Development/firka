import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('hu'),
    Locale('pl')
  ];

  /// No description provided for @restart_title.
  ///
  /// In en, this message translates to:
  /// **'Restart application'**
  String get restart_title;

  /// No description provided for @restart_body.
  ///
  /// In en, this message translates to:
  /// **'Click here to open the app again.'**
  String get restart_body;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Login with E-Kréta'**
  String get loginBtn;

  /// No description provided for @privacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyLabel;

  /// No description provided for @title1.
  ///
  /// In en, this message translates to:
  /// **'Know everything at a glance'**
  String get title1;

  /// No description provided for @subtitle1.
  ///
  /// In en, this message translates to:
  /// **'You can see useful info about your day on the top of your home screen.'**
  String get subtitle1;

  /// No description provided for @title2.
  ///
  /// In en, this message translates to:
  /// **'Your classes fit here comfortably'**
  String get title2;

  /// No description provided for @subtitle2.
  ///
  /// In en, this message translates to:
  /// **'See statistics, upcoming tests, and even your grades from previous school years.'**
  String get subtitle2;

  /// No description provided for @title3.
  ///
  /// In en, this message translates to:
  /// **'Customizable timetable'**
  String get title3;

  /// No description provided for @subtitle3.
  ///
  /// In en, this message translates to:
  /// **'Decide what you want to see on your timetable page. Turn tests, assignments, breaks, and even free periods on or off.'**
  String get subtitle3;

  /// No description provided for @title4.
  ///
  /// In en, this message translates to:
  /// **'Many extras you will never find in Kréta'**
  String get title4;

  /// No description provided for @subtitle4.
  ///
  /// In en, this message translates to:
  /// **''**
  String get subtitle4;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @debug_screen.
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get debug_screen;

  /// No description provided for @settings_screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_screen;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetable;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @reauth.
  ///
  /// In en, this message translates to:
  /// **'Reauthentication required'**
  String get reauth;

  /// No description provided for @api_error.
  ///
  /// In en, this message translates to:
  /// **'Kréta API error'**
  String get api_error;

  /// No description provided for @pairing.
  ///
  /// In en, this message translates to:
  /// **'Pair your watch'**
  String get pairing;

  /// No description provided for @pairing_description.
  ///
  /// In en, this message translates to:
  /// **'Would you like to pair this watch with the Firka app?\nAfter pairing, you will be able to see your timetable, new grades, tests and tasks.'**
  String get pairing_description;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @beta_title.
  ///
  /// In en, this message translates to:
  /// **'Firka - Public Beta'**
  String get beta_title;

  /// No description provided for @beta_body.
  ///
  /// In en, this message translates to:
  /// **'The application is still in development; some features may be unfinished, not work correctly, or be buggy.'**
  String get beta_body;

  /// No description provided for @good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {p}!'**
  String good_morning(String p);

  /// No description provided for @good_day.
  ///
  /// In en, this message translates to:
  /// **'Good day, {p}!'**
  String good_day(String p);

  /// No description provided for @n_left_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hang in there, there\'s only {n} lessons left!'**
  String n_left_subtitle(num n);

  /// No description provided for @suffering_almost_over_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re almost free. Keep paying attention to your teacher.'**
  String get suffering_almost_over_subtitle;

  /// No description provided for @school_ending.
  ///
  /// In en, this message translates to:
  /// **'Are you anxious, {p}?'**
  String school_ending(String p);

  /// No description provided for @tomorrow_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your next day'**
  String get tomorrow_subtitle;

  /// No description provided for @good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {p}!'**
  String good_afternoon(String p);

  /// No description provided for @good_night.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {p}!'**
  String good_night(String p);

  /// No description provided for @starting_soon.
  ///
  /// In en, this message translates to:
  /// **'Your first lesson will start soon!'**
  String get starting_soon;

  /// No description provided for @starting_hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get starting_hour;

  /// No description provided for @starting_hour_plural.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get starting_hour_plural;

  /// No description provided for @starting_min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get starting_min;

  /// No description provided for @starting_min_plural.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get starting_min_plural;

  /// No description provided for @starting_sec.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get starting_sec;

  /// No description provided for @starting_sec_plural.
  ///
  /// In en, this message translates to:
  /// **'secs'**
  String get starting_sec_plural;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @your_subjects.
  ///
  /// In en, this message translates to:
  /// **'Your Subjects'**
  String get your_subjects;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get data;

  /// No description provided for @subject_avg.
  ///
  /// In en, this message translates to:
  /// **'Subject average'**
  String get subject_avg;

  /// No description provided for @subject_avg_rounded.
  ///
  /// In en, this message translates to:
  /// **'Subject average after rounding'**
  String get subject_avg_rounded;

  /// No description provided for @class_avg.
  ///
  /// In en, this message translates to:
  /// **'Class average'**
  String get class_avg;

  /// No description provided for @class_n.
  ///
  /// In en, this message translates to:
  /// **'Weekly lesson number'**
  String get class_n;

  /// No description provided for @tt_no_classes_l1.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any lessons on this day!'**
  String get tt_no_classes_l1;

  /// No description provided for @tt_no_classes_l2.
  ///
  /// In en, this message translates to:
  /// **'Yippee!'**
  String get tt_no_classes_l2;

  /// No description provided for @class_dismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed lesson'**
  String get class_dismissed;

  /// No description provided for @catalog_lesson_btn.
  ///
  /// In en, this message translates to:
  /// **'Catalog lesson'**
  String get catalog_lesson_btn;

  /// No description provided for @catalog_lesson_title.
  ///
  /// In en, this message translates to:
  /// **'Catalog lesson'**
  String get catalog_lesson_title;

  /// No description provided for @catalog_lesson_topic_hint.
  ///
  /// In en, this message translates to:
  /// **'Topic covered'**
  String get catalog_lesson_topic_hint;

  /// No description provided for @catalog_lesson_submit_btn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get catalog_lesson_submit_btn;

  /// No description provided for @class_substitution.
  ///
  /// In en, this message translates to:
  /// **'Substitution'**
  String get class_substitution;

  /// No description provided for @lesson_subject.
  ///
  /// In en, this message translates to:
  /// **'Lesson subject'**
  String get lesson_subject;

  /// No description provided for @tt_settings_toast.
  ///
  /// In en, this message translates to:
  /// **'Timetable settings'**
  String get tt_settings_toast;

  /// No description provided for @tt_settings_toast_lesson_nos.
  ///
  /// In en, this message translates to:
  /// **'Number of lessons'**
  String get tt_settings_toast_lesson_nos;

  /// No description provided for @tt_settings_toast_lesson_tests.
  ///
  /// In en, this message translates to:
  /// **'Tests & others'**
  String get tt_settings_toast_lesson_tests;

  /// No description provided for @tt_settings_toast_lesson_breaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get tt_settings_toast_lesson_breaks;

  /// No description provided for @a_week.
  ///
  /// In en, this message translates to:
  /// **'A week'**
  String get a_week;

  /// No description provided for @b_week.
  ///
  /// In en, this message translates to:
  /// **'B week'**
  String get b_week;

  /// No description provided for @stats_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get stats_date;

  /// No description provided for @stats_created_at.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get stats_created_at;

  /// No description provided for @stats_last_mod.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get stats_last_mod;

  /// No description provided for @s_developer.
  ///
  /// In en, this message translates to:
  /// **'Developer settings'**
  String get s_developer;

  /// No description provided for @s_stats_for_nerds.
  ///
  /// In en, this message translates to:
  /// **'Stats for nerds'**
  String get s_stats_for_nerds;

  /// No description provided for @s_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get s_settings;

  /// No description provided for @s_a.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get s_a;

  /// No description provided for @s_ag.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get s_ag;

  /// No description provided for @s_ag_bell_delay.
  ///
  /// In en, this message translates to:
  /// **'Bell delay'**
  String get s_ag_bell_delay;

  /// No description provided for @s_ag_rounding.
  ///
  /// In en, this message translates to:
  /// **'Default rounding'**
  String get s_ag_rounding;

  /// No description provided for @s_shortened_timetable.
  ///
  /// In en, this message translates to:
  /// **'Shortened timetable'**
  String get s_shortened_timetable;

  /// No description provided for @s_shortened_timetable_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable shortened timetable'**
  String get s_shortened_timetable_enable;

  /// No description provided for @s_shortened_timetable_start.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get s_shortened_timetable_start;

  /// No description provided for @s_shortened_timetable_end.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get s_shortened_timetable_end;

  /// No description provided for @s_shortened_timetable_no_lessons.
  ///
  /// In en, this message translates to:
  /// **'No lessons to show in the cache. Refresh the timetable and try again.'**
  String get s_shortened_timetable_no_lessons;

  /// No description provided for @s_shortened_timetable_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset to original times'**
  String get s_shortened_timetable_reset;

  /// No description provided for @s_shortened_timetable_invalid_time.
  ///
  /// In en, this message translates to:
  /// **'The end must be after the start'**
  String get s_shortened_timetable_invalid_time;

  /// No description provided for @s_shortened_timetable_lesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson {n}'**
  String s_shortened_timetable_lesson(int n);

  /// No description provided for @s_customization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get s_customization;

  /// No description provided for @s_ag_r1.
  ///
  /// In en, this message translates to:
  /// **'1 → 2'**
  String get s_ag_r1;

  /// No description provided for @s_ag_r2.
  ///
  /// In en, this message translates to:
  /// **'2 → 3'**
  String get s_ag_r2;

  /// No description provided for @s_ag_r3.
  ///
  /// In en, this message translates to:
  /// **'3 → 4'**
  String get s_ag_r3;

  /// No description provided for @s_ag_r4.
  ///
  /// In en, this message translates to:
  /// **'4 → 5'**
  String get s_ag_r4;

  /// No description provided for @s_ag_class_avg_on_graph.
  ///
  /// In en, this message translates to:
  /// **'Class\'s average on the graph'**
  String get s_ag_class_avg_on_graph;

  /// No description provided for @s_ag_navbar.
  ///
  /// In en, this message translates to:
  /// **'Navbar'**
  String get s_ag_navbar;

  /// No description provided for @s_ag_left_handed_mode.
  ///
  /// In en, this message translates to:
  /// **'Left-handed mode'**
  String get s_ag_left_handed_mode;

  /// No description provided for @s_ag_language_header.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get s_ag_language_header;

  /// No description provided for @s_ag_language_auto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get s_ag_language_auto;

  /// No description provided for @s_ag_language_hu.
  ///
  /// In en, this message translates to:
  /// **'Hungarian'**
  String get s_ag_language_hu;

  /// No description provided for @s_ag_language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get s_ag_language_en;

  /// No description provided for @s_ag_language_de.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get s_ag_language_de;

  /// No description provided for @s_c.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get s_c;

  /// No description provided for @s_c_icon_header.
  ///
  /// In en, this message translates to:
  /// **'App icons'**
  String get s_c_icon_header;

  /// No description provided for @s_c_replace_icon.
  ///
  /// In en, this message translates to:
  /// **'Replace icon'**
  String get s_c_replace_icon;

  /// No description provided for @s_ci_icon_header.
  ///
  /// In en, this message translates to:
  /// **'App icon'**
  String get s_ci_icon_header;

  /// No description provided for @s_ci_warning_header.
  ///
  /// In en, this message translates to:
  /// **'[!] Changing the app\'s icon in debug mode won\'t work'**
  String get s_ci_warning_header;

  /// No description provided for @s_ci_icon_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a pretty app icon if you\'re already tired of the green one.'**
  String get s_ci_icon_subtitle;

  /// No description provided for @s_ci_icon_g1.
  ///
  /// In en, this message translates to:
  /// **'Catboy domain'**
  String get s_ci_icon_g1;

  /// No description provided for @s_ci_icon_g2.
  ///
  /// In en, this message translates to:
  /// **'Felt pen'**
  String get s_ci_icon_g2;

  /// No description provided for @s_ci_icon_g3.
  ///
  /// In en, this message translates to:
  /// **'Nostalgia'**
  String get s_ci_icon_g3;

  /// No description provided for @s_ci_icon_g4.
  ///
  /// In en, this message translates to:
  /// **'Reimagined'**
  String get s_ci_icon_g4;

  /// No description provided for @s_ci_icon_g5.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get s_ci_icon_g5;

  /// No description provided for @s_ci_icon_g6.
  ///
  /// In en, this message translates to:
  /// **'Christmas logo competition 2024'**
  String get s_ci_icon_g6;

  /// No description provided for @s_ci_icon_g6_desc.
  ///
  /// In en, this message translates to:
  /// **'By @emilia6_6'**
  String get s_ci_icon_g6_desc;

  /// No description provided for @s_ci_icon_g7.
  ///
  /// In en, this message translates to:
  /// **'Pride'**
  String get s_ci_icon_g7;

  /// No description provided for @s_ci_icon_g8.
  ///
  /// In en, this message translates to:
  /// **'Pride '**
  String get s_ci_icon_g8;

  /// No description provided for @s_c_theme_header.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get s_c_theme_header;

  /// No description provided for @s_c_theme_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get s_c_theme_auto;

  /// No description provided for @s_c_theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get s_c_theme_light;

  /// No description provided for @s_c_theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get s_c_theme_dark;

  /// No description provided for @s_ci_child_protection.
  ///
  /// In en, this message translates to:
  /// **'Child protection'**
  String get s_ci_child_protection;

  /// No description provided for @ic_ace.
  ///
  /// In en, this message translates to:
  /// **'Asexual'**
  String get ic_ace;

  /// No description provided for @ic_ace_f.
  ///
  /// In en, this message translates to:
  /// **'Asexual'**
  String get ic_ace_f;

  /// No description provided for @ic_bi.
  ///
  /// In en, this message translates to:
  /// **'Bisexual'**
  String get ic_bi;

  /// No description provided for @ic_bi_f.
  ///
  /// In en, this message translates to:
  /// **'Bisexual'**
  String get ic_bi_f;

  /// No description provided for @ic_cactus.
  ///
  /// In en, this message translates to:
  /// **'Cactus grove'**
  String get ic_cactus;

  /// No description provided for @ic_cc.
  ///
  /// In en, this message translates to:
  /// **'Creative Cloud'**
  String get ic_cc;

  /// No description provided for @ic_enby.
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get ic_enby;

  /// No description provided for @ic_enby_f.
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get ic_enby_f;

  /// No description provided for @ic_fidesz.
  ///
  /// In en, this message translates to:
  /// **'Fidesz'**
  String get ic_fidesz;

  /// No description provided for @ic_filc.
  ///
  /// In en, this message translates to:
  /// **'Firka'**
  String get ic_filc;

  /// No description provided for @ic_filco.
  ///
  /// In en, this message translates to:
  /// **'Filc . O'**
  String get ic_filco;

  /// No description provided for @ic_galaxy.
  ///
  /// In en, this message translates to:
  /// **'Galaxy'**
  String get ic_galaxy;

  /// No description provided for @ic_gay.
  ///
  /// In en, this message translates to:
  /// **'Gay'**
  String get ic_gay;

  /// No description provided for @ic_gay_f.
  ///
  /// In en, this message translates to:
  /// **'Gay'**
  String get ic_gay_f;

  /// No description provided for @ic_half_firka_2.
  ///
  /// In en, this message translates to:
  /// **'Revolution'**
  String get ic_half_firka_2;

  /// No description provided for @ic_kreta.
  ///
  /// In en, this message translates to:
  /// **'eFirka'**
  String get ic_kreta;

  /// No description provided for @ic_lesb.
  ///
  /// In en, this message translates to:
  /// **'Lesbian'**
  String get ic_lesb;

  /// No description provided for @ic_lesb_f.
  ///
  /// In en, this message translates to:
  /// **'Lesbian'**
  String get ic_lesb_f;

  /// No description provided for @ic_lgbtq.
  ///
  /// In en, this message translates to:
  /// **'LGBTQ+'**
  String get ic_lgbtq;

  /// No description provided for @ic_lgbtq_f.
  ///
  /// In en, this message translates to:
  /// **'LGBTQ+'**
  String get ic_lgbtq_f;

  /// No description provided for @ic_lgbtqp.
  ///
  /// In en, this message translates to:
  /// **'Progression'**
  String get ic_lgbtqp;

  /// No description provided for @ic_lgbtqp_f.
  ///
  /// In en, this message translates to:
  /// **'Progression'**
  String get ic_lgbtqp_f;

  /// No description provided for @ic_lidl.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get ic_lidl;

  /// No description provided for @ic_mkkp.
  ///
  /// In en, this message translates to:
  /// **'Free grades'**
  String get ic_mkkp;

  /// No description provided for @ic_nuke.
  ///
  /// In en, this message translates to:
  /// **'Nuclear'**
  String get ic_nuke;

  /// No description provided for @ic_modern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get ic_modern;

  /// No description provided for @ic_o1g.
  ///
  /// In en, this message translates to:
  /// **'Orbán is a cunt'**
  String get ic_o1g;

  /// No description provided for @ic_old.
  ///
  /// In en, this message translates to:
  /// **'Domain Dave'**
  String get ic_old;

  /// No description provided for @ic_original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get ic_original;

  /// No description provided for @ic_paper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get ic_paper;

  /// No description provided for @ic_pear.
  ///
  /// In en, this message translates to:
  /// **'Pear'**
  String get ic_pear;

  /// No description provided for @ic_pixel.
  ///
  /// In en, this message translates to:
  /// **'Pixel'**
  String get ic_pixel;

  /// No description provided for @ic_pixelized.
  ///
  /// In en, this message translates to:
  /// **'Pixelified'**
  String get ic_pixelized;

  /// No description provided for @ic_pride.
  ///
  /// In en, this message translates to:
  /// **'Space rainbow'**
  String get ic_pride;

  /// No description provided for @ic_proto.
  ///
  /// In en, this message translates to:
  /// **'Prototype'**
  String get ic_proto;

  /// No description provided for @ic_refilc.
  ///
  /// In en, this message translates to:
  /// **'reFilc'**
  String get ic_refilc;

  /// No description provided for @ic_refulc.
  ///
  /// In en, this message translates to:
  /// **'firk\'a'**
  String get ic_refulc;

  /// No description provided for @ic_repont.
  ///
  /// In en, this message translates to:
  /// **'Repont'**
  String get ic_repont;

  /// No description provided for @ic_szivacs.
  ///
  /// In en, this message translates to:
  /// **'sponge'**
  String get ic_szivacs;

  /// No description provided for @ic_tisza.
  ///
  /// In en, this message translates to:
  /// **'árad a firka'**
  String get ic_tisza;

  /// No description provided for @ic_trans.
  ///
  /// In en, this message translates to:
  /// **'Trans'**
  String get ic_trans;

  /// No description provided for @ic_trans_f.
  ///
  /// In en, this message translates to:
  /// **'Trans'**
  String get ic_trans_f;

  /// No description provided for @ic_void_icon.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get ic_void_icon;

  /// No description provided for @ic_xmas1.
  ///
  /// In en, this message translates to:
  /// **'naughty list'**
  String get ic_xmas1;

  /// No description provided for @ic_xmas2.
  ///
  /// In en, this message translates to:
  /// **'gift'**
  String get ic_xmas2;

  /// No description provided for @ic_xmas3.
  ///
  /// In en, this message translates to:
  /// **'FirCristmas'**
  String get ic_xmas3;

  /// No description provided for @wear_phone_unpaired.
  ///
  /// In en, this message translates to:
  /// **'Your watch isn\'t paired with your phone!'**
  String get wear_phone_unpaired;

  /// No description provided for @wear_phone_disconnected.
  ///
  /// In en, this message translates to:
  /// **'Your watch isn\'t connected to your phone!'**
  String get wear_phone_disconnected;

  /// No description provided for @wear_pairing_request_sent.
  ///
  /// In en, this message translates to:
  /// **'Open the app on your phone'**
  String get wear_pairing_request_sent;

  /// No description provided for @wear_pairing_check_phone.
  ///
  /// In en, this message translates to:
  /// **'Check your phone'**
  String get wear_pairing_check_phone;

  /// No description provided for @wear_try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get wear_try_again;

  /// No description provided for @breakTxt.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakTxt;

  /// No description provided for @empty_class.
  ///
  /// In en, this message translates to:
  /// **'Empty class'**
  String get empty_class;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{mins, plural, =1{1 min left} other{{mins} mins left}}'**
  String timeLeft(num mins);

  /// No description provided for @noClasses.
  ///
  /// In en, this message translates to:
  /// **'School\'s out today, take it easy!'**
  String get noClasses;

  /// No description provided for @noMoreClasses.
  ///
  /// In en, this message translates to:
  /// **'No more classes for you today'**
  String get noMoreClasses;

  /// No description provided for @firstIn.
  ///
  /// In en, this message translates to:
  /// **'First class in: {t}'**
  String firstIn(String t);

  /// No description provided for @wearTitle.
  ///
  /// In en, this message translates to:
  /// **'{n}. class'**
  String wearTitle(num n);

  /// No description provided for @licensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licensesLabel;

  /// No description provided for @licenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Licenses for external libraries used by the application'**
  String get licenseDescription;

  /// No description provided for @view_subject_btn.
  ///
  /// In en, this message translates to:
  /// **'View subject'**
  String get view_subject_btn;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Time of the class'**
  String get date;

  /// No description provided for @tt_settings_toast_lesson_substitution.
  ///
  /// In en, this message translates to:
  /// **'Substitutions'**
  String get tt_settings_toast_lesson_substitution;

  /// No description provided for @tt_settings_toast_lesson_ab_timetable.
  ///
  /// In en, this message translates to:
  /// **'Two-week class schedule'**
  String get tt_settings_toast_lesson_ab_timetable;

  /// No description provided for @s_ag_navbar_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose which items appear in the navigation bar and arrange them. The other pages are accessible via the “More” button. You can display up to 4 pages.'**
  String get s_ag_navbar_desc;

  /// No description provided for @s_ag_navbar_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get s_ag_navbar_home;

  /// No description provided for @s_ag_navbar_visible.
  ///
  /// In en, this message translates to:
  /// **'Appears'**
  String get s_ag_navbar_visible;

  /// No description provided for @happy_birthday.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday, {p}!'**
  String happy_birthday(String p);

  /// No description provided for @tests_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'You\'ll have {tests} exams'**
  String tests_tomorrow(String tests);

  /// No description provided for @no_tests_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any exams tomorrow'**
  String get no_tests_tomorrow;

  /// No description provided for @get_ready.
  ///
  /// In en, this message translates to:
  /// **'Relax, and prepare for tomorrow'**
  String get get_ready;

  /// No description provided for @homework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homework;

  /// No description provided for @mark_as_done.
  ///
  /// In en, this message translates to:
  /// **'Mark as finished'**
  String get mark_as_done;

  /// No description provided for @mark_as_not_done.
  ///
  /// In en, this message translates to:
  /// **'Mark as unfinished'**
  String get mark_as_not_done;

  /// No description provided for @grade_teacherName.
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s name: '**
  String get grade_teacherName;

  /// No description provided for @grade_strValue.
  ///
  /// In en, this message translates to:
  /// **'Text-based rating: '**
  String get grade_strValue;

  /// No description provided for @no_grades.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any grades for this subject yet.'**
  String get no_grades;

  /// No description provided for @unknown_teacher.
  ///
  /// In en, this message translates to:
  /// **'Unknown teacher'**
  String get unknown_teacher;

  /// No description provided for @tt_added.
  ///
  /// In en, this message translates to:
  /// **'Created at: '**
  String get tt_added;

  /// No description provided for @view_lesson_btn.
  ///
  /// In en, this message translates to:
  /// **'View lesson'**
  String get view_lesson_btn;

  /// No description provided for @s_ag_navbar_hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get s_ag_navbar_hidden;

  /// No description provided for @s_your_account.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get s_your_account;

  /// No description provided for @s_acc_kreta.
  ///
  /// In en, this message translates to:
  /// **'eKRÉTA accounts'**
  String get s_acc_kreta;

  /// No description provided for @s_acc_accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get s_acc_accounts;

  /// No description provided for @s_neptun_title.
  ///
  /// In en, this message translates to:
  /// **'ELTE Neptun'**
  String get s_neptun_title;

  /// No description provided for @s_neptun_user_hint.
  ///
  /// In en, this message translates to:
  /// **'ID (e.g. abc123)'**
  String get s_neptun_user_hint;

  /// No description provided for @s_neptun_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get s_neptun_password_hint;

  /// No description provided for @s_neptun_totp_code_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get s_neptun_totp_code_hint;

  /// No description provided for @s_neptun_code_by_email.
  ///
  /// In en, this message translates to:
  /// **'code sent by e-mail'**
  String get s_neptun_code_by_email;

  /// No description provided for @s_neptun_confirm_code.
  ///
  /// In en, this message translates to:
  /// **'Confirm code'**
  String get s_neptun_confirm_code;

  /// No description provided for @s_neptun_login_btn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get s_neptun_login_btn;

  /// No description provided for @s_neptun_seed_hint.
  ///
  /// In en, this message translates to:
  /// **'Authenticator key (optional)'**
  String get s_neptun_seed_hint;

  /// No description provided for @s_neptun_seed_help.
  ///
  /// In en, this message translates to:
  /// **'Enter your 2FA authenticator\'s secret key. NOT the 6 digit code.'**
  String get s_neptun_seed_help;

  /// No description provided for @s_neptun_login_with_elte.
  ///
  /// In en, this message translates to:
  /// **'Log in with ELTE Neptun'**
  String get s_neptun_login_with_elte;

  /// No description provided for @s_neptun_seed_failed.
  ///
  /// In en, this message translates to:
  /// **'Automatic 2FA code generation failed — check your authenticator key.'**
  String get s_neptun_seed_failed;

  /// No description provided for @s_neptun_2fa_rejected.
  ///
  /// In en, this message translates to:
  /// **'2FA code rejected — if the code is correct, restart the login and enter a fresh code.'**
  String get s_neptun_2fa_rejected;

  /// No description provided for @s_neptun_login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get s_neptun_login_failed;

  /// No description provided for @s_acc_add.
  ///
  /// In en, this message translates to:
  /// **'Add new student account'**
  String get s_acc_add;

  /// No description provided for @s_acc_add_teacher.
  ///
  /// In en, this message translates to:
  /// **'Add new teacher account'**
  String get s_acc_add_teacher;

  /// No description provided for @s_acc_logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get s_acc_logout;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tt_non_instructional_day.
  ///
  /// In en, this message translates to:
  /// **'Non-instructional workday'**
  String get tt_non_instructional_day;

  /// No description provided for @tt_public_holiday.
  ///
  /// In en, this message translates to:
  /// **'Non-instructional day'**
  String get tt_public_holiday;

  /// No description provided for @tt_spring_break.
  ///
  /// In en, this message translates to:
  /// **'Spring break'**
  String get tt_spring_break;

  /// No description provided for @tt_winter_break.
  ///
  /// In en, this message translates to:
  /// **'Winter break'**
  String get tt_winter_break;

  /// No description provided for @tt_autumn_break.
  ///
  /// In en, this message translates to:
  /// **'Autumn break'**
  String get tt_autumn_break;

  /// No description provided for @tt_instructional_day.
  ///
  /// In en, this message translates to:
  /// **'Instructional day'**
  String get tt_instructional_day;

  /// No description provided for @tt_first_semester_end.
  ///
  /// In en, this message translates to:
  /// **'End of first semester'**
  String get tt_first_semester_end;

  /// No description provided for @tt_holiday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get tt_holiday;

  /// No description provided for @tt_rest_day.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get tt_rest_day;

  /// No description provided for @tt_first_instructional_day.
  ///
  /// In en, this message translates to:
  /// **'First instructional day'**
  String get tt_first_instructional_day;

  /// No description provided for @tt_last_instructional_day.
  ///
  /// In en, this message translates to:
  /// **'Last instructional day'**
  String get tt_last_instructional_day;

  /// No description provided for @tt_last_instructional_day_graduates.
  ///
  /// In en, this message translates to:
  /// **'Last instructional day for graduates'**
  String get tt_last_instructional_day_graduates;

  /// No description provided for @tt_full_day_trip.
  ///
  /// In en, this message translates to:
  /// **'Full-day trip'**
  String get tt_full_day_trip;

  /// No description provided for @tt_quarter_end.
  ///
  /// In en, this message translates to:
  /// **'end of quarter'**
  String get tt_quarter_end;

  /// No description provided for @lessons_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'You\'ll have {lessons} lessons'**
  String lessons_tomorrow(String lessons);

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @grade_calculator.
  ///
  /// In en, this message translates to:
  /// **'Grade calculator'**
  String get grade_calculator;

  /// No description provided for @grade_calculator_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get grade_calculator_add;

  /// No description provided for @ghost_grade.
  ///
  /// In en, this message translates to:
  /// **'Ghost grade'**
  String get ghost_grade;

  /// No description provided for @ghost_grades.
  ///
  /// In en, this message translates to:
  /// **'Ghost grades'**
  String get ghost_grades;

  /// No description provided for @gradesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} grade(s)'**
  String gradesCount(int count);

  /// No description provided for @overall_avg.
  ///
  /// In en, this message translates to:
  /// **'Overall average'**
  String get overall_avg;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @s_n.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get s_n;

  /// No description provided for @s_n_morning.
  ///
  /// In en, this message translates to:
  /// **'Morning notification'**
  String get s_n_morning;

  /// No description provided for @s_n_morning_time.
  ///
  /// In en, this message translates to:
  /// **'Time of notification before school'**
  String get s_n_morning_time;

  /// No description provided for @s_n_live_activity.
  ///
  /// In en, this message translates to:
  /// **'Live Activity'**
  String get s_n_live_activity;

  /// No description provided for @s_n_test.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get s_n_test;

  /// No description provided for @s_wear.
  ///
  /// In en, this message translates to:
  /// **'Wear OS'**
  String get s_wear;

  /// No description provided for @s_wear_os_support.
  ///
  /// In en, this message translates to:
  /// **'Wear OS support'**
  String get s_wear_os_support;

  /// No description provided for @wearSyncNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Synchronize with watch'**
  String get wearSyncNotificationTitle;

  /// No description provided for @wearSyncNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Keep watch\'s data in sync'**
  String get wearSyncNotificationText;

  /// No description provided for @wear_sync_with_phone.
  ///
  /// In en, this message translates to:
  /// **'Open the mobile app to sync'**
  String get wear_sync_with_phone;

  /// No description provided for @wear_syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get wear_syncing;

  /// No description provided for @la_privacy_header.
  ///
  /// In en, this message translates to:
  /// **'Live Activity privacy policy'**
  String get la_privacy_header;

  /// No description provided for @la_privacy_intro.
  ///
  /// In en, this message translates to:
  /// **'We have to store and process certain data for use in the Live Activity function. Please, read the disclosure below.'**
  String get la_privacy_intro;

  /// No description provided for @la_privacy_section1_title.
  ///
  /// In en, this message translates to:
  /// **'What data do we store?'**
  String get la_privacy_section1_title;

  /// No description provided for @la_privacy_section1_body.
  ///
  /// In en, this message translates to:
  /// **'For the Live Activity to function, we store the below data with your device identifier:\n\n• Device Identifier (UUID)\n• Device token\n• Live Activity push token\n• APNs push token\n• Device hash\n• Language setting\n• Bell delay\n\nYour timetable data (lessons table) contains the following:\n• The subject and time of the lesson\n• The name of the teacher\n• The name of the classroom\n• Period number of the lesson\n• The topic of the lesson\n• Details of a substitution\n• Indication of dismissed lesson\n\nThe scheduled notifications (scheduled_notifications table) contains the following:\n• Identifier\n• Device identifier\n• Scheduled time\n• Status and time of notification\n• Time of creation and update'**
  String get la_privacy_section1_body;

  /// No description provided for @la_privacy_section2_title.
  ///
  /// In en, this message translates to:
  /// **'How do we protect your data?'**
  String get la_privacy_section2_title;

  /// No description provided for @la_privacy_section2_body.
  ///
  /// In en, this message translates to:
  /// **'We take the security of your data seriously:\n\n• The data in the \"devices\" and \"lessons\" tables are encrypted\n• We store the data on secure servers\n• We only store data for as long as we need it'**
  String get la_privacy_section2_body;

  /// No description provided for @la_privacy_section3_title.
  ///
  /// In en, this message translates to:
  /// **'How long do we store data for?'**
  String get la_privacy_section3_title;

  /// No description provided for @la_privacy_section3_body.
  ///
  /// In en, this message translates to:
  /// **'We store data for the least amount of time possible:\n\n• Live Activity push token: Only stored as long as you have lessons on the given day (including the 2-hour period before). If you don\'t have any lessons left, the value becomes zero.\n\n• Timetable data: Only stored for the length of the lessons and they\'re deleted automatically. On Fridays, the table containing the timetable will be completely empty after the last lesson.\n\n• Device data (token, identifiers): Stored for as long as the Live Activity function is enabled. This data gets deleted when disabling the function.'**
  String get la_privacy_section3_body;

  /// No description provided for @la_privacy_section4_title.
  ///
  /// In en, this message translates to:
  /// **'What do we use the data for?'**
  String get la_privacy_section4_title;

  /// No description provided for @la_privacy_section4_body.
  ///
  /// In en, this message translates to:
  /// **'We use the data exclusively for the Live Activity function:\n\n• Displaying a live timetable on your lockscreen\n• Sending push notifications when lessons change\n• Synchronizing the timetable on your device\n• Ensuring the Monday morning notifications get delivered even after the weekly database-clearing.\n\nWe don\'t share your data with third parties and we don\'t use them for marketing.'**
  String get la_privacy_section4_body;

  /// No description provided for @la_privacy_section5_title.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get la_privacy_section5_title;

  /// No description provided for @la_privacy_section5_body.
  ///
  /// In en, this message translates to:
  /// **'Under the GDPR, you have the following rights:\n\n• Right of access: You can view the type of data stored in this privacy policy.\n• Right to erasure: By disabling the Live Activity function, all data related to the function (device identifiers, timetable) will be immediately and permanently deleted from our servers.\n• Right to modification: The timetable data is modified in the Kréta system by authorized persons (e.g. teachers).\n• Right to object: You can object to data processing at any time by disabling the Live Activity function.'**
  String get la_privacy_section5_body;

  /// No description provided for @la_privacy_footer.
  ///
  /// In en, this message translates to:
  /// **'This privacy policy was last updated on: November 2025'**
  String get la_privacy_footer;

  /// No description provided for @la_privacy_contact.
  ///
  /// In en, this message translates to:
  /// **'Do you have any questions? Contact us at support@firka.app.'**
  String get la_privacy_contact;

  /// No description provided for @la_privacy_summary1.
  ///
  /// In en, this message translates to:
  /// **'Device tokens, Live Activity tokens, timetable data'**
  String get la_privacy_summary1;

  /// No description provided for @la_privacy_summary2.
  ///
  /// In en, this message translates to:
  /// **'Encrypted storage, secure servers'**
  String get la_privacy_summary2;

  /// No description provided for @la_privacy_summary3.
  ///
  /// In en, this message translates to:
  /// **'Data is automatically deleted when it is no longer needed.'**
  String get la_privacy_summary3;

  /// No description provided for @la_title.
  ///
  /// In en, this message translates to:
  /// **'Live Activity'**
  String get la_title;

  /// No description provided for @la_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your schedule live on your device\'s lock screen'**
  String get la_subtitle;

  /// No description provided for @la_privacy_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get la_privacy_title;

  /// No description provided for @la_privacy_required.
  ///
  /// In en, this message translates to:
  /// **'To use Live Activity you must accept the privacy policy'**
  String get la_privacy_required;

  /// No description provided for @la_learn_more.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get la_learn_more;

  /// No description provided for @la_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get la_accept;

  /// No description provided for @la_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get la_decline;

  /// No description provided for @runningInDomainBrowser.
  ///
  /// In en, this message translates to:
  /// **'Domain Böngésző'**
  String get runningInDomainBrowser;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @view_day_btn.
  ///
  /// In en, this message translates to:
  /// **'View day'**
  String get view_day_btn;

  /// No description provided for @omission.
  ///
  /// In en, this message translates to:
  /// **'Absence'**
  String get omission;

  /// No description provided for @omissions.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get omissions;

  /// No description provided for @omission_state_excused.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get omission_state_excused;

  /// No description provided for @omission_state_unexcused.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get omission_state_unexcused;

  /// No description provided for @omission_state_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get omission_state_pending;

  /// No description provided for @omissions_count.
  ///
  /// In en, this message translates to:
  /// **'{state, select, unexcused{{count} igazolatlan} pending{{count} igazolandó} other{{count}}} hiányzás'**
  String omissions_count(String state, int count);

  /// No description provided for @s_beta_warning.
  ///
  /// In en, this message translates to:
  /// **'Beta warning'**
  String get s_beta_warning;

  /// No description provided for @s_ag_privacy_ever_declined.
  ///
  /// In en, this message translates to:
  /// **'Privacy previously declined'**
  String get s_ag_privacy_ever_declined;

  /// No description provided for @s_c_my_themes.
  ///
  /// In en, this message translates to:
  /// **'My themes'**
  String get s_c_my_themes;

  /// No description provided for @s_c_manage_subjects.
  ///
  /// In en, this message translates to:
  /// **'Manage subjects'**
  String get s_c_manage_subjects;

  /// No description provided for @s_c_change_app_icon.
  ///
  /// In en, this message translates to:
  /// **'Change app icon'**
  String get s_c_change_app_icon;

  /// No description provided for @s_c_colors_header.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get s_c_colors_header;

  /// No description provided for @s_c_grade_colors_header.
  ///
  /// In en, this message translates to:
  /// **'Grade colors'**
  String get s_c_grade_colors_header;

  /// No description provided for @s_c_colors_theme_header.
  ///
  /// In en, this message translates to:
  /// **'Colors & Theme'**
  String get s_c_colors_theme_header;

  /// No description provided for @s_c_slot_accent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get s_c_slot_accent;

  /// No description provided for @s_c_slot_background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get s_c_slot_background;

  /// No description provided for @s_c_slot_cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get s_c_slot_cards;

  /// No description provided for @s_c_slot_buttons.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get s_c_slot_buttons;

  /// No description provided for @s_c_mode_both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get s_c_mode_both;

  /// No description provided for @s_c_slot_secondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get s_c_slot_secondary;

  /// No description provided for @s_c_slot_text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get s_c_slot_text;

  /// No description provided for @s_c_slot_text_secondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary text'**
  String get s_c_slot_text_secondary;

  /// No description provided for @s_c_slot_text_tertiary.
  ///
  /// In en, this message translates to:
  /// **'Tertiary text'**
  String get s_c_slot_text_tertiary;

  /// No description provided for @s_c_slot_shadow.
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get s_c_slot_shadow;

  /// No description provided for @s_c_slot_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get s_c_slot_success;

  /// No description provided for @s_c_slot_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get s_c_slot_warning;

  /// No description provided for @s_c_slot_warning_text.
  ///
  /// In en, this message translates to:
  /// **'Warning text'**
  String get s_c_slot_warning_text;

  /// No description provided for @s_c_slot_warning_card.
  ///
  /// In en, this message translates to:
  /// **'Warning card'**
  String get s_c_slot_warning_card;

  /// No description provided for @s_c_slot_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get s_c_slot_error;

  /// No description provided for @s_c_slot_error_text.
  ///
  /// In en, this message translates to:
  /// **'Error text'**
  String get s_c_slot_error_text;

  /// No description provided for @s_c_slot_error_card.
  ///
  /// In en, this message translates to:
  /// **'Error card'**
  String get s_c_slot_error_card;

  /// No description provided for @s_c_title_style_header.
  ///
  /// In en, this message translates to:
  /// **'Title style'**
  String get s_c_title_style_header;

  /// No description provided for @s_c_title_weight_header.
  ///
  /// In en, this message translates to:
  /// **'Title weight'**
  String get s_c_title_weight_header;

  /// No description provided for @s_c_title_weight_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Not all fonts support this'**
  String get s_c_title_weight_subtitle;

  /// No description provided for @s_c_title_weight_thin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get s_c_title_weight_thin;

  /// No description provided for @s_c_title_weight_thick.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get s_c_title_weight_thick;

  /// No description provided for @s_c_capitalization_header.
  ///
  /// In en, this message translates to:
  /// **'Capitalization'**
  String get s_c_capitalization_header;

  /// No description provided for @s_c_capitalization_lower.
  ///
  /// In en, this message translates to:
  /// **'lowercase'**
  String get s_c_capitalization_lower;

  /// No description provided for @s_c_capitalization_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get s_c_capitalization_normal;

  /// No description provided for @s_c_capitalization_upper.
  ///
  /// In en, this message translates to:
  /// **'UPPERCASE'**
  String get s_c_capitalization_upper;

  /// No description provided for @s_c_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get s_c_change;

  /// No description provided for @s_c_customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get s_c_customize;

  /// No description provided for @s_c_themes_current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get s_c_themes_current;

  /// No description provided for @s_c_themes_own.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get s_c_themes_own;

  /// No description provided for @s_c_themes_downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get s_c_themes_downloaded;

  /// No description provided for @s_c_themes_share_current.
  ///
  /// In en, this message translates to:
  /// **'Share current theme'**
  String get s_c_themes_share_current;

  /// No description provided for @s_c_themes_create_new.
  ///
  /// In en, this message translates to:
  /// **'Create new theme'**
  String get s_c_themes_create_new;

  /// No description provided for @s_c_themes_import.
  ///
  /// In en, this message translates to:
  /// **'Import theme'**
  String get s_c_themes_import;

  /// No description provided for @s_c_themes_use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get s_c_themes_use;

  /// No description provided for @s_c_themes_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get s_c_themes_continue;

  /// No description provided for @s_c_themes_own_label.
  ///
  /// In en, this message translates to:
  /// **'My theme'**
  String get s_c_themes_own_label;

  /// No description provided for @s_c_themes_imported_label.
  ///
  /// In en, this message translates to:
  /// **'Imported theme'**
  String get s_c_themes_imported_label;

  /// No description provided for @s_c_themes_builtin_label.
  ///
  /// In en, this message translates to:
  /// **'Built-in theme'**
  String get s_c_themes_builtin_label;

  /// No description provided for @s_c_themes_builtin_name.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get s_c_themes_builtin_name;

  /// No description provided for @s_c_themes_create_title.
  ///
  /// In en, this message translates to:
  /// **'Create new theme'**
  String get s_c_themes_create_title;

  /// No description provided for @s_c_themes_create_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the theme'**
  String get s_c_themes_create_subtitle;

  /// No description provided for @s_c_themes_create_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get s_c_themes_create_placeholder;

  /// No description provided for @s_c_themes_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete theme'**
  String get s_c_themes_delete_title;

  /// No description provided for @s_c_themes_delete_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this theme? This action can be undone.'**
  String get s_c_themes_delete_subtitle;

  /// No description provided for @s_c_themes_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get s_c_themes_delete_confirm;

  /// No description provided for @s_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get s_about;

  /// No description provided for @s_extras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get s_extras;

  /// No description provided for @s_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get s_other;

  /// No description provided for @grade_weight_x1.
  ///
  /// In en, this message translates to:
  /// **'single weight'**
  String get grade_weight_x1;

  /// No description provided for @grade_weight_x2.
  ///
  /// In en, this message translates to:
  /// **'double weight'**
  String get grade_weight_x2;

  /// No description provided for @grade_weight_x3.
  ///
  /// In en, this message translates to:
  /// **'triple weight'**
  String get grade_weight_x3;

  /// No description provided for @grade_weight_x4.
  ///
  /// In en, this message translates to:
  /// **'quadruple weight'**
  String get grade_weight_x4;

  /// No description provided for @grade_weight_x5.
  ///
  /// In en, this message translates to:
  /// **'quintuple weight'**
  String get grade_weight_x5;

  /// No description provided for @grade_weight_percent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% weight'**
  String grade_weight_percent(int percent);

  /// No description provided for @surprise_grade_rank_5.
  ///
  /// In en, this message translates to:
  /// **'LEGENDARY'**
  String get surprise_grade_rank_5;

  /// No description provided for @surprise_grade_rank_4.
  ///
  /// In en, this message translates to:
  /// **'EXCELLENT'**
  String get surprise_grade_rank_4;

  /// No description provided for @surprise_grade_rank_3.
  ///
  /// In en, this message translates to:
  /// **'OKAY'**
  String get surprise_grade_rank_3;

  /// No description provided for @surprise_grade_rank_2.
  ///
  /// In en, this message translates to:
  /// **'WEAK'**
  String get surprise_grade_rank_2;

  /// No description provided for @surprise_grade_rank_1.
  ///
  /// In en, this message translates to:
  /// **'CATASTROPHE'**
  String get surprise_grade_rank_1;

  /// No description provided for @new_grades_card.
  ///
  /// In en, this message translates to:
  /// **'You have new grades'**
  String get new_grades_card;

  /// No description provided for @s_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get s_notifications;

  /// No description provided for @s_sticker_map.
  ///
  /// In en, this message translates to:
  /// **'Sticker map'**
  String get s_sticker_map;

  /// No description provided for @s_qr_reader.
  ///
  /// In en, this message translates to:
  /// **'QR code reader'**
  String get s_qr_reader;

  /// No description provided for @s_feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get s_feedback;

  /// No description provided for @s_a_desc.
  ///
  /// In en, this message translates to:
  /// **'Navigation, language, bell, rounding'**
  String get s_a_desc;

  /// No description provided for @s_c_desc.
  ///
  /// In en, this message translates to:
  /// **'Grade colors, theme, app icon'**
  String get s_c_desc;

  /// No description provided for @s_todo.
  ///
  /// In en, this message translates to:
  /// **'túdú: program this'**
  String get s_todo;

  /// No description provided for @s_surprise_grades.
  ///
  /// In en, this message translates to:
  /// **'Surprise grades'**
  String get s_surprise_grades;

  /// No description provided for @s_seasonal_icons.
  ///
  /// In en, this message translates to:
  /// **'Seasonal app icons'**
  String get s_seasonal_icons;

  /// No description provided for @s_uwu_mode.
  ///
  /// In en, this message translates to:
  /// **'UwU mode'**
  String get s_uwu_mode;

  /// No description provided for @s_calendar_sync.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync'**
  String get s_calendar_sync;

  /// No description provided for @s_save_grades.
  ///
  /// In en, this message translates to:
  /// **'Save grades'**
  String get s_save_grades;

  /// No description provided for @s_welcome_msg.
  ///
  /// In en, this message translates to:
  /// **'Welcome message'**
  String get s_welcome_msg;

  /// No description provided for @s_extras_desc.
  ///
  /// In en, this message translates to:
  /// **'Surprise grades, calendar sync'**
  String get s_extras_desc;

  /// No description provided for @s_notifications_desc.
  ///
  /// In en, this message translates to:
  /// **'Grades, timetable changes, absences'**
  String get s_notifications_desc;

  /// No description provided for @s_notif_push_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enable push notifications'**
  String get s_notif_push_enabled;

  /// No description provided for @s_notif_delivery_method_header.
  ///
  /// In en, this message translates to:
  /// **'Delivery method'**
  String get s_notif_delivery_method_header;

  /// No description provided for @s_notif_delivery_auto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get s_notif_delivery_auto;

  /// No description provided for @s_notif_delivery_fcm.
  ///
  /// In en, this message translates to:
  /// **'Firebase Cloud Messaging (FCM)'**
  String get s_notif_delivery_fcm;

  /// No description provided for @s_notif_delivery_alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm (background check)'**
  String get s_notif_delivery_alarm;

  /// No description provided for @s_notif_wakeup_interval_header.
  ///
  /// In en, this message translates to:
  /// **'Check frequency'**
  String get s_notif_wakeup_interval_header;

  /// No description provided for @s_notif_wakeup_hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get s_notif_wakeup_hourly;

  /// No description provided for @s_notif_wakeup_two_hourly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours'**
  String get s_notif_wakeup_two_hourly;

  /// No description provided for @s_notif_categories_header.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get s_notif_categories_header;

  /// No description provided for @s_notif_grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get s_notif_grades;

  /// No description provided for @s_notif_homework_tests.
  ///
  /// In en, this message translates to:
  /// **'Homework & tests'**
  String get s_notif_homework_tests;

  /// No description provided for @s_notif_absences.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get s_notif_absences;

  /// No description provided for @s_notif_lessons.
  ///
  /// In en, this message translates to:
  /// **'Lesson changes'**
  String get s_notif_lessons;

  /// No description provided for @s_notif_lessons_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled lessons'**
  String get s_notif_lessons_cancelled;

  /// No description provided for @s_notif_lessons_substituted.
  ///
  /// In en, this message translates to:
  /// **'Substitutions'**
  String get s_notif_lessons_substituted;

  /// No description provided for @s_notif_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get s_notif_messages;

  /// No description provided for @s_progress_notification.
  ///
  /// In en, this message translates to:
  /// **'Progress-centric notification'**
  String get s_progress_notification;

  /// No description provided for @s_progress_notification_desc.
  ///
  /// In en, this message translates to:
  /// **'Live progress notification for lessons and breaks throughout the school day'**
  String get s_progress_notification_desc;

  /// No description provided for @progress_notif_channel_name.
  ///
  /// In en, this message translates to:
  /// **'School day progress'**
  String get progress_notif_channel_name;

  /// No description provided for @progress_notif_channel_desc.
  ///
  /// In en, this message translates to:
  /// **'Live progress notification for today\'s lessons and breaks'**
  String get progress_notif_channel_desc;

  /// No description provided for @progress_notif_lesson_title.
  ///
  /// In en, this message translates to:
  /// **'Lesson {number}: {name}'**
  String progress_notif_lesson_title(String number, String name);

  /// No description provided for @progress_notif_substitution.
  ///
  /// In en, this message translates to:
  /// **' (Substitution)'**
  String get progress_notif_substitution;

  /// No description provided for @progress_notif_case1_text.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} min ({timeRange}){room}{substitution}{remaining}'**
  String progress_notif_case1_text(String minutes, String timeRange, String room, String substitution, String remaining);

  /// No description provided for @progress_notif_case2_lesson_text.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left ({timeRange}){room}{substitution}{remaining}'**
  String progress_notif_case2_lesson_text(String minutes, String timeRange, String room, String substitution, String remaining);

  /// No description provided for @progress_notif_case2_break_title.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get progress_notif_case2_break_title;

  /// No description provided for @progress_notif_case2_break_text.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left{remaining}'**
  String progress_notif_case2_break_text(String minutes, String remaining);

  /// No description provided for @progress_notif_critical_text.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String progress_notif_critical_text(String minutes);

  /// No description provided for @progress_notif_remaining_lessons_one.
  ///
  /// In en, this message translates to:
  /// **' - 1 lesson remaining'**
  String get progress_notif_remaining_lessons_one;

  /// No description provided for @progress_notif_remaining_lessons_other.
  ///
  /// In en, this message translates to:
  /// **' - {count} lessons remaining'**
  String progress_notif_remaining_lessons_other(String count);

  /// No description provided for @s_fcm_status_title.
  ///
  /// In en, this message translates to:
  /// **'FCM status'**
  String get s_fcm_status_title;

  /// No description provided for @s_fcm_status_initialized.
  ///
  /// In en, this message translates to:
  /// **'Initialized'**
  String get s_fcm_status_initialized;

  /// No description provided for @s_fcm_status_not_initialized.
  ///
  /// In en, this message translates to:
  /// **'Not initialized'**
  String get s_fcm_status_not_initialized;

  /// No description provided for @s_fcm_status_token_present.
  ///
  /// In en, this message translates to:
  /// **'Token present'**
  String get s_fcm_status_token_present;

  /// No description provided for @s_fcm_status_token_missing.
  ///
  /// In en, this message translates to:
  /// **'No token'**
  String get s_fcm_status_token_missing;

  /// No description provided for @s_fcm_status_permission_label.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get s_fcm_status_permission_label;

  /// No description provided for @s_fcm_status_permission_granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get s_fcm_status_permission_granted;

  /// No description provided for @s_fcm_status_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get s_fcm_status_permission_denied;

  /// No description provided for @s_fcm_status_permission_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get s_fcm_status_permission_unknown;

  /// No description provided for @s_fcm_status_topic_label.
  ///
  /// In en, this message translates to:
  /// **'Subscribed topic'**
  String get s_fcm_status_topic_label;

  /// No description provided for @s_fcm_status_last_refresh_label.
  ///
  /// In en, this message translates to:
  /// **'Last token refresh'**
  String get s_fcm_status_last_refresh_label;

  /// No description provided for @s_fcm_status_last_refresh_never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get s_fcm_status_last_refresh_never;

  /// No description provided for @s_fcm_status_refresh_button.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get s_fcm_status_refresh_button;

  /// No description provided for @s_fcm_notify_on_message.
  ///
  /// In en, this message translates to:
  /// **'Notify on FCM message'**
  String get s_fcm_notify_on_message;

  /// No description provided for @s_fcm_test_notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Test notifications'**
  String get s_fcm_test_notifications_title;

  /// No description provided for @s_fcm_test_notifications_multi_title.
  ///
  /// In en, this message translates to:
  /// **'Simulate multi-account'**
  String get s_fcm_test_notifications_multi_title;

  /// No description provided for @s_n_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get s_n_all;

  /// No description provided for @s_n_grades.
  ///
  /// In en, this message translates to:
  /// **'New grades'**
  String get s_n_grades;

  /// No description provided for @s_n_homework_tests.
  ///
  /// In en, this message translates to:
  /// **'Homework & Tests'**
  String get s_n_homework_tests;

  /// No description provided for @s_n_absences.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get s_n_absences;

  /// No description provided for @s_n_lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get s_n_lessons;

  /// No description provided for @s_n_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get s_n_messages;

  /// No description provided for @s_n_by_subject.
  ///
  /// In en, this message translates to:
  /// **'By subject'**
  String get s_n_by_subject;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'hu', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'hu': return AppLocalizationsHu();
    case 'pl': return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
