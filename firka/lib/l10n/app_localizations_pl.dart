// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get restart_title => 'Uruchom ponownie aplikację';

  @override
  String get restart_body => 'Kliknij tutaj, aby otworzyć aplikację.';

  @override
  String get loginBtn => 'Zaloguj się za pomocą konta E-Kréta';

  @override
  String get privacyLabel => 'Polityka prywatności';

  @override
  String get title1 => 'Poznaj wszystko na pierwszy rzut oka';

  @override
  String get subtitle1 => 'Na górze strony głównej możesz zobaczyć przydatne informacje o swoim dniu.';

  @override
  String get title2 => 'Twoje przedmioty wygodnie się tutaj mieszczą';

  @override
  String get subtitle2 => 'Zobacz statystyki, nadchodzące sprawdziany, a nawet oceny z poprzednich lat szkolnych.';

  @override
  String get title3 => 'Personalizowany plan lekcji';

  @override
  String get subtitle3 => 'Wybierz, co chcesz widzieć na stronie planu lekcji. Włącz lub wyłącz sprawdziany, prace domowe, przerwy oraz okienka.';

  @override
  String get title4 => 'Wiele dodatkowych rzeczy, których nigdy nie znajdziesz w Kréta.';

  @override
  String get subtitle4 => '';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get today => 'Dziś';

  @override
  String get tomorrow => 'Jutro';

  @override
  String get debug_screen => 'Menu deweloperskie';

  @override
  String get settings_screen => 'Ustawienia';

  @override
  String get home => 'Strona główna';

  @override
  String get grades => 'Oceny';

  @override
  String get timetable => 'Plan lekcji';

  @override
  String get other => 'Więcej';

  @override
  String get refreshing => 'Aktualizowanie danych...';

  @override
  String get reauth => 'Wymagane logowanie';

  @override
  String get api_error => 'Błąd API Kréta';

  @override
  String get pairing => 'Łączenie lekcji';

  @override
  String get pairing_description => 'Czy chcesz połączyć tę lekcję z aplikacją Firka?\nPo połączeniu zobaczysz plan lekcji oraz swoje najnowsze oceny, sprawdziany i zadania.';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get okay => 'Ok';

  @override
  String get pair => 'Parowanie';

  @override
  String get beta_title => 'Firka – publiczna beta';

  @override
  String get beta_body => 'Aplikacja jest w trakcie rozwoju; niektóre funkcje mogą działać nieprawidłowo, nie działać lub jeszcze nie być ukończone.';

  @override
  String good_morning(String p) {
    return 'Dzień dobry, $p!';
  }

  @override
  String good_day(String p) {
    return 'Miłego dnia, $p!';
  }

  @override
  String n_left_subtitle(num n) {
    return 'Wytrzymaj, zostało tylko $n godzin!';
  }

  @override
  String get suffering_almost_over_subtitle => 'Już niedługo będziesz wolny. Uważaj na nauczyciela.';

  @override
  String school_ending(String p) {
    return 'Denerwujesz się, $p?';
  }

  @override
  String get tomorrow_subtitle => 'Oto Twój jutrzejszy dzień.';

  @override
  String good_afternoon(String p) {
    return 'Miłego popołudnia, $p!';
  }

  @override
  String good_night(String p) {
    return 'Miłego wieczoru, $p!';
  }

  @override
  String get starting_soon => 'Już wkrótce zaczyna się Twoja pierwsza lekcja!';

  @override
  String get starting_hour => 'godzina';

  @override
  String get starting_hour_plural => 'godzina';

  @override
  String get starting_min => 'minuta';

  @override
  String get starting_min_plural => 'minuta';

  @override
  String get starting_sec => 'sekunda';

  @override
  String get starting_sec_plural => 'sekunda';

  @override
  String get subjects => '­Przedmioty';

  @override
  String get your_subjects => 'Twoje przedmioty';

  @override
  String get data => 'Dane';

  @override
  String get subject_avg => 'Średnia z przedmiotu';

  @override
  String get subject_avg_rounded => 'Średnia z przedmiotu po zaokrągleniu';

  @override
  String get class_avg => 'Średnia klasy';

  @override
  String get class_n => '­Liczba godzin tygodniowo';

  @override
  String get tt_no_classes_l1 => 'W tym dniu nie masz lekcji!';

  @override
  String get tt_no_classes_l2 => 'Yippee!';

  @override
  String get class_dismissed => 'Odwołana lekcja';

  @override
  String get catalog_lesson_btn => 'Catalog lesson';

  @override
  String get catalog_lesson_title => 'Catalog lesson';

  @override
  String get catalog_lesson_topic_hint => 'Topic covered';

  @override
  String get catalog_lesson_submit_btn => 'Save';

  @override
  String get class_substitution => 'Zastępstwo';

  @override
  String get lesson_subject => 'Przedmiot lekcji';

  @override
  String get tt_settings_toast => 'Ustawienia planu lekcji';

  @override
  String get tt_settings_toast_lesson_nos => 'Numery lekcji';

  @override
  String get tt_settings_toast_lesson_tests => 'Sprawdziany i inne';

  @override
  String get tt_settings_toast_lesson_breaks => 'Przerwy';

  @override
  String get a_week => 'Tydzień';

  @override
  String get b_week => 'Tydzień B';

  @override
  String get stats_date => 'Data';

  @override
  String get stats_created_at => 'Utworzono';

  @override
  String get stats_last_mod => 'Ostatnio zmodyfikowano';

  @override
  String get s_developer => 'Ustawienia deweloperskie';

  @override
  String get s_stats_for_nerds => 'Pokaż dodatkowe informacje';

  @override
  String get s_settings => 'Ustawienia';

  @override
  String get s_a => 'Aplikacja';

  @override
  String get s_ag => 'Ogólne';

  @override
  String get s_ag_bell_delay => 'Przesunięcie dzwonka';

  @override
  String get s_ag_rounding => 'Domyślne zaokrąglanie';

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
  String get s_customization => 'Personalizacja';

  @override
  String get s_ag_r1 => '1 → 2';

  @override
  String get s_ag_r2 => '2 → 3';

  @override
  String get s_ag_r3 => '3 → 4';

  @override
  String get s_ag_r4 => '4 → 5';

  @override
  String get s_ag_class_avg_on_graph => 'Średnia klasy na wykresie';

  @override
  String get s_ag_navbar => 'Pasek nawigacyjny';

  @override
  String get s_ag_left_handed_mode => 'Tryb dla leworęcznych';

  @override
  String get s_ag_language_header => 'Język';

  @override
  String get s_ag_language_auto => 'Automatyczny';

  @override
  String get s_ag_language_hu => 'Węgierski';

  @override
  String get s_ag_language_en => 'Angielski';

  @override
  String get s_ag_language_de => 'Niemiecki';

  @override
  String get s_c => 'Dostosowanie';

  @override
  String get s_c_icon_header => 'Ikony aplikacji';

  @override
  String get s_c_replace_icon => '­Zmiana ikony';

  @override
  String get s_ci_icon_header => 'Ikona aplikacji';

  @override
  String get s_ci_warning_header => '[!] W trybie debug zmiana ikony nie będzie działać';

  @override
  String get s_ci_icon_subtitle => 'Wybierz piękną ikonę aplikacji, jeśli znudził Ci się zielony kolor.';

  @override
  String get s_ci_icon_g1 => 'Catboy domain';

  @override
  String get s_ci_icon_g2 => '­Pisak';

  @override
  String get s_ci_icon_g3 => 'Nostalgia';

  @override
  String get s_ci_icon_g4 => 'Przeprojektowany';

  @override
  String get s_ci_icon_g5 => 'Referencja';

  @override
  String get s_ci_icon_g6 => 'Konkurs na świąteczne logo 2024';

  @override
  String get s_ci_icon_g6_desc => 'przez @emilia6_6';

  @override
  String get s_ci_icon_g7 => 'Pride';

  @override
  String get s_ci_icon_g8 => 'Pride ';

  @override
  String get s_c_theme_header => 'Motyw';

  @override
  String get s_c_theme_auto => 'Automatyczny';

  @override
  String get s_c_theme_light => 'Jasny';

  @override
  String get s_c_theme_dark => 'Ciemny';

  @override
  String get s_ci_child_protection => 'Ochrona dzieci';

  @override
  String get ic_ace => 'Aseksualny';

  @override
  String get ic_ace_f => 'Aseksualny';

  @override
  String get ic_bi => 'Biseksualny';

  @override
  String get ic_bi_f => 'Biseksualny';

  @override
  String get ic_cactus => 'Kaktusowy zagajnik';

  @override
  String get ic_cc => 'Chmura Kreatywna';

  @override
  String get ic_enby => 'Niebinarna';

  @override
  String get ic_enby_f => 'Niebinarna';

  @override
  String get ic_fidesz => 'Fidesz';

  @override
  String get ic_filc => 'Filc Dziennik';

  @override
  String get ic_filco => 'Filc . O';

  @override
  String get ic_galaxy => 'Galaktyka';

  @override
  String get ic_gay => 'Gej';

  @override
  String get ic_gay_f => 'Gej';

  @override
  String get ic_half_firka_2 => 'Rewolucja';

  @override
  String get ic_kreta => 'eFIRKA';

  @override
  String get ic_lesb => 'Lesbijka';

  @override
  String get ic_lesb_f => 'Lesbijka';

  @override
  String get ic_lgbtq => 'LGBTQ+';

  @override
  String get ic_lgbtq_f => 'LGBTQ+';

  @override
  String get ic_lgbtqp => 'Postęp';

  @override
  String get ic_lgbtqp_f => 'Postęp';

  @override
  String get ic_lidl => 'Zakupy';

  @override
  String get ic_mkkp => 'Darmowe oceny';

  @override
  String get ic_nuke => 'Nuklearny';

  @override
  String get ic_modern => 'Nowoczesny';

  @override
  String get ic_o1g => 'Orbán to pizda';

  @override
  String get ic_old => 'Domain Dave';

  @override
  String get ic_original => 'Oryginał';

  @override
  String get ic_paper => 'Papier';

  @override
  String get ic_pear => 'Gruszka';

  @override
  String get ic_pixel => 'Pixel';

  @override
  String get ic_pixelized => 'Spikselizowany';

  @override
  String get ic_pride => 'Kosmiczna tęcza';

  @override
  String get ic_proto => 'Prototyp';

  @override
  String get ic_refilc => 'reFilc';

  @override
  String get ic_refulc => 'firk’a';

  @override
  String get ic_repont => 'Pięćdziesiąt groszy';

  @override
  String get ic_szivacs => 'Gąbka';

  @override
  String get ic_tisza => 'Árad a firka';

  @override
  String get ic_trans => 'Trans';

  @override
  String get ic_trans_f => 'Trans';

  @override
  String get ic_void_icon => 'Nic';

  @override
  String get ic_xmas1 => 'Lista złych';

  @override
  String get ic_xmas2 => 'Prezent';

  @override
  String get ic_xmas3 => 'FirŚwięta';

  @override
  String get wear_phone_unpaired => 'Az órád nincs párosítva a telefonoddal!';

  @override
  String get wear_phone_disconnected => 'Az órád nincs csatlakoztatva a telefonoddal!';

  @override
  String get wear_pairing_request_sent => 'Párosítás folyamatban, nyisd meg az appot a telefonodon';

  @override
  String get wear_pairing_check_phone => 'Folytasd a párosítást a telefonodon';

  @override
  String get wear_try_again => 'Újra';

  @override
  String get breakTxt => 'Szünet';

  @override
  String get empty_class => 'Lyukasóra';

  @override
  String timeLeft(num mins) {
    return 'Még $mins perc';
  }

  @override
  String get noClasses => 'Nincs ma iskola, pihend ki magad!';

  @override
  String get noMoreClasses => 'Nincs több órád ma';

  @override
  String firstIn(String t) {
    return 'Első órád: $t';
  }

  @override
  String wearTitle(num n) {
    return '$n. óra';
  }

  @override
  String get licensesLabel => 'Licencek';

  @override
  String get licenseDescription => 'Az alkalmazás által használt külső könyvtárak licencei';

  @override
  String get view_subject_btn => 'Zobacz przedmiot';

  @override
  String get date => 'Godzina lekcji';

  @override
  String get tt_settings_toast_lesson_substitution => 'Zastępstwa';

  @override
  String get tt_settings_toast_lesson_ab_timetable => 'Dwutygodniowy plan lekcji';

  @override
  String get s_ag_navbar_desc => 'Wybierz, co ma się wyświetlać na pasku nawigacyjnym, i uporządkuj elementy. Pozostałe strony są dostępne przez przycisk „więcej”. Możesz przypiąć maksymalnie 4 strony.';

  @override
  String get s_ag_navbar_home => 'Strona główna';

  @override
  String get s_ag_navbar_visible => 'Wyświetlane';

  @override
  String happy_birthday(String p) {
    return 'Wszystkiego najlepszego, $p!';
  }

  @override
  String tests_tomorrow(String tests) {
    return 'Masz $tests sprawdzianów';
  }

  @override
  String get no_tests_tomorrow => 'Jutro nie masz sprawdzianu';

  @override
  String get get_ready => 'Odpocznij i przygotuj się';

  @override
  String get homework => 'Praca domowa';

  @override
  String get mark_as_done => '­Oznacz jako ukończone';

  @override
  String get mark_as_not_done => 'Oznacz jako nieukończone';

  @override
  String get grade_teacherName => 'Imię i nazwisko nauczyciela: ';

  @override
  String get grade_strValue => 'Ocena opisowa: ';

  @override
  String get no_grades => 'Z tego przedmiotu nie masz jeszcze ocen.';

  @override
  String get unknown_teacher => 'Nieznany nauczyciel';

  @override
  String get tt_added => 'Utworzono: ';

  @override
  String get view_lesson_btn => 'Zobacz lekcję';

  @override
  String get s_ag_navbar_hidden => 'Ukryte';

  @override
  String get s_your_account => 'Twoje konto';

  @override
  String get s_acc_kreta => 'Konta eKRÉTA';

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
  String get s_acc_add => 'Dodaj nowe konto';

  @override
  String get s_acc_add_teacher => 'Add new teacher account';

  @override
  String get s_acc_logout => 'Wyloguj się';

  @override
  String get close => 'Zamknij';

  @override
  String get tt_non_instructional_day => 'Dzień wolny od zajęć dydaktycznych';

  @override
  String get tt_public_holiday => 'Dzień wolny od pracy';

  @override
  String get tt_spring_break => 'Wiosenna przerwa';

  @override
  String get tt_winter_break => 'Zimowa przerwa';

  @override
  String get tt_autumn_break => 'Jesienna przerwa';

  @override
  String get tt_instructional_day => 'Dzień zajęć szkolnych';

  @override
  String get tt_first_semester_end => 'Koniec pierwszego semestru';

  @override
  String get tt_holiday => 'Dzień świąteczny';

  @override
  String get tt_rest_day => 'Dzień wolny';

  @override
  String get tt_first_instructional_day => 'Pierwszy dzień nauki';

  @override
  String get tt_last_instructional_day => 'Ostatni dzień nauki';

  @override
  String get tt_last_instructional_day_graduates => 'Ostatni dzień zajęć dla klas kończących szkołę';

  @override
  String get tt_full_day_trip => 'Całodniowa wycieczka';

  @override
  String get tt_quarter_end => 'koniec kwartału';

  @override
  String lessons_tomorrow(String lessons) {
    return '$lessons órád lesz';
  }

  @override
  String get subject => 'Tantárgy';

  @override
  String get grade_calculator => 'Jegy kalkulátor';

  @override
  String get grade_calculator_add => 'Hozzáadás';

  @override
  String get ghost_grade => 'Szellem jegy';

  @override
  String get ghost_grades => 'Szellem jegyek';

  @override
  String gradesCount(int count) {
    return '$count jegy';
  }

  @override
  String get overall_avg => 'Összesített átlag';

  @override
  String get now => 'Most';

  @override
  String get s_n => 'Értesítések';

  @override
  String get s_n_morning => 'Reggeli értesítés';

  @override
  String get s_n_morning_time => 'Értesítés ideje iskola előtt';

  @override
  String get s_n_live_activity => 'Live Activity';

  @override
  String get s_n_test => 'Teszt értesítés küldése';

  @override
  String get s_wear => 'Wear OS';

  @override
  String get s_wear_os_support => 'Wear OS támogatás';

  @override
  String get wearSyncNotificationTitle => 'Szinkronizálás az órával';

  @override
  String get wearSyncNotificationText => 'Óra adatainak szinkronban tartása';

  @override
  String get wear_sync_with_phone => 'Nyisd meg a telefonos appot a szinkronizáláshoz';

  @override
  String get wear_syncing => 'Szinkronizálás...';

  @override
  String get la_privacy_header => 'Live Activity adatvédelmi tájékoztató';

  @override
  String get la_privacy_intro => 'A Live Activity funkció használatához bizonyos adatokat kell tárolnunk és feldolgoznunk. Kérjük, olvasd el figyelmesen az alábbi tájékoztatót.';

  @override
  String get la_privacy_section1_title => 'Milyen adatokat tárolunk?';

  @override
  String get la_privacy_section1_body => 'A Live Activity működéséhez az alábbi adatokat tároljuk eszközazonosítóddal együtt:\n\n• Eszköz azonosító (UUID)\n• Eszköz token\n• Live Activity push token\n• APNs push token\n• Eszköz hash\n• Nyelvi beállítás\n• Csengő eltolódása\n\nAz órarendi adataid (lessons tábla) a következőket tartalmazzák:\n• Óra tárgya és időpontja\n• Tanár neve\n• Terem neve\n• Óra sorszáma\n• Óra témája\n• Helyettesítés adatai\n• Elmaradt óra jelzése\n\nAz időzített értesítések (scheduled_notifications tábla) a következőket tartalmazzák:\n• Azonosító\n• Eszköz azonosító\n• Időzített időpont\n• Küldés állapota és ideje\n• Létrehozás és frissítés ideje';

  @override
  String get la_privacy_section2_title => 'Hogyan védjük az adataidat?';

  @override
  String get la_privacy_section2_body => 'Komolyan vesszük az adataid biztonságát:\n\n• A devices és lessons táblákban lévő összes adat titkosítva van\n• Az adatokat biztonságos szerveren tároljuk\n• Csak a szükséges időtartamig tároljuk az adatokat';

  @override
  String get la_privacy_section3_title => 'Meddig tároljuk az adatokat?';

  @override
  String get la_privacy_section3_body => 'Az adatok tárolása minimális időtartamra korlátozódik:\n\n• Live Activity push token: Addig van tárolva, amíg óráid vannak az adott napon (beleértve az első óra előtti 2 órás időszakot is). Ha nincs több órád, az érték null lesz.\n\n• Órarendi adatok: Csak az órák időtartamára tárolódnak, majd automatikusan törlődnek. Pénteken az utolsó óra után az órarendet tartalmazó tábla teljesen üres lesz.\n\n• Eszközadatok (token, azonosítók): Addig van tárolva, amíg a Live Activity funkció engedélyezve van. A funkció kikapcsolásakor ezek az adatok azonnal törlésre kerülnek.';

  @override
  String get la_privacy_section4_title => 'Mire használjuk az adatokat?';

  @override
  String get la_privacy_section4_body => 'Az adatokat kizárólag a Live Activity funkció működtetésére használjuk:\n\n• Élő órarend megjelenítése a lezárási képernyőn\n• Push értesítések küldése óraváltásokkor\n• Az órarend szinkronizálása az eszközödön\n• A hétfő reggeli értesítések kézbesítésének biztosítása a heti adatbázis-ürítés után is\n\nAz adataidat nem adjuk át harmadik félnek, és nem használjuk marketing célokra.';

  @override
  String get la_privacy_section5_title => 'Jogaid';

  @override
  String get la_privacy_section5_body => 'A GDPR alapján az alábbi jogokkal rendelkezel:\n\n• Hozzáférési jog: A tárolt adatok típusát ebben az adatvédelmi tájékoztatóban tekintheted meg.\n• Törlési jog: A Live Activity funkció kikapcsolásával minden, a funkcióhoz kapcsolódó adat (eszközazonosítók, órarend) azonnal és véglegesen törlődik a szervereinkről.\n• Módosítási jog: Az órarendi adatok módosítása a Kréta rendszerben történik, az arra jogosult személyek (pl. tanárok) által.\n• Tiltakozási jog: Az adatkezelés ellen bármikor tiltakozhatsz a Live Activity funkció kikapcsolásával.';

  @override
  String get la_privacy_footer => 'Az adatvédelmi tájékoztató utolsó frissítése: 2025. november';

  @override
  String get la_privacy_contact => 'Kérdésed van? Keress minket a support @firka.app címen.';

  @override
  String get la_privacy_summary1 => 'Eszköz tokenek, Live Activity tokenek, órarendi adatok';

  @override
  String get la_privacy_summary2 => 'Titkosított tárolás, biztonságos szerverek';

  @override
  String get la_privacy_summary3 => 'Az adatok automatikusan törlődnek, ha már nincs rájuk szükség';

  @override
  String get la_title => 'Live Activity';

  @override
  String get la_subtitle => 'Az órarended élő megjelenítése az eszköz lezárási képernyőjén';

  @override
  String get la_privacy_title => 'Adatvédelmi tájékoztató';

  @override
  String get la_privacy_required => 'A Live Activity használatához el kell fogadnod az adatvédelmi tájékoztatót';

  @override
  String get la_learn_more => 'Bővebben';

  @override
  String get la_accept => 'Elfogadom';

  @override
  String get la_decline => 'Elutasítom';

  @override
  String get runningInDomainBrowser => 'Przeglądarka domen';

  @override
  String get copied => 'Másolva';

  @override
  String get view_day_btn => 'Zobacz dzień';

  @override
  String get omission => 'Hiányzás';

  @override
  String get omissions => 'Hiányzások';

  @override
  String get omission_state_excused => 'Igazolt';

  @override
  String get omission_state_unexcused => 'Igazolatlan';

  @override
  String get omission_state_pending => 'Függőben';

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
  String get s_beta_warning => 'Ostrzeżenie beta';

  @override
  String get s_ag_privacy_ever_declined => 'Wcześniej odrzucono politykę prywatności';

  @override
  String get s_c_tab_appearance => 'Wygląd aplikacji';

  @override
  String get s_c_tab_subjects => 'Przedmioty';

  @override
  String get s_c_tab_fonts => 'Czcionki';

  @override
  String get s_c_my_themes => 'Moje motywy';

  @override
  String get s_c_manage_subjects => 'Zarządzaj przedmiotami';

  @override
  String get s_c_change_app_icon => 'Zmień ikonę aplikacji';

  @override
  String get s_c_colors_header => 'Kolory';

  @override
  String get s_c_grade_colors_header => 'Kolory ocen';

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
  String get s_c_title_style_header => 'Styl tytułów';

  @override
  String get s_c_title_weight_header => 'Grubość tytułów';

  @override
  String get s_c_title_weight_subtitle => 'Nie wszystkie czcionki to obsługują';

  @override
  String get s_c_title_weight_thin => 'Cienka';

  @override
  String get s_c_title_weight_thick => 'Gruba';

  @override
  String get s_c_capitalization_header => 'Wielkość liter';

  @override
  String get s_c_capitalization_lower => 'małe litery';

  @override
  String get s_c_capitalization_normal => 'Normalna';

  @override
  String get s_c_capitalization_upper => 'WIELKIE LITERY';

  @override
  String get s_c_change => 'Zmień';

  @override
  String get s_c_customize => 'Dostosuj';

  @override
  String get s_c_themes_current => 'Bieżący';

  @override
  String get s_c_themes_own => 'Własne';

  @override
  String get s_c_themes_downloaded => 'Pobrane';

  @override
  String get s_c_themes_share_current => 'Udostępnij bieżący motyw';

  @override
  String get s_c_themes_create_new => 'Utwórz nowy motyw';

  @override
  String get s_c_themes_import => 'Importuj motyw';

  @override
  String get s_c_themes_use => 'Użyj';

  @override
  String get s_c_themes_continue => 'Kontynuuj';

  @override
  String get s_c_themes_own_label => 'Własny motyw';

  @override
  String get s_c_themes_imported_label => 'Zaimportowany motyw';

  @override
  String get s_c_themes_builtin_label => 'Wbudowany motyw';

  @override
  String get s_c_themes_builtin_name => 'Domyślny';

  @override
  String get s_c_themes_create_title => 'Utwórz nowy motyw';

  @override
  String get s_c_themes_create_subtitle => 'Podaj nazwę motywu';

  @override
  String get s_c_themes_create_placeholder => 'Nazwa motywu';

  @override
  String get s_c_themes_delete_title => 'Usuń motyw';

  @override
  String get s_c_themes_delete_subtitle => 'Czy na pewno chcesz usunąć ten motyw? Tę czynność można cofnąć.';

  @override
  String get s_c_themes_delete_confirm => 'Usuń';

  @override
  String get s_about => 'O aplikacji';

  @override
  String get s_extras => 'Dodatki';

  @override
  String get s_other => 'Inne';

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
