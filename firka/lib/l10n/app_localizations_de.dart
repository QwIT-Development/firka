// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get restart_title => 'App neu starten';

  @override
  String get restart_body => 'Klicke hier, um die App zu öffnen.';

  @override
  String get loginBtn => 'Login mit E-Kréta';

  @override
  String get privacyLabel => 'Datenschutzerklärung';

  @override
  String get title1 => 'Alles auf einen Blick';

  @override
  String get subtitle1 => 'Oben auf der Startseite findest du nützliche Informationen zu deinem Tag.';

  @override
  String get title2 => 'Hier finden deine Fächer Platz';

  @override
  String get subtitle2 => 'Hier findest du Statistiken, bevorstehende Prüfungen und sogar deine Noten aus früheren Schuljahren.';

  @override
  String get title3 => 'Individuell anpassbarer Stundenplan';

  @override
  String get subtitle3 => 'Wähle auf der Stundenplanseite aus, was du sehen möchtest, und schalte Tests, Hausaufgaben, Pausen und Freistunden ein oder aus.';

  @override
  String get title4 => 'Viele Extras, die du in Kreta niemals finden wirst';

  @override
  String get subtitle4 => '';

  @override
  String get yesterday => 'Gestern';

  @override
  String get today => 'Heute';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get debug_screen => 'Entwicklermenü';

  @override
  String get settings_screen => 'Einstellungen';

  @override
  String get home => 'Startseite';

  @override
  String get grades => 'Noten';

  @override
  String get timetable => 'Stundenplan';

  @override
  String get other => 'Andere';

  @override
  String get refreshing => 'Daten werden aktualisiert...';

  @override
  String get reauth => 'Login notwendig';

  @override
  String get api_error => 'Kréta API Fehler';

  @override
  String get pairing => 'Koppel deine Uhr';

  @override
  String get pairing_description => 'Möchtest du diese Uhr mit der Firka App koppeln?\nNach der Kopplung kannst du deinen Stundenplan, neue Noten, Tests und Aufgaben einsehen.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get okay => 'Okay';

  @override
  String get pair => 'Kopplung';

  @override
  String get beta_title => 'Firka - öffentliche Beta';

  @override
  String get beta_body => 'Die Anwendung befindet sich noch in der Entwicklung; einige Funktionen sind möglicherweise noch nicht fertiggestellt, funktionieren nicht richtig oder weisen Fehler auf.';

  @override
  String good_morning(String p) {
    return 'Guten Morgen, $p!';
  }

  @override
  String good_day(String p) {
    return 'Guten Tag, $p!';
  }

  @override
  String n_left_subtitle(num n) {
    return 'Halte durch, es sind nur noch $n Stunden übrig!';
  }

  @override
  String get suffering_almost_over_subtitle => 'Du hast es fast geschafft. Pass weiterhin bei deinem Lehrer gut auf.';

  @override
  String school_ending(String p) {
    return 'Bist du nervös, $p?';
  }

  @override
  String get tomorrow_subtitle => 'So sieht dein morgiger Tag aus.';

  @override
  String good_afternoon(String p) {
    return 'Guten Nachmittag, $p!';
  }

  @override
  String good_night(String p) {
    return 'Guten Abend, $p!';
  }

  @override
  String get starting_soon => 'Deine erste Unterrichtstunde beginnt gleich!';

  @override
  String get starting_hour => 'Stunde';

  @override
  String get starting_hour_plural => 'Stunden';

  @override
  String get starting_min => 'Minute';

  @override
  String get starting_min_plural => 'Minuten';

  @override
  String get starting_sec => 'Sekunde';

  @override
  String get starting_sec_plural => 'Sekunden';

  @override
  String get subjects => 'Fächer';

  @override
  String get your_subjects => 'Deine Fächer';

  @override
  String get data => 'Details';

  @override
  String get subject_avg => 'Notendurchschnitt';

  @override
  String get subject_avg_rounded => 'Notendurchschnitt nach Rundung';

  @override
  String get class_avg => 'Klassendurchschnitt';

  @override
  String get class_n => 'Wöchentliche Stundenzahl';

  @override
  String get tt_no_classes_l1 => 'Diese Woche hast du keinen Unterricht!';

  @override
  String get tt_no_classes_l2 => 'Yippee!';

  @override
  String get class_dismissed => 'Abgesagte Unterrichtsstunde';

  @override
  String get catalog_lesson_btn => 'Catalog lesson';

  @override
  String get catalog_lesson_title => 'Catalog lesson';

  @override
  String get catalog_lesson_topic_hint => 'Topic covered';

  @override
  String get catalog_lesson_submit_btn => 'Save';

  @override
  String get class_substitution => 'Vertretung';

  @override
  String get lesson_subject => 'Thema der Stunde';

  @override
  String get tt_settings_toast => 'Stundenplan Einstellungen';

  @override
  String get tt_settings_toast_lesson_nos => 'Anzahl von Stunden';

  @override
  String get tt_settings_toast_lesson_tests => 'Tests & Sonstiges';

  @override
  String get tt_settings_toast_lesson_breaks => 'Pausen';

  @override
  String get a_week => 'A Woche';

  @override
  String get b_week => 'B Woche';

  @override
  String get stats_date => 'Datum';

  @override
  String get stats_created_at => 'Erstellt am';

  @override
  String get stats_last_mod => 'Zuletzt bearbeitet';

  @override
  String get s_developer => 'Entwicklereinstellungen';

  @override
  String get s_stats_for_nerds => 'Statistiken für Nerds';

  @override
  String get s_settings => 'Einstellungen';

  @override
  String get s_a => 'Applikation';

  @override
  String get s_ag => 'Allgemein';

  @override
  String get s_ag_bell_delay => 'Glockenverzögerung';

  @override
  String get s_ag_rounding => 'Standardmäßige Rundung';

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
  String get s_customization => 'Personalisierung';

  @override
  String get s_ag_r1 => '1 → 2';

  @override
  String get s_ag_r2 => '2 → 3';

  @override
  String get s_ag_r3 => '3 → 4';

  @override
  String get s_ag_r4 => '4 → 5';

  @override
  String get s_ag_class_avg_on_graph => 'Klassendurchschnitt in der Grafik';

  @override
  String get s_ag_navbar => 'Navigationsleiste';

  @override
  String get s_ag_left_handed_mode => 'Linkshänder Modus';

  @override
  String get s_ag_language_header => 'Sprache';

  @override
  String get s_ag_language_auto => 'Automatisch';

  @override
  String get s_ag_language_hu => 'Ungarisch';

  @override
  String get s_ag_language_en => 'Englisch';

  @override
  String get s_ag_language_de => 'Deutsch';

  @override
  String get s_c => 'Personalisierung';

  @override
  String get s_c_icon_header => 'App Symbole';

  @override
  String get s_c_replace_icon => 'Symbol ersetzen';

  @override
  String get s_ci_icon_header => 'App Symbol';

  @override
  String get s_ci_warning_header => '[!] Im Debug-Modus funktioniert das Ändern des Symbols nicht';

  @override
  String get s_ci_icon_subtitle => 'Such dir ein hübsches App-Symbol aus, wenn du das grüne satt hast.';

  @override
  String get s_ci_icon_g1 => 'Catboy domain';

  @override
  String get s_ci_icon_g2 => 'Filc-Stift';

  @override
  String get s_ci_icon_g3 => 'Nostalgie';

  @override
  String get s_ci_icon_g4 => 'Neu gedacht';

  @override
  String get s_ci_icon_g5 => 'Referenz';

  @override
  String get s_ci_icon_g6 => 'Weihnachtslogo-Wettbewerb 2024';

  @override
  String get s_ci_icon_g6_desc => 'Von @emilia6_6';

  @override
  String get s_ci_icon_g7 => 'Pride';

  @override
  String get s_ci_icon_g8 => 'Pride ';

  @override
  String get s_c_theme_header => 'Thema';

  @override
  String get s_c_theme_auto => 'Automatisch';

  @override
  String get s_c_theme_light => 'Hell';

  @override
  String get s_c_theme_dark => 'Dunkel';

  @override
  String get s_ci_child_protection => 'Kinderschutz';

  @override
  String get ic_ace => 'Asexuell';

  @override
  String get ic_ace_f => 'Asexuell';

  @override
  String get ic_bi => 'Bisexuell';

  @override
  String get ic_bi_f => 'Bisexuell';

  @override
  String get ic_cactus => 'Kaktusgarten';

  @override
  String get ic_cc => 'Kreative Wolke';

  @override
  String get ic_enby => 'Nicht-binär';

  @override
  String get ic_enby_f => 'Nicht-binär';

  @override
  String get ic_fidesz => 'Orange';

  @override
  String get ic_filc => 'Filc Tagebuch';

  @override
  String get ic_filco => 'Filc . O';

  @override
  String get ic_galaxy => 'Galaxie';

  @override
  String get ic_gay => 'Schwul';

  @override
  String get ic_gay_f => 'Schwul';

  @override
  String get ic_half_firka_2 => 'Revolution';

  @override
  String get ic_kreta => 'eFirka';

  @override
  String get ic_lesb => 'Lesbisch';

  @override
  String get ic_lesb_f => 'Lesbisch';

  @override
  String get ic_lgbtq => 'LGBTQ+';

  @override
  String get ic_lgbtq_f => 'LGBTQ+';

  @override
  String get ic_lgbtqp => 'Progression';

  @override
  String get ic_lgbtqp_f => 'Progression';

  @override
  String get ic_lidl => 'Einkaufen';

  @override
  String get ic_mkkp => 'Freikarten';

  @override
  String get ic_nuke => 'Nuklear';

  @override
  String get ic_modern => 'Modern';

  @override
  String get ic_o1g => 'Orbán ist ein Arschloch';

  @override
  String get ic_old => 'Domain David';

  @override
  String get ic_original => 'Original';

  @override
  String get ic_paper => 'Papier';

  @override
  String get ic_pear => 'Birne';

  @override
  String get ic_pixel => 'Pixel';

  @override
  String get ic_pixelized => 'Verpixelt';

  @override
  String get ic_pride => 'Weltraumregenbogen';

  @override
  String get ic_proto => 'Prototyp';

  @override
  String get ic_refilc => 'reFilc';

  @override
  String get ic_refulc => 'firk’a';

  @override
  String get ic_repont => 'Fünfzig Forint';

  @override
  String get ic_szivacs => 'Schwamm';

  @override
  String get ic_tisza => 'Árad a firka';

  @override
  String get ic_trans => 'Trans';

  @override
  String get ic_trans_f => 'Trans';

  @override
  String get ic_void_icon => 'Leere';

  @override
  String get ic_xmas1 => 'Liste der Bösen';

  @override
  String get ic_xmas2 => 'Geschenk';

  @override
  String get ic_xmas3 => 'FirWeihnachten';

  @override
  String get wear_phone_unpaired => 'Deine Uhr ist nicht mit deinem Handy gekoppelt!';

  @override
  String get wear_phone_disconnected => 'Deine Uhr ist nicht mit deinem Handy verbunden!';

  @override
  String get wear_pairing_request_sent => 'Die Kopplung läuft, öffne die App auf deinem Smartphone';

  @override
  String get wear_pairing_check_phone => 'Setze die Kopplung auf deinem Smartphone fort';

  @override
  String get wear_try_again => 'Erneut versuchen';

  @override
  String get breakTxt => 'Pause';

  @override
  String get empty_class => 'Freistunde';

  @override
  String timeLeft(num mins) {
    return '$mins Minuten übrig';
  }

  @override
  String get noClasses => 'Heute ist Schulfrei, ruh dich aus!';

  @override
  String get noMoreClasses => 'Du hast heute keinen Unterricht mehr';

  @override
  String firstIn(String t) {
    return 'Deine erste Stunde: $t';
  }

  @override
  String wearTitle(num n) {
    return '$n. Stunde';
  }

  @override
  String get licensesLabel => 'Lizenzen';

  @override
  String get licenseDescription => 'Lizenzen für die von der Applikation verwendeten externen Bibliotheken';

  @override
  String get view_subject_btn => 'Fach anzeigen';

  @override
  String get date => 'Datum';

  @override
  String get tt_settings_toast_lesson_substitution => 'Vertretungen';

  @override
  String get tt_settings_toast_lesson_ab_timetable => 'Zweiwöchiger Stundenplan';

  @override
  String get s_ag_navbar_desc => 'Wähle aus, was in der Navigationsleiste angezeigt werden soll, und ordne die Elemente an. Die übrigen Seiten sind über die Schaltfläche „Mehr“ erreichbar. Du kannst maximal 4 Seiten festlegen.';

  @override
  String get s_ag_navbar_home => 'Startseite';

  @override
  String get s_ag_navbar_visible => 'Erscheint';

  @override
  String happy_birthday(String p) {
    return 'Alles Gute zum Geburtstag, $p!';
  }

  @override
  String tests_tomorrow(String tests) {
    return 'Du hast $tests Prüfungen';
  }

  @override
  String get no_tests_tomorrow => 'Du hast morgen keine Prüfungen';

  @override
  String get get_ready => 'Entspann dich und mach dich bereit für morgen';

  @override
  String get homework => 'Hausaufgaben';

  @override
  String get mark_as_done => 'Als erledigt markieren';

  @override
  String get mark_as_not_done => 'Als unvollständig markieren';

  @override
  String get grade_teacherName => 'Name des Lehrers: ';

  @override
  String get grade_strValue => 'Textbasierte Bewertung: ';

  @override
  String get no_grades => 'Du hast noch keine Noten für dieses Fach.';

  @override
  String get unknown_teacher => 'Unbekannter Lehrer';

  @override
  String get tt_added => 'Eingetragen: ';

  @override
  String get view_lesson_btn => 'Stunde anzeigen';

  @override
  String get s_ag_navbar_hidden => 'Versteckt';

  @override
  String get s_your_account => 'Dein Konto';

  @override
  String get s_acc_kreta => 'eKRÉTA Konto';

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
  String get s_acc_add => 'Neues Konto hinzufügen';

  @override
  String get s_acc_add_teacher => 'Add new teacher account';

  @override
  String get s_acc_logout => 'Abmelden';

  @override
  String get close => 'Schließen';

  @override
  String get tt_non_instructional_day => 'Unterrichtsfreier Schultag';

  @override
  String get tt_public_holiday => 'Feiertag';

  @override
  String get tt_spring_break => 'Frühlingsferien';

  @override
  String get tt_winter_break => 'Winterferien';

  @override
  String get tt_autumn_break => 'Herbstferien';

  @override
  String get tt_instructional_day => 'Unterrichtstag';

  @override
  String get tt_first_semester_end => 'Ende des ersten Semesters';

  @override
  String get tt_holiday => 'Ferien';

  @override
  String get tt_rest_day => 'Ruhetag';

  @override
  String get tt_first_instructional_day => 'Erster Schultag';

  @override
  String get tt_last_instructional_day => 'Letzter Schultag';

  @override
  String get tt_last_instructional_day_graduates => 'Letzter Schultag für die Absolventen';

  @override
  String get tt_full_day_trip => 'Ganztägiger Ausflug';

  @override
  String get tt_quarter_end => 'Quartalsende';

  @override
  String lessons_tomorrow(String lessons) {
    return '$lessons Stunden morgen';
  }

  @override
  String get subject => 'Fach';

  @override
  String get grade_calculator => 'Notenrechner';

  @override
  String get grade_calculator_add => 'Hinzufügen';

  @override
  String get ghost_grade => 'Geist-Note';

  @override
  String get ghost_grades => 'Geist-Noten';

  @override
  String gradesCount(int count) {
    return '$count Note(n)';
  }

  @override
  String get overall_avg => 'Gesamtdurchschnitt';

  @override
  String get now => 'Jetzt';

  @override
  String get s_n => 'Benachrichtigungen';

  @override
  String get s_n_morning => 'Morgendliche Benachrichtigung';

  @override
  String get s_n_morning_time => 'Zeitpunkt der Benachrichtigung vor Schulbeginn';

  @override
  String get s_n_live_activity => 'Live Aktivität';

  @override
  String get s_n_test => 'Testbenachrichtigung senden';

  @override
  String get s_wear => 'Wear OS';

  @override
  String get s_wear_os_support => 'Wear OS Unterstützung';

  @override
  String get wearSyncNotificationTitle => 'Mit Uhr synchronisieren';

  @override
  String get wearSyncNotificationText => 'Daten mit Uhr synchronisieren';

  @override
  String get wear_sync_with_phone => 'Öffne die Smartphone App, um die Synchronisierung durchzuführen';

  @override
  String get wear_syncing => 'Synchronisieren...';

  @override
  String get la_privacy_header => 'Datenschutzerklärung für Live Aktivität';

  @override
  String get la_privacy_intro => 'Um die Funktion „Live Aktivität“ nutzen zu können, müssen wir bestimmte Daten speichern und verarbeiten. Bitte lies dir die folgenden Informationen sorgfältig durch.';

  @override
  String get la_privacy_section1_title => 'Welche Daten speichern wir?';

  @override
  String get la_privacy_section1_body => 'Für den Betrieb von Live Aktivität speichern wir die folgenden Daten zusammen mit deiner Gerätekennung:\n\n• Gerätekennung (UUID)\n• Gerätetoken\n• Live-Aktivität-Push-Token\n• APNs-Push-Token\n• Geräte-Hash\n• Spracheinstellung\n• Glockenverzögerung\n\nDeine Stundenplandaten (Tabelle „lessons“) enthalten Folgendes:\n• Fach und Uhrzeit der Unterrichtsstunde\n• Name des Lehrers\n• Name des Raums\n• Nummer der Unterrichtsstunde\n• Thema der Unterrichtsstunde\n• Daten zur Vertretung\n• Kennzeichnung einer ausgefallenen Unterrichtsstunde\n\nDie zeitgesteuerten Benachrichtigungen (Tabelle „scheduled_notifications“) enthalten Folgendes:\n• ID\n• Geräte-ID\n• Zeitpunkt der Benachrichtigung\n• Status und Zeitpunkt der Übermittlung\n• Erstellungs- und Aktualisierungszeitpunkt';

  @override
  String get la_privacy_section2_title => 'Wie schützen wir deine Daten?';

  @override
  String get la_privacy_section2_body => 'Wir nehmen die Sicherheit deiner Daten ernst:\n\n• Alle Daten in den Tabellen „Geräte“ und „Stunden“ sind verschlüsselt\n• Die Daten werden auf einem sicheren Server gespeichert\n• Wir speichern die Daten nur so lange, wie es erforderlich ist';

  @override
  String get la_privacy_section3_title => 'Wie lange speichern wir die Daten?';

  @override
  String get la_privacy_section3_body => 'Die Speicherung der Daten ist auf einen minimalen Zeitraum beschränkt:\n\n• Live-Aktivität-Push-Token: Wird so lange gespeichert, wie du an diesem Tag Stunden hast (einschließlich des Zeitraums von zwei Stunden vor der ersten Stunde). Wenn du keine Stunden mehr hast, wird der Wert auf Null gesetzt.\n\n• Stundenplan-Daten: Sie werden nur für die Dauer der Stunden gespeichert und anschließend automatisch gelöscht. Am Freitag nach der letzten Stunde ist die Tabelle mit dem Stundenplan vollständig leer.\n\n• Gerätedaten (Token, Identifikatoren): Sie werden so lange gespeichert, wie die Live-Aktivität-Funktion aktiviert ist. Beim Deaktivieren der Funktion werden diese Daten sofort gelöscht.';

  @override
  String get la_privacy_section4_title => 'Wofür verwenden wir die Daten?';

  @override
  String get la_privacy_section4_body => 'Wir verwenden die Daten ausschließlich für den Betrieb der Live-Aktivität-Funktion:\n\n• Anzeige des Live-Stundenplans auf dem Sperrbildschirm\n• Versand von Push-Benachrichtigungen bei Stundenwechseln\n• Synchronisierung des Stundenplans auf deinem Gerät\n• Sicherstellung der Zustellung der Benachrichtigungen am Montagmorgen auch nach der wöchentlichen Datenbankbereinigung\n\nWir geben deine Daten nicht an Dritte weiter und verwenden sie nicht für Marketingzwecke.';

  @override
  String get la_privacy_section5_title => 'Deine Rechte';

  @override
  String get la_privacy_section5_body => 'Gemäß der DSGVO stehen dir folgende Rechte zu:\n\n• Recht auf Auskunft: Die Art der gespeicherten Daten kannst du in dieser Datenschutzerklärung einsehen.\n• Recht auf Löschung: Durch das Deaktivieren der Live-Aktivität-Funktion werden alle mit dieser Funktion verbundenen Daten (Geräte-IDs, Stundenplan) sofort und endgültig von unseren Servern gelöscht.\n• Recht auf Berichtigung: Die Änderung der Stundenplandaten erfolgt im Kréta-System durch die dazu berechtigten Personen (z. B. Lehrkräfte).\n• Widerspruchsrecht: Du kannst der Datenverarbeitung jederzeit widersprechen, indem du die Live-Aktivität-Funktion deaktivierst.';

  @override
  String get la_privacy_footer => 'Letzte Aktualisierung der Datenschutzerklärung: November 2025';

  @override
  String get la_privacy_contact => 'Hast du eine Frage? Schreib uns an support@firka.app.';

  @override
  String get la_privacy_summary1 => 'Gerätetoken, Live-Aktivität-Token, Stundenplandaten';

  @override
  String get la_privacy_summary2 => 'Verschlüsselte Speicherung, sichere Server';

  @override
  String get la_privacy_summary3 => 'Die Daten werden automatisch gelöscht, sobald sie nicht mehr benötigt werden';

  @override
  String get la_title => 'Live Aktivität';

  @override
  String get la_subtitle => 'Live-Anzeige des Stundenplans auf dem Sperrbildschirm des Geräts';

  @override
  String get la_privacy_title => 'Datenschutzerklärung';

  @override
  String get la_privacy_required => 'Um Live Aktivität nutzen zu können, musst du der Datenschutzerklärung zustimmen';

  @override
  String get la_learn_more => 'Mehr dazu';

  @override
  String get la_accept => 'Ich stimme zu';

  @override
  String get la_decline => 'Ich lehne ab';

  @override
  String get runningInDomainBrowser => 'Domain-Browser';

  @override
  String get copied => 'Kopiert';

  @override
  String get view_day_btn => 'Tag anzeigen';

  @override
  String get omission => 'Abwesenheit';

  @override
  String get omissions => 'Abwesenheiten';

  @override
  String get omission_state_excused => 'Entschuldigt';

  @override
  String get omission_state_unexcused => 'Unentschuldigt';

  @override
  String get omission_state_pending => 'Ausstehend';

  @override
  String omissions_count(String state, int count) {
    String _temp0 = intl.Intl.selectLogic(
      state,
      {
        'unexcused': '$count unentschuldigt',
        'pending': '$count zu entschuldigen',
        'other': '$count',
      },
    );
    return '$_temp0 Fehlzeiten';
  }

  @override
  String get s_beta_warning => 'Beta-Warnung';

  @override
  String get s_ag_privacy_ever_declined => 'Datenschutz zuvor abgelehnt';

  @override
  String get s_c_my_themes => 'Meine Themes';

  @override
  String get s_c_manage_subjects => 'Fächer verwalten';

  @override
  String get s_c_change_app_icon => 'App-Icon ändern';

  @override
  String get s_c_colors_header => 'Farben';

  @override
  String get s_c_grade_colors_header => 'Notenfarben';

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
  String get s_c_title_style_header => 'Titelstil';

  @override
  String get s_c_title_weight_header => 'Titelstärke';

  @override
  String get s_c_title_weight_subtitle => 'Wird nicht von allen Schriftarten unterstützt';

  @override
  String get s_c_title_weight_thin => 'Dünn';

  @override
  String get s_c_title_weight_thick => 'Fett';

  @override
  String get s_c_capitalization_header => 'Groß-/Kleinschreibung';

  @override
  String get s_c_capitalization_lower => 'kleinbuchstaben';

  @override
  String get s_c_capitalization_normal => 'Normal';

  @override
  String get s_c_capitalization_upper => 'GROSSBUCHSTABEN';

  @override
  String get s_c_change => 'Ändern';

  @override
  String get s_c_customize => 'Anpassen';

  @override
  String get s_c_themes_current => 'Aktuell';

  @override
  String get s_c_themes_own => 'Eigene';

  @override
  String get s_c_themes_downloaded => 'Heruntergeladen';

  @override
  String get s_c_themes_share_current => 'Aktuelles Theme teilen';

  @override
  String get s_c_themes_create_new => 'Neues Theme erstellen';

  @override
  String get s_c_themes_import => 'Theme importieren';

  @override
  String get s_c_themes_use => 'Verwenden';

  @override
  String get s_c_themes_continue => 'Weiter';

  @override
  String get s_c_themes_own_label => 'Eigenes Theme';

  @override
  String get s_c_themes_imported_label => 'Importiertes Theme';

  @override
  String get s_c_themes_builtin_label => 'Integriertes Theme';

  @override
  String get s_c_themes_builtin_name => 'Standard';

  @override
  String get s_c_themes_create_title => 'Neues Theme erstellen';

  @override
  String get s_c_themes_create_subtitle => 'Gib einen Namen für das Theme ein';

  @override
  String get s_c_themes_create_placeholder => 'Themename';

  @override
  String get s_c_themes_delete_title => 'Theme löschen';

  @override
  String get s_c_themes_delete_subtitle => 'Möchtest du dieses Theme wirklich löschen? Diese Aktion kann rückgängig gemacht werden.';

  @override
  String get s_c_themes_delete_confirm => 'Löschen';

  @override
  String get s_about => 'Über die App';

  @override
  String get s_extras => 'Extras';

  @override
  String get s_other => 'Sonstiges';

  @override
  String get grade_weight_x1 => 'einfache Gewichtung';

  @override
  String get grade_weight_x2 => 'doppelte Gewichtung';

  @override
  String get grade_weight_x3 => 'dreifache Gewichtung';

  @override
  String get grade_weight_x4 => 'vierfache Gewichtung';

  @override
  String get grade_weight_x5 => 'fünffache Gewichtung';

  @override
  String grade_weight_percent(int percent) {
    return '$percent%ige Gewichtung';
  }

  @override
  String get surprise_grade_rank_5 => 'LEGENDÄR';

  @override
  String get surprise_grade_rank_4 => 'AUSGEZEICHNET';

  @override
  String get surprise_grade_rank_3 => 'OKAY';

  @override
  String get surprise_grade_rank_2 => 'SCHWACH';

  @override
  String get surprise_grade_rank_1 => 'KATASTROPHE';

  @override
  String get new_grades_card => 'Du hast neue Noten';

  @override
  String get s_notifications => 'Benachrichtigungen';

  @override
  String get s_sticker_map => 'Stickerkarte';

  @override
  String get s_qr_reader => 'QR-Code-Scanner';

  @override
  String get s_feedback => 'Feedback';

  @override
  String get s_a_desc => 'Navigation, Sprache, Glocke, Rundung';

  @override
  String get s_c_desc => 'Notenfarben, Thema, App-Symbol';

  @override
  String get s_todo => 'túdú: program this';

  @override
  String get s_surprise_grades => 'Überraschungsnoten';

  @override
  String get s_seasonal_icons => 'Saisonale App-Symbole';

  @override
  String get s_uwu_mode => 'UwU-Modus';

  @override
  String get s_calendar_sync => 'Kalendersynchronisierung';

  @override
  String get s_save_grades => 'Noten speichern';

  @override
  String get s_welcome_msg => 'Begrüßungsnachricht';

  @override
  String get s_extras_desc => 'Überraschungsnoten, Kalendersynchronisierung';

  @override
  String get s_notifications_desc => 'Noten, Stundenplanänderungen, Fehlzeiten';

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
  String get s_n_all => 'Alle';

  @override
  String get s_n_grades => 'Neue Noten';

  @override
  String get s_n_homework_tests => 'Hausaufgaben & Prüfungen';

  @override
  String get s_n_absences => 'Fehlzeiten';

  @override
  String get s_n_lessons => 'Stunden';

  @override
  String get s_n_messages => 'Nachrichten';

  @override
  String get s_n_by_subject => 'Nach Fach';
}
