// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get restart_title => 'Restart application';

  @override
  String get restart_body => 'Click here to open the app again.';

  @override
  String get loginBtn => 'Login with E-Kréta';

  @override
  String get privacyLabel => 'Privacy policy';

  @override
  String get title1 => 'Know everything at a glance';

  @override
  String get subtitle1 => 'You can see useful info about your day on the top of your home screen.';

  @override
  String get title2 => 'Your classes fit here comfortably';

  @override
  String get subtitle2 => 'See statistics, upcoming tests, and even your grades from previous school years.';

  @override
  String get title3 => 'Customizable timetable';

  @override
  String get subtitle3 => 'Decide what you want to see on your timetable page. Turn tests, assignments, breaks, and even free periods on or off.';

  @override
  String get title4 => 'Many extras you will never find in Kréta';

  @override
  String get subtitle4 => '';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get debug_screen => 'Developer options';

  @override
  String get settings_screen => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get grades => 'Grades';

  @override
  String get timetable => 'Timetable';

  @override
  String get other => 'Other';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get reauth => 'Reauthentication required';

  @override
  String get api_error => 'Kréta API error';

  @override
  String get pairing => 'Pair your watch';

  @override
  String get pairing_description => 'Would you like to pair this watch with the Firka app?\nAfter pairing, you will be able to see your timetable, new grades, tests and tasks.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get okay => 'Okay';

  @override
  String get pair => 'Pair';

  @override
  String get beta_title => 'Firka - Public Beta';

  @override
  String get beta_body => 'The application is still in development; some features may be unfinished, not work correctly, or be buggy.';

  @override
  String good_morning(String p) {
    return 'Good morning, $p!';
  }

  @override
  String good_day(String p) {
    return 'Good day, $p!';
  }

  @override
  String n_left_subtitle(num n) {
    return 'Hang in there, there\'s only $n lessons left!';
  }

  @override
  String get suffering_almost_over_subtitle => 'You\'re almost free. Keep paying attention to your teacher.';

  @override
  String school_ending(String p) {
    return 'Are you anxious, $p?';
  }

  @override
  String get tomorrow_subtitle => 'Your next day';

  @override
  String good_afternoon(String p) {
    return 'Good afternoon, $p!';
  }

  @override
  String good_night(String p) {
    return 'Good evening, $p!';
  }

  @override
  String get starting_soon => 'Your first lesson will start soon!';

  @override
  String get starting_hour => 'hour';

  @override
  String get starting_hour_plural => 'hours';

  @override
  String get starting_min => 'min';

  @override
  String get starting_min_plural => 'mins';

  @override
  String get starting_sec => 'sec';

  @override
  String get starting_sec_plural => 'secs';

  @override
  String get subjects => 'Subjects';

  @override
  String get your_subjects => 'Your Subjects';

  @override
  String get data => 'Info';

  @override
  String get subject_avg => 'Subject average';

  @override
  String get subject_avg_rounded => 'Subject average after rounding';

  @override
  String get class_avg => 'Class average';

  @override
  String get class_n => 'Weekly lesson number';

  @override
  String get tt_no_classes_l1 => 'You don\'t have any lessons on this day!';

  @override
  String get tt_no_classes_l2 => 'Yippee!';

  @override
  String get class_dismissed => 'Dismissed lesson';

  @override
  String get catalog_lesson_btn => 'Catalog lesson';

  @override
  String get catalog_lesson_title => 'Catalog lesson';

  @override
  String get catalog_lesson_topic_hint => 'Topic covered';

  @override
  String get catalog_lesson_submit_btn => 'Save';

  @override
  String get class_substitution => 'Substitution';

  @override
  String get lesson_subject => 'Lesson subject';

  @override
  String get tt_settings_toast => 'Timetable settings';

  @override
  String get tt_settings_toast_lesson_nos => 'Number of lessons';

  @override
  String get tt_settings_toast_lesson_tests => 'Tests & others';

  @override
  String get tt_settings_toast_lesson_breaks => 'Breaks';

  @override
  String get a_week => 'A week';

  @override
  String get b_week => 'B week';

  @override
  String get stats_date => 'Date';

  @override
  String get stats_created_at => 'Created at';

  @override
  String get stats_last_mod => 'Last modified';

  @override
  String get s_developer => 'Developer settings';

  @override
  String get s_stats_for_nerds => 'Stats for nerds';

  @override
  String get s_settings => 'Settings';

  @override
  String get s_a => 'Application';

  @override
  String get s_ag => 'General';

  @override
  String get s_ag_bell_delay => 'Bell delay';

  @override
  String get s_ag_rounding => 'Default rounding';

  @override
  String get s_shortened_timetable => 'Shortened timetable';

  @override
  String get s_shortened_timetable_enable => 'Enable shortened timetable';

  @override
  String get s_shortened_timetable_start => 'Starts';

  @override
  String get s_shortened_timetable_end => 'Ends';

  @override
  String get s_shortened_timetable_no_lessons => 'No lessons to show in the cache. Refresh the timetable and try again.';

  @override
  String get s_shortened_timetable_reset => 'Reset to original times';

  @override
  String get s_shortened_timetable_invalid_time => 'The end must be after the start';

  @override
  String s_shortened_timetable_lesson(int n) {
    return 'Lesson $n';
  }

  @override
  String get s_customization => 'Customization';

  @override
  String get s_ag_r1 => '1 → 2';

  @override
  String get s_ag_r2 => '2 → 3';

  @override
  String get s_ag_r3 => '3 → 4';

  @override
  String get s_ag_r4 => '4 → 5';

  @override
  String get s_ag_class_avg_on_graph => 'Class\'s average on the graph';

  @override
  String get s_ag_navbar => 'Navbar';

  @override
  String get s_ag_left_handed_mode => 'Left-handed mode';

  @override
  String get s_ag_language_header => 'Language';

  @override
  String get s_ag_language_auto => 'Automatic';

  @override
  String get s_ag_language_hu => 'Hungarian';

  @override
  String get s_ag_language_en => 'English';

  @override
  String get s_ag_language_de => 'German';

  @override
  String get s_c => 'Customization';

  @override
  String get s_c_icon_header => 'App icons';

  @override
  String get s_c_replace_icon => 'Replace icon';

  @override
  String get s_ci_icon_header => 'App icon';

  @override
  String get s_ci_warning_header => '[!] Changing the app\'s icon in debug mode won\'t work';

  @override
  String get s_ci_icon_subtitle => 'Choose a pretty app icon if you\'re already tired of the green one.';

  @override
  String get s_ci_icon_g1 => 'Catboy domain';

  @override
  String get s_ci_icon_g2 => 'Felt pen';

  @override
  String get s_ci_icon_g3 => 'Nostalgia';

  @override
  String get s_ci_icon_g4 => 'Reimagined';

  @override
  String get s_ci_icon_g5 => 'Reference';

  @override
  String get s_ci_icon_g6 => 'Christmas logo competition 2024';

  @override
  String get s_ci_icon_g6_desc => 'By @emilia6_6';

  @override
  String get s_ci_icon_g7 => 'Pride';

  @override
  String get s_ci_icon_g8 => 'Pride ';

  @override
  String get s_c_theme_header => 'Theme';

  @override
  String get s_c_theme_auto => 'Auto';

  @override
  String get s_c_theme_light => 'Light';

  @override
  String get s_c_theme_dark => 'Dark';

  @override
  String get s_ci_child_protection => 'Child protection';

  @override
  String get ic_ace => 'Asexual';

  @override
  String get ic_ace_f => 'Asexual';

  @override
  String get ic_bi => 'Bisexual';

  @override
  String get ic_bi_f => 'Bisexual';

  @override
  String get ic_cactus => 'Cactus grove';

  @override
  String get ic_cc => 'Creative Cloud';

  @override
  String get ic_enby => 'Non-binary';

  @override
  String get ic_enby_f => 'Non-binary';

  @override
  String get ic_fidesz => 'Fidesz';

  @override
  String get ic_filc => 'Firka';

  @override
  String get ic_filco => 'Filc . O';

  @override
  String get ic_galaxy => 'Galaxy';

  @override
  String get ic_gay => 'Gay';

  @override
  String get ic_gay_f => 'Gay';

  @override
  String get ic_half_firka_2 => 'Revolution';

  @override
  String get ic_kreta => 'eFirka';

  @override
  String get ic_lesb => 'Lesbian';

  @override
  String get ic_lesb_f => 'Lesbian';

  @override
  String get ic_lgbtq => 'LGBTQ+';

  @override
  String get ic_lgbtq_f => 'LGBTQ+';

  @override
  String get ic_lgbtqp => 'Progression';

  @override
  String get ic_lgbtqp_f => 'Progression';

  @override
  String get ic_lidl => 'Shopping';

  @override
  String get ic_mkkp => 'Free grades';

  @override
  String get ic_nuke => 'Nuclear';

  @override
  String get ic_modern => 'Modern';

  @override
  String get ic_o1g => 'Orbán is a cunt';

  @override
  String get ic_old => 'Domain Dave';

  @override
  String get ic_original => 'Original';

  @override
  String get ic_paper => 'Paper';

  @override
  String get ic_pear => 'Pear';

  @override
  String get ic_pixel => 'Pixel';

  @override
  String get ic_pixelized => 'Pixelified';

  @override
  String get ic_pride => 'Space rainbow';

  @override
  String get ic_proto => 'Prototype';

  @override
  String get ic_refilc => 'reFilc';

  @override
  String get ic_refulc => 'firk\'a';

  @override
  String get ic_repont => 'Repont';

  @override
  String get ic_szivacs => 'sponge';

  @override
  String get ic_tisza => 'árad a firka';

  @override
  String get ic_trans => 'Trans';

  @override
  String get ic_trans_f => 'Trans';

  @override
  String get ic_void_icon => 'Nothing';

  @override
  String get ic_xmas1 => 'naughty list';

  @override
  String get ic_xmas2 => 'gift';

  @override
  String get ic_xmas3 => 'FirCristmas';

  @override
  String get wear_phone_unpaired => 'Your watch isn\'t paired with your phone!';

  @override
  String get wear_phone_disconnected => 'Your watch isn\'t connected to your phone!';

  @override
  String get wear_pairing_request_sent => 'Open the app on your phone';

  @override
  String get wear_pairing_check_phone => 'Check your phone';

  @override
  String get wear_try_again => 'Try again';

  @override
  String get breakTxt => 'Break';

  @override
  String get empty_class => 'Empty class';

  @override
  String timeLeft(num mins) {
    String _temp0 = intl.Intl.pluralLogic(
      mins,
      locale: localeName,
      other: '$mins mins left',
      one: '1 min left',
    );
    return '$_temp0';
  }

  @override
  String get noClasses => 'School\'s out today, take it easy!';

  @override
  String get noMoreClasses => 'No more classes for you today';

  @override
  String firstIn(String t) {
    return 'First class in: $t';
  }

  @override
  String wearTitle(num n) {
    return '$n. class';
  }

  @override
  String get licensesLabel => 'Licenses';

  @override
  String get licenseDescription => 'Licenses for external libraries used by the application';

  @override
  String get view_subject_btn => 'View subject';

  @override
  String get date => 'Time of the class';

  @override
  String get tt_settings_toast_lesson_substitution => 'Substitutions';

  @override
  String get tt_settings_toast_lesson_ab_timetable => 'Two-week class schedule';

  @override
  String get s_ag_navbar_desc => 'Choose which items appear in the navigation bar and arrange them. The other pages are accessible via the “More” button. You can display up to 4 pages.';

  @override
  String get s_ag_navbar_home => 'Home';

  @override
  String get s_ag_navbar_visible => 'Appears';

  @override
  String happy_birthday(String p) {
    return 'Happy birthday, $p!';
  }

  @override
  String tests_tomorrow(String tests) {
    return 'You\'ll have $tests exams';
  }

  @override
  String get no_tests_tomorrow => 'You don\'t have any exams tomorrow';

  @override
  String get get_ready => 'Relax, and prepare for tomorrow';

  @override
  String get homework => 'Homework';

  @override
  String get mark_as_done => 'Mark as finished';

  @override
  String get mark_as_not_done => 'Mark as unfinished';

  @override
  String get grade_teacherName => 'Teacher\'s name: ';

  @override
  String get grade_strValue => 'Text-based rating: ';

  @override
  String get no_grades => 'You don\'t have any grades for this subject yet.';

  @override
  String get unknown_teacher => 'Unknown teacher';

  @override
  String get tt_added => 'Created at: ';

  @override
  String get view_lesson_btn => 'View lesson';

  @override
  String get s_ag_navbar_hidden => 'Hidden';

  @override
  String get s_your_account => 'Your account';

  @override
  String get s_acc_kreta => 'eKRÉTA accounts';

  @override
  String get s_acc_accounts => 'Accounts';

  @override
  String get s_neptun_title => 'ELTE Neptun';

  @override
  String get s_neptun_user_hint => 'ID (e.g. abc123)';

  @override
  String get s_neptun_password_hint => 'Password';

  @override
  String get s_neptun_totp_code_hint => 'Enter the 6-digit code';

  @override
  String get s_neptun_code_by_email => 'code sent by e-mail';

  @override
  String get s_neptun_confirm_code => 'Confirm code';

  @override
  String get s_neptun_login_btn => 'Log in';

  @override
  String get s_neptun_seed_hint => 'Authenticator key (optional)';

  @override
  String get s_neptun_seed_help => 'Enter your 2FA authenticator\'s secret key. NOT the 6 digit code.';

  @override
  String get s_neptun_login_with_elte => 'Log in with ELTE Neptun';

  @override
  String get s_neptun_seed_failed => 'Automatic 2FA code generation failed — check your authenticator key.';

  @override
  String get s_neptun_2fa_rejected => '2FA code rejected — if the code is correct, restart the login and enter a fresh code.';

  @override
  String get s_neptun_login_failed => 'Login failed';

  @override
  String get s_acc_add => 'Add new student account';

  @override
  String get s_acc_add_teacher => 'Add new teacher account';

  @override
  String get s_acc_logout => 'Log out';

  @override
  String get close => 'Close';

  @override
  String get tt_non_instructional_day => 'Non-instructional workday';

  @override
  String get tt_public_holiday => 'Non-instructional day';

  @override
  String get tt_spring_break => 'Spring break';

  @override
  String get tt_winter_break => 'Winter break';

  @override
  String get tt_autumn_break => 'Autumn break';

  @override
  String get tt_instructional_day => 'Instructional day';

  @override
  String get tt_first_semester_end => 'End of first semester';

  @override
  String get tt_holiday => 'Holiday';

  @override
  String get tt_rest_day => 'Rest day';

  @override
  String get tt_first_instructional_day => 'First instructional day';

  @override
  String get tt_last_instructional_day => 'Last instructional day';

  @override
  String get tt_last_instructional_day_graduates => 'Last instructional day for graduates';

  @override
  String get tt_full_day_trip => 'Full-day trip';

  @override
  String get tt_quarter_end => 'end of quarter';

  @override
  String lessons_tomorrow(String lessons) {
    return 'You\'ll have $lessons lessons';
  }

  @override
  String get subject => 'Subject';

  @override
  String get grade_calculator => 'Grade calculator';

  @override
  String get grade_calculator_add => 'Add';

  @override
  String get ghost_grade => 'Ghost grade';

  @override
  String get ghost_grades => 'Ghost grades';

  @override
  String gradesCount(int count) {
    return '$count grade(s)';
  }

  @override
  String get overall_avg => 'Overall average';

  @override
  String get now => 'Now';

  @override
  String get s_n => 'Notifications';

  @override
  String get s_n_morning => 'Morning notification';

  @override
  String get s_n_morning_time => 'Time of notification before school';

  @override
  String get s_n_live_activity => 'Live Activity';

  @override
  String get s_n_test => 'Send test notification';

  @override
  String get s_wear => 'Wear OS';

  @override
  String get s_wear_os_support => 'Wear OS support';

  @override
  String get wearSyncNotificationTitle => 'Synchronize with watch';

  @override
  String get wearSyncNotificationText => 'Keep watch\'s data in sync';

  @override
  String get wear_sync_with_phone => 'Open the mobile app to sync';

  @override
  String get wear_syncing => 'Syncing...';

  @override
  String get la_privacy_header => 'Live Activity privacy policy';

  @override
  String get la_privacy_intro => 'We have to store and process certain data for use in the Live Activity function. Please, read the disclosure below.';

  @override
  String get la_privacy_section1_title => 'What data do we store?';

  @override
  String get la_privacy_section1_body => 'For the Live Activity to function, we store the below data with your device identifier:\n\n• Device Identifier (UUID)\n• Device token\n• Live Activity push token\n• APNs push token\n• Device hash\n• Language setting\n• Bell delay\n\nYour timetable data (lessons table) contains the following:\n• The subject and time of the lesson\n• The name of the teacher\n• The name of the classroom\n• Period number of the lesson\n• The topic of the lesson\n• Details of a substitution\n• Indication of dismissed lesson\n\nThe scheduled notifications (scheduled_notifications table) contains the following:\n• Identifier\n• Device identifier\n• Scheduled time\n• Status and time of notification\n• Time of creation and update';

  @override
  String get la_privacy_section2_title => 'How do we protect your data?';

  @override
  String get la_privacy_section2_body => 'We take the security of your data seriously:\n\n• The data in the \"devices\" and \"lessons\" tables are encrypted\n• We store the data on secure servers\n• We only store data for as long as we need it';

  @override
  String get la_privacy_section3_title => 'How long do we store data for?';

  @override
  String get la_privacy_section3_body => 'We store data for the least amount of time possible:\n\n• Live Activity push token: Only stored as long as you have lessons on the given day (including the 2-hour period before). If you don\'t have any lessons left, the value becomes zero.\n\n• Timetable data: Only stored for the length of the lessons and they\'re deleted automatically. On Fridays, the table containing the timetable will be completely empty after the last lesson.\n\n• Device data (token, identifiers): Stored for as long as the Live Activity function is enabled. This data gets deleted when disabling the function.';

  @override
  String get la_privacy_section4_title => 'What do we use the data for?';

  @override
  String get la_privacy_section4_body => 'We use the data exclusively for the Live Activity function:\n\n• Displaying a live timetable on your lockscreen\n• Sending push notifications when lessons change\n• Synchronizing the timetable on your device\n• Ensuring the Monday morning notifications get delivered even after the weekly database-clearing.\n\nWe don\'t share your data with third parties and we don\'t use them for marketing.';

  @override
  String get la_privacy_section5_title => 'Your rights';

  @override
  String get la_privacy_section5_body => 'Under the GDPR, you have the following rights:\n\n• Right of access: You can view the type of data stored in this privacy policy.\n• Right to erasure: By disabling the Live Activity function, all data related to the function (device identifiers, timetable) will be immediately and permanently deleted from our servers.\n• Right to modification: The timetable data is modified in the Kréta system by authorized persons (e.g. teachers).\n• Right to object: You can object to data processing at any time by disabling the Live Activity function.';

  @override
  String get la_privacy_footer => 'This privacy policy was last updated on: November 2025';

  @override
  String get la_privacy_contact => 'Do you have any questions? Contact us at support@firka.app.';

  @override
  String get la_privacy_summary1 => 'Device tokens, Live Activity tokens, timetable data';

  @override
  String get la_privacy_summary2 => 'Encrypted storage, secure servers';

  @override
  String get la_privacy_summary3 => 'Data is automatically deleted when it is no longer needed.';

  @override
  String get la_title => 'Live Activity';

  @override
  String get la_subtitle => 'Show your schedule live on your device\'s lock screen';

  @override
  String get la_privacy_title => 'Privacy Policy';

  @override
  String get la_privacy_required => 'To use Live Activity you must accept the privacy policy';

  @override
  String get la_learn_more => 'Learn More';

  @override
  String get la_accept => 'Accept';

  @override
  String get la_decline => 'Decline';

  @override
  String get runningInDomainBrowser => 'Domain Böngésző';

  @override
  String get copied => 'Copied';

  @override
  String get view_day_btn => 'View day';

  @override
  String get omission => 'Absence';

  @override
  String get omissions => 'Absences';

  @override
  String get omission_state_excused => 'Verified';

  @override
  String get omission_state_unexcused => 'Unverified';

  @override
  String get omission_state_pending => 'Pending';

  @override
  String omissions_count(String state, int count) {
    String _temp0 = intl.Intl.selectLogic(
      state,
      {
        'unexcused': '$count igazolatlan',
        'pending': '$count igazolandó',
        'other': '$count',
      },
    );
    return '$_temp0 hiányzás';
  }

  @override
  String get s_beta_warning => 'Beta warning';

  @override
  String get s_ag_privacy_ever_declined => 'Privacy previously declined';

  @override
  String get s_c_tab_appearance => 'Appearance';

  @override
  String get s_c_tab_subjects => 'Subjects';

  @override
  String get s_c_tab_fonts => 'Fonts';

  @override
  String get s_c_my_themes => 'My themes';

  @override
  String get s_c_manage_subjects => 'Manage subjects';

  @override
  String get s_c_change_app_icon => 'Change app icon';

  @override
  String get s_c_colors_header => 'Colors';

  @override
  String get s_c_grade_colors_header => 'Grade colors';

  @override
  String get s_c_colors_theme_header => 'Colors & Theme';

  @override
  String get s_c_slot_accent => 'Accent';

  @override
  String get s_c_slot_background => 'Background';

  @override
  String get s_c_slot_cards => 'Cards';

  @override
  String get s_c_slot_buttons => 'Buttons';

  @override
  String get s_c_mode_both => 'Both';

  @override
  String get s_c_slot_secondary => 'Secondary';

  @override
  String get s_c_slot_text => 'Text';

  @override
  String get s_c_slot_text_secondary => 'Secondary text';

  @override
  String get s_c_slot_text_tertiary => 'Tertiary text';

  @override
  String get s_c_slot_shadow => 'Shadow';

  @override
  String get s_c_slot_success => 'Success';

  @override
  String get s_c_slot_warning => 'Warning';

  @override
  String get s_c_slot_warning_text => 'Warning text';

  @override
  String get s_c_slot_warning_card => 'Warning card';

  @override
  String get s_c_slot_error => 'Error';

  @override
  String get s_c_slot_error_text => 'Error text';

  @override
  String get s_c_slot_error_card => 'Error card';

  @override
  String get s_c_title_style_header => 'Title style';

  @override
  String get s_c_title_weight_header => 'Title weight';

  @override
  String get s_c_title_weight_subtitle => 'Not all fonts support this';

  @override
  String get s_c_title_weight_thin => 'Thin';

  @override
  String get s_c_title_weight_thick => 'Bold';

  @override
  String get s_c_capitalization_header => 'Capitalization';

  @override
  String get s_c_capitalization_lower => 'lowercase';

  @override
  String get s_c_capitalization_normal => 'Normal';

  @override
  String get s_c_capitalization_upper => 'UPPERCASE';

  @override
  String get s_c_change => 'Change';

  @override
  String get s_c_customize => 'Customize';

  @override
  String get s_c_themes_current => 'Current';

  @override
  String get s_c_themes_own => 'Mine';

  @override
  String get s_c_themes_downloaded => 'Downloaded';

  @override
  String get s_c_themes_share_current => 'Share current theme';

  @override
  String get s_c_themes_create_new => 'Create new theme';

  @override
  String get s_c_themes_import => 'Import theme';

  @override
  String get s_c_themes_use => 'Use';

  @override
  String get s_c_themes_continue => 'Continue';

  @override
  String get s_c_themes_own_label => 'My theme';

  @override
  String get s_c_themes_imported_label => 'Imported theme';

  @override
  String get s_c_themes_builtin_label => 'Built-in theme';

  @override
  String get s_c_themes_builtin_name => 'Default';

  @override
  String get s_c_themes_create_title => 'Create new theme';

  @override
  String get s_c_themes_create_subtitle => 'Enter a name for the theme';

  @override
  String get s_c_themes_create_placeholder => 'Theme name';

  @override
  String get s_c_themes_delete_title => 'Delete theme';

  @override
  String get s_c_themes_delete_subtitle => 'Are you sure you want to delete this theme? This action can be undone.';

  @override
  String get s_c_themes_delete_confirm => 'Delete';

  @override
  String get s_about => 'About';

  @override
  String get s_extras => 'Extras';

  @override
  String get s_other => 'Other';

  @override
  String get grade_weight_x1 => 'single weight';

  @override
  String get grade_weight_x2 => 'double weight';

  @override
  String get grade_weight_x3 => 'triple weight';

  @override
  String get grade_weight_x4 => 'quadruple weight';

  @override
  String get grade_weight_x5 => 'quintuple weight';

  @override
  String grade_weight_percent(int percent) {
    return '$percent% weight';
  }

  @override
  String get surprise_grade_rank_5 => 'LEGENDARY';

  @override
  String get surprise_grade_rank_4 => 'EXCELLENT';

  @override
  String get surprise_grade_rank_3 => 'OKAY';

  @override
  String get surprise_grade_rank_2 => 'WEAK';

  @override
  String get surprise_grade_rank_1 => 'CATASTROPHE';

  @override
  String get new_grades_card => 'You have new grades';

  @override
  String get s_notifications => 'Notifications';

  @override
  String get s_sticker_map => 'Sticker map';

  @override
  String get s_qr_reader => 'QR code reader';

  @override
  String get s_feedback => 'Feedback';

  @override
  String get s_a_desc => 'Navigation, language, bell, rounding';

  @override
  String get s_c_desc => 'Grade colors, theme, app icon';

  @override
  String get s_todo => 'túdú: program this';

  @override
  String get s_surprise_grades => 'Surprise grades';

  @override
  String get s_seasonal_icons => 'Seasonal app icons';

  @override
  String get s_uwu_mode => 'UwU mode';

  @override
  String get s_calendar_sync => 'Calendar sync';

  @override
  String get s_save_grades => 'Save grades';

  @override
  String get s_welcome_msg => 'Welcome message';

  @override
  String get s_extras_desc => 'Surprise grades, calendar sync';

  @override
  String get s_notifications_desc => 'Grades, timetable changes, absences';

  @override
  String get s_notif_push_enabled => 'Enable push notifications';

  @override
  String get s_notif_delivery_method_header => 'Delivery method';

  @override
  String get s_notif_delivery_auto => 'Automatic';

  @override
  String get s_notif_delivery_fcm => 'Firebase Cloud Messaging (FCM)';

  @override
  String get s_notif_delivery_alarm => 'Alarm (background check)';

  @override
  String get s_notif_wakeup_interval_header => 'Check frequency';

  @override
  String get s_notif_wakeup_hourly => 'Hourly';

  @override
  String get s_notif_wakeup_two_hourly => 'Every 2 hours';

  @override
  String get s_notif_categories_header => 'Categories';

  @override
  String get s_notif_grades => 'Grades';

  @override
  String get s_notif_homework_tests => 'Homework & tests';

  @override
  String get s_notif_absences => 'Absences';

  @override
  String get s_notif_lessons => 'Lesson changes';

  @override
  String get s_notif_lessons_cancelled => 'Cancelled lessons';

  @override
  String get s_notif_lessons_substituted => 'Substitutions';

  @override
  String get s_notif_messages => 'Messages';

  @override
  String get s_progress_notification => 'Progress-centric notification';

  @override
  String get s_progress_notification_desc => 'Live progress notification for lessons and breaks throughout the school day';

  @override
  String get progress_notif_channel_name => 'School day progress';

  @override
  String get progress_notif_channel_desc => 'Live progress notification for today\'s lessons and breaks';

  @override
  String progress_notif_lesson_title(String number, String name) {
    return 'Lesson $number: $name';
  }

  @override
  String get progress_notif_substitution => ' (Substitution)';

  @override
  String progress_notif_case1_text(String minutes, String timeRange, String room, String substitution, String remaining) {
    return 'In $minutes min ($timeRange)$room$substitution$remaining';
  }

  @override
  String progress_notif_case2_lesson_text(String minutes, String timeRange, String room, String substitution, String remaining) {
    return '$minutes min left ($timeRange)$room$substitution$remaining';
  }

  @override
  String get progress_notif_case2_break_title => 'Break';

  @override
  String progress_notif_case2_break_text(String minutes, String remaining) {
    return '$minutes min left$remaining';
  }

  @override
  String progress_notif_critical_text(String minutes) {
    return '${minutes}m';
  }

  @override
  String get progress_notif_remaining_lessons_one => ' - 1 lesson remaining';

  @override
  String progress_notif_remaining_lessons_other(String count) {
    return ' - $count lessons remaining';
  }

  @override
  String get s_fcm_status_title => 'FCM status';

  @override
  String get s_fcm_status_initialized => 'Initialized';

  @override
  String get s_fcm_status_not_initialized => 'Not initialized';

  @override
  String get s_fcm_status_token_present => 'Token present';

  @override
  String get s_fcm_status_token_missing => 'No token';

  @override
  String get s_fcm_status_permission_label => 'Notification permission';

  @override
  String get s_fcm_status_permission_granted => 'Granted';

  @override
  String get s_fcm_status_permission_denied => 'Denied';

  @override
  String get s_fcm_status_permission_unknown => 'Unknown';

  @override
  String get s_fcm_status_topic_label => 'Subscribed topic';

  @override
  String get s_fcm_status_last_refresh_label => 'Last token refresh';

  @override
  String get s_fcm_status_last_refresh_never => 'Never';

  @override
  String get s_fcm_status_refresh_button => 'Refresh';

  @override
  String get s_fcm_notify_on_message => 'Notify on FCM message';

  @override
  String get s_fcm_test_notifications_title => 'Test notifications';

  @override
  String get s_fcm_test_notifications_multi_title => 'Simulate multi-account';

  @override
  String get s_n_all => 'All';

  @override
  String get s_n_grades => 'New grades';

  @override
  String get s_n_homework_tests => 'Homework & Tests';

  @override
  String get s_n_absences => 'Absences';

  @override
  String get s_n_lessons => 'Lessons';

  @override
  String get s_n_messages => 'Messages';

  @override
  String get s_n_by_subject => 'By subject';
}
