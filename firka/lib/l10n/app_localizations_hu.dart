// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get restart_title => 'Alkalmazás újraindítása';

  @override
  String get restart_body => 'Kattints ide az alkalmazás megnyitásához.';

  @override
  String get loginBtn => 'Bejelentkezés E-Kréta fiókkal';

  @override
  String get privacyLabel => 'Adatvédelmi tájékoztató';

  @override
  String get title1 => 'Egy pillantásra tudhatsz mindent';

  @override
  String get subtitle1 => 'A főoldal tetején hasznos információkat láthatsz a napodról.';

  @override
  String get title2 => 'A tantárgyaid kényelmesen elférnek itt';

  @override
  String get subtitle2 => 'Láss statisztikákat, közelgő számonkéréseket, és akár a régebbi tanéves jegyeidet is.';

  @override
  String get title3 => 'Személyre szabható órarend';

  @override
  String get subtitle3 => 'Válaszd ki, mit szeretnél látni az órarend oldalon, kapcsold ki vagy be a számonkéréseket, házi feladatokat, szüneteket és lyukas órákat is.';

  @override
  String get title4 => 'Sok extra dolog, amit a Krétában sosem fogsz megtalálni';

  @override
  String get subtitle4 => '';

  @override
  String get yesterday => 'Tegnap';

  @override
  String get today => 'Ma';

  @override
  String get tomorrow => 'Holnap';

  @override
  String get debug_screen => 'Fejlesztői menü';

  @override
  String get settings_screen => 'Beállítások';

  @override
  String get home => 'Kezdőlap';

  @override
  String get grades => 'Jegyek';

  @override
  String get timetable => 'Órarend';

  @override
  String get other => 'Több';

  @override
  String get refreshing => 'Adatok frissítése...';

  @override
  String get reauth => 'Bejelentkezés szükséges';

  @override
  String get api_error => 'Kréta API hiba';

  @override
  String get pairing => 'Óra párosítása';

  @override
  String get pairing_description => 'Szeretnéd ezt az órát párosítani a Firka appal?\nPárosítás láthatod az órarendet, és a legújabb jegyeidet, számonkéréseidet, és a feladataidat.';

  @override
  String get cancel => 'Mégse';

  @override
  String get save => 'Mentés';

  @override
  String get okay => 'Rendben';

  @override
  String get pair => 'Párosítás';

  @override
  String get beta_title => 'Firka - Publikus béta';

  @override
  String get beta_body => 'Az alkalmazás fejlesztés alatt áll; egyes funkciók hibásan működhetnek, nem működnek, vagy még nem készültek el.';

  @override
  String good_morning(String p) {
    return 'Jó reggelt, $p!';
  }

  @override
  String good_day(String p) {
    return 'Szép napot, $p!';
  }

  @override
  String n_left_subtitle(num n) {
    return 'Tarts ki, már csak $n óra!';
  }

  @override
  String get suffering_almost_over_subtitle => 'Mindjárt szabad vagy. Figyelj oda a tanárra.';

  @override
  String school_ending(String p) {
    return 'Izgulsz, $p?';
  }

  @override
  String get tomorrow_subtitle => 'Itt a holnapi napod.';

  @override
  String good_afternoon(String p) {
    return 'Szép délutánt, $p!';
  }

  @override
  String good_night(String p) {
    return 'Szép estét, $p!';
  }

  @override
  String get starting_soon => 'Hamarosan kezdődik az első órád!';

  @override
  String get starting_hour => 'óra';

  @override
  String get starting_hour_plural => 'óra';

  @override
  String get starting_min => 'perc';

  @override
  String get starting_min_plural => 'perc';

  @override
  String get starting_sec => 'másodperc';

  @override
  String get starting_sec_plural => 'másodperc';

  @override
  String get subjects => 'Tantárgyak';

  @override
  String get your_subjects => 'Tantárgyaid';

  @override
  String get data => 'Adatok';

  @override
  String get subject_avg => 'Tantárgyi átlag';

  @override
  String get subject_avg_rounded => 'Tantárgyi átlag kerekítés után';

  @override
  String get class_avg => 'Osztályátlag';

  @override
  String get class_n => 'Heti óraszám';

  @override
  String get tt_no_classes_l1 => 'Ezen a napon nincsenek óráid!';

  @override
  String get tt_no_classes_l2 => 'Yippee!';

  @override
  String get class_dismissed => 'Elmaradt óra';

  @override
  String get catalog_lesson_btn => 'Óra naplózása';

  @override
  String get catalog_lesson_title => 'Óra naplózása';

  @override
  String get catalog_lesson_topic_hint => 'Az óra témája';

  @override
  String get catalog_lesson_submit_btn => 'Mentés';

  @override
  String get class_substitution => 'Helyettesítés';

  @override
  String get lesson_subject => 'Az óra tárgya';

  @override
  String get tt_settings_toast => 'Órarend beállításai';

  @override
  String get tt_settings_toast_lesson_nos => 'Óraszámok';

  @override
  String get tt_settings_toast_lesson_tests => 'Számonkérések & egyéb';

  @override
  String get tt_settings_toast_lesson_breaks => 'Szünetek';

  @override
  String get a_week => 'A hét';

  @override
  String get b_week => 'B hét';

  @override
  String get stats_date => 'Dátum';

  @override
  String get stats_created_at => 'Létrehozva';

  @override
  String get stats_last_mod => 'Utoljára módosítva';

  @override
  String get s_developer => 'Fejlesztői beállítások';

  @override
  String get s_stats_for_nerds => 'Extra információ mutatása';

  @override
  String get s_settings => 'Beállítások';

  @override
  String get s_a => 'Alkalmazás';

  @override
  String get s_ag => 'Általános';

  @override
  String get s_ag_bell_delay => 'Csengő eltolódása';

  @override
  String get s_ag_rounding => 'Alapértelmezett kerekítés';

  @override
  String get s_shortened_timetable => 'Rövidített órák';

  @override
  String get s_shortened_timetable_enable => 'Rövidített órák engedélyezése';

  @override
  String get s_shortened_timetable_start => 'Kezdete';

  @override
  String get s_shortened_timetable_end => 'Vége';

  @override
  String get s_shortened_timetable_no_lessons => 'Nincs megjeleníthető óra a gyorsítótárban. Frissítsd az órarendet, majd próbáld újra.';

  @override
  String get s_shortened_timetable_reset => 'Eredeti időpontok visszaállítása';

  @override
  String get s_shortened_timetable_invalid_time => 'A végének a kezdete után kell lennie';

  @override
  String s_shortened_timetable_lesson(int n) {
    return '$n. óra';
  }

  @override
  String get s_customization => 'Személyre szabás';

  @override
  String get s_ag_r1 => '1 → 2';

  @override
  String get s_ag_r2 => '2 → 3';

  @override
  String get s_ag_r3 => '3 → 4';

  @override
  String get s_ag_r4 => '4 → 5';

  @override
  String get s_ag_class_avg_on_graph => 'Osztályátlag a grafikonon';

  @override
  String get s_ag_navbar => 'Navigációs sáv';

  @override
  String get s_ag_left_handed_mode => 'Balkezes mód';

  @override
  String get s_ag_language_header => 'Nyelv';

  @override
  String get s_ag_language_auto => 'Automatikus';

  @override
  String get s_ag_language_hu => 'Magyar';

  @override
  String get s_ag_language_en => 'Angol';

  @override
  String get s_ag_language_de => 'Német';

  @override
  String get s_c => 'Személyre szabás';

  @override
  String get s_c_icon_header => 'App ikonok';

  @override
  String get s_c_replace_icon => 'Ikon cseréje';

  @override
  String get s_ci_icon_header => 'App ikon';

  @override
  String get s_ci_warning_header => '[!] Debug módban nem fog működni az ikon megváltoztatása';

  @override
  String get s_ci_icon_subtitle => 'Válassz egy csodaszép app ikont, ha már unod a zöldet.';

  @override
  String get s_ci_icon_g1 => 'Catboy domain';

  @override
  String get s_ci_icon_g2 => 'Filctoll';

  @override
  String get s_ci_icon_g3 => 'Nosztalgia';

  @override
  String get s_ci_icon_g4 => 'Újragondolt';

  @override
  String get s_ci_icon_g5 => 'Referencia';

  @override
  String get s_ci_icon_g6 => 'Karácsonyi logó verseny 2024';

  @override
  String get s_ci_icon_g6_desc => '@emilia6_6 által';

  @override
  String get s_ci_icon_g7 => 'Pride';

  @override
  String get s_ci_icon_g8 => 'Pride ';

  @override
  String get s_c_theme_header => 'Téma';

  @override
  String get s_c_theme_auto => 'Automatikus';

  @override
  String get s_c_theme_light => 'Világos';

  @override
  String get s_c_theme_dark => 'Sötét';

  @override
  String get s_ci_child_protection => 'Gyermekvédelem';

  @override
  String get ic_ace => 'Aszexuális';

  @override
  String get ic_ace_f => 'Aszexuális';

  @override
  String get ic_bi => 'Biszexuális';

  @override
  String get ic_bi_f => 'Biszexuális';

  @override
  String get ic_cactus => 'Kaktuszliget';

  @override
  String get ic_cc => 'Kreatív Felhő';

  @override
  String get ic_enby => 'Nembináris';

  @override
  String get ic_enby_f => 'Nembináris';

  @override
  String get ic_fidesz => 'Narancs';

  @override
  String get ic_filc => 'Filc Napló';

  @override
  String get ic_filco => 'Filc . O';

  @override
  String get ic_galaxy => 'Galaxis';

  @override
  String get ic_gay => 'Meleg';

  @override
  String get ic_gay_f => 'Meleg';

  @override
  String get ic_half_firka_2 => 'Revolution';

  @override
  String get ic_kreta => 'eFIRKA';

  @override
  String get ic_lesb => 'Leszbikus';

  @override
  String get ic_lesb_f => 'Leszbikus';

  @override
  String get ic_lgbtq => 'LMGBTQ+';

  @override
  String get ic_lgbtq_f => 'LMGBTQ+';

  @override
  String get ic_lgbtqp => 'Progresszió';

  @override
  String get ic_lgbtqp_f => 'Progresszió';

  @override
  String get ic_lidl => 'Bevásárlás';

  @override
  String get ic_mkkp => 'Ingyen jegyek';

  @override
  String get ic_nuke => 'Nukleáris';

  @override
  String get ic_modern => 'Modern';

  @override
  String get ic_o1g => 'O1G';

  @override
  String get ic_old => 'Domain Dév Dévid';

  @override
  String get ic_original => 'Az eredeti';

  @override
  String get ic_paper => 'Papír';

  @override
  String get ic_pear => 'Körte';

  @override
  String get ic_pixel => 'Pixel';

  @override
  String get ic_pixelized => 'Pixelizált';

  @override
  String get ic_pride => 'Űrszívárvány';

  @override
  String get ic_proto => 'Prototípus';

  @override
  String get ic_refilc => 'reFilc';

  @override
  String get ic_refulc => 'firk’a';

  @override
  String get ic_repont => 'Ötven forint';

  @override
  String get ic_szivacs => 'Szivacs';

  @override
  String get ic_tisza => 'Árad a firka';

  @override
  String get ic_trans => 'Transz';

  @override
  String get ic_trans_f => 'Transz';

  @override
  String get ic_void_icon => 'Semmi';

  @override
  String get ic_xmas1 => 'Rosszak listája';

  @override
  String get ic_xmas2 => 'Ajándék';

  @override
  String get ic_xmas3 => 'reKarácsony';

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
  String get view_subject_btn => 'Tantárgy megtekintése';

  @override
  String get date => 'Időpont';

  @override
  String get tt_settings_toast_lesson_substitution => 'Helyettesítések';

  @override
  String get tt_settings_toast_lesson_ab_timetable => 'Kéthetes órarend';

  @override
  String get s_ag_navbar_desc => 'Válaszd ki, mik jelenjenek meg a navigációs sávon, és rendezd el őket. A többi oldal elérhető a “több” gombon keresztül. Maximum 4 oldalt tudsz kitűzni.';

  @override
  String get s_ag_navbar_home => 'Kezdőlap';

  @override
  String get s_ag_navbar_visible => 'Megjelenik';

  @override
  String happy_birthday(String p) {
    return 'Boldog születésnapot, $p!';
  }

  @override
  String tests_tomorrow(String tests) {
    return '$tests dolgozatod lesz';
  }

  @override
  String get no_tests_tomorrow => 'Holnap nincs dolgozatod';

  @override
  String get get_ready => 'Pihend ki magad, és készülj fel';

  @override
  String get homework => 'Házi feladat';

  @override
  String get mark_as_done => 'Megjelölés befejezettként';

  @override
  String get mark_as_not_done => 'Megjelölés befejezetlenként';

  @override
  String get grade_teacherName => 'Tanár neve: ';

  @override
  String get grade_strValue => 'Szöveges értékelés: ';

  @override
  String get grade_not_taken => 'Nem írt';

  @override
  String get no_grades => 'Ebből a tantárgyból még nincsen jegyed.';

  @override
  String get unknown_teacher => 'Ismeretlen tanár';

  @override
  String get tt_added => 'Létrehozva: ';

  @override
  String get view_lesson_btn => 'Óra megtekintése';

  @override
  String get s_ag_navbar_hidden => 'Elrejtve';

  @override
  String get s_your_account => 'Fiókod';

  @override
  String get s_acc_kreta => 'eKRÉTA Fiókok';

  @override
  String get s_acc_accounts => 'Fiókok';

  @override
  String get s_neptun_title => 'ELTE Neptun';

  @override
  String get s_neptun_user_hint => 'Azonosító (pl. abc123)';

  @override
  String get s_neptun_password_hint => 'Jelszó';

  @override
  String get s_neptun_totp_code_hint => 'Add meg a 6-jegyős kódot';

  @override
  String get s_neptun_code_by_email => 'e-mailben elküldve';

  @override
  String get s_neptun_confirm_code => 'Kód megerősítése';

  @override
  String get s_neptun_login_btn => 'Bejelentkezés';

  @override
  String get s_neptun_seed_hint => 'Hitelesítő kulcs (opcionális)';

  @override
  String get s_neptun_seed_help => 'Add meg a 2FA hitelesítőd titkos kulcsát. NEM a 6 jegyű kódot.';

  @override
  String get s_neptun_login_with_elte => 'Bejelentkezés ELTE Neptunnal';

  @override
  String get s_neptun_seed_failed => 'A 2FA automatikus kódgenerálás sikertelen — ellenőrizd a hitelesítő kulcsot.';

  @override
  String get s_neptun_2fa_rejected => 'A 2FA kódot elutasította a rendszer — ha a kód helyes, indítsd újra a bejelentkezést és adj meg egy friss kódot.';

  @override
  String get s_neptun_login_failed => 'Bejelentkezés sikertelen';

  @override
  String get s_acc_add => 'Új diákfiók hozzáadása';

  @override
  String get s_acc_add_teacher => 'Új tanárfiók hozzáadása';

  @override
  String get s_acc_logout => 'Kijelentkezés';

  @override
  String get close => 'Bezárás';

  @override
  String get tt_non_instructional_day => 'Tanítás nélküli munkanap';

  @override
  String get tt_public_holiday => 'Munkaszüneti nap';

  @override
  String get tt_spring_break => 'Tavaszi szünet';

  @override
  String get tt_winter_break => 'Téli szünet';

  @override
  String get tt_autumn_break => 'Őszi szünet';

  @override
  String get tt_instructional_day => 'Tanítási nap';

  @override
  String get tt_first_semester_end => 'Első félév vége';

  @override
  String get tt_holiday => 'Ünnepnap';

  @override
  String get tt_rest_day => 'Pihenőnap';

  @override
  String get tt_first_instructional_day => 'Első tanítási nap';

  @override
  String get tt_last_instructional_day => 'Utolsó tanítási nap';

  @override
  String get tt_last_instructional_day_graduates => 'Utolsó tanítási nap a végzős évfolyamokon';

  @override
  String get tt_full_day_trip => 'Egész napos kirándulás';

  @override
  String get tt_quarter_end => 'negyedév vége';

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
  String get runningInDomainBrowser => 'Doméjn böngésző';

  @override
  String get copied => 'Másolva';

  @override
  String get view_day_btn => 'Nap megtekintése';

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
  String get s_beta_warning => 'Béta figyelmeztetés';

  @override
  String get s_ag_privacy_ever_declined => 'Adatvédelem korábban elutasítva';

  @override
  String get s_c_tab_appearance => 'App kinézete';

  @override
  String get s_c_tab_subjects => 'Tantárgyak';

  @override
  String get s_c_tab_fonts => 'Betűk';

  @override
  String get s_c_my_themes => 'Témáim';

  @override
  String get s_c_manage_subjects => 'Tantárgyak kezelése';

  @override
  String get s_c_change_app_icon => 'App ikon cseréje';

  @override
  String get s_c_colors_header => 'Színek';

  @override
  String get s_c_grade_colors_header => 'Jegyek színei';

  @override
  String get s_c_colors_theme_header => 'Színek & téma';

  @override
  String get s_c_slot_accent => 'Accent';

  @override
  String get s_c_slot_background => 'Háttér';

  @override
  String get s_c_slot_cards => 'Kártyák';

  @override
  String get s_c_slot_buttons => 'Gombok';

  @override
  String get s_c_mode_both => 'Mindkettő';

  @override
  String get s_c_slot_secondary => 'Másodlagos';

  @override
  String get s_c_slot_text => 'Szöveg';

  @override
  String get s_c_slot_text_secondary => 'Másodlagos szöveg';

  @override
  String get s_c_slot_text_tertiary => 'Harmadlagos szöveg';

  @override
  String get s_c_slot_shadow => 'Árnyék';

  @override
  String get s_c_slot_success => 'Siker';

  @override
  String get s_c_slot_warning => 'Figyelmeztetés';

  @override
  String get s_c_slot_warning_text => 'Figyelmeztető szöveg';

  @override
  String get s_c_slot_warning_card => 'Figyelmeztető kártya';

  @override
  String get s_c_slot_error => 'Hiba';

  @override
  String get s_c_slot_error_text => 'Hiba szöveg';

  @override
  String get s_c_slot_error_card => 'Hiba kártya';

  @override
  String get s_c_title_style_header => 'Címek stílusa';

  @override
  String get s_c_title_weight_header => 'Címek vastagsága';

  @override
  String get s_c_title_weight_subtitle => 'Ezt nem mindegyik betűtípus támogatja';

  @override
  String get s_c_title_weight_thin => 'Vékony';

  @override
  String get s_c_title_weight_thick => 'Vastag';

  @override
  String get s_c_capitalization_header => 'Kapitalizáció';

  @override
  String get s_c_capitalization_lower => 'kisbetűs';

  @override
  String get s_c_capitalization_normal => 'Normál';

  @override
  String get s_c_capitalization_upper => 'NAGYBETŰS';

  @override
  String get s_c_change => 'Csere';

  @override
  String get s_c_customize => 'Személyre szabás';

  @override
  String get s_c_themes_current => 'Jelenlegi';

  @override
  String get s_c_themes_own => 'Saját';

  @override
  String get s_c_themes_downloaded => 'Letöltött';

  @override
  String get s_c_themes_share_current => 'Jelenlegi téma megosztása';

  @override
  String get s_c_themes_create_new => 'Új téma létrehozása';

  @override
  String get s_c_themes_import => 'Téma importálása';

  @override
  String get s_c_themes_use => 'Használat';

  @override
  String get s_c_themes_continue => 'Folytatás';

  @override
  String get s_c_themes_own_label => 'Saját téma';

  @override
  String get s_c_themes_imported_label => 'Importált téma';

  @override
  String get s_c_themes_builtin_label => 'Beépített téma';

  @override
  String get s_c_themes_builtin_name => 'Alapértelmezett';

  @override
  String get s_c_themes_create_title => 'Új téma létrehozása';

  @override
  String get s_c_themes_create_subtitle => 'Add meg a téma nevét';

  @override
  String get s_c_themes_create_placeholder => 'A téma neve';

  @override
  String get s_c_themes_delete_title => 'Téma törlése';

  @override
  String get s_c_themes_delete_subtitle => 'Biztosan törölni szeretnéd ezt a témát? Ez a művelet visszavonható.';

  @override
  String get s_c_themes_delete_confirm => 'Törlés';

  @override
  String get s_about => 'Névjegy';

  @override
  String get s_extras => 'Extrák';

  @override
  String get s_other => 'Egyéb';

  @override
  String get grade_weight_x1 => 'egyszeres súllyal';

  @override
  String get grade_weight_x2 => 'dupla súllyal';

  @override
  String get grade_weight_x3 => 'tripla súllyal';

  @override
  String get grade_weight_x4 => 'négyszeres súllyal';

  @override
  String get grade_weight_x5 => 'ötszörös súllyal';

  @override
  String grade_weight_percent(int percent) {
    return '$percent%-os súllyal';
  }

  @override
  String get surprise_grade_rank_5 => 'LEGENDÁS';

  @override
  String get surprise_grade_rank_4 => 'KIVÁLÓ';

  @override
  String get surprise_grade_rank_3 => 'RENDBEN';

  @override
  String get surprise_grade_rank_2 => 'GYENGE';

  @override
  String get surprise_grade_rank_1 => 'KATASZTRÓFA';

  @override
  String get new_grades_card => 'Új jegyeid vannak';

  @override
  String get s_notifications => 'Értesítések';

  @override
  String get s_sticker_map => 'Matrica térkép';

  @override
  String get s_qr_reader => 'QR-kód olvasó';

  @override
  String get s_feedback => 'Visszajelzés';

  @override
  String get s_a_desc => 'Navigáció, nyelv, csengő, kerekítés';

  @override
  String get s_c_desc => 'Jegyek színe, téma, app ikon';

  @override
  String get s_todo => 'túdú: program this';

  @override
  String get s_surprise_grades => 'Meglepetés jegyek';

  @override
  String get s_seasonal_icons => 'Szezonális app ikonok';

  @override
  String get s_uwu_mode => 'UwU mód';

  @override
  String get s_calendar_sync => 'Naptár szinkronizálás';

  @override
  String get s_save_grades => 'Jegyek mentése';

  @override
  String get s_welcome_msg => 'Üdvözlő üzenet';

  @override
  String get s_extras_desc => 'Meglepetés jegyek, naptár szinkronizálás';

  @override
  String get s_notifications_desc => 'Jegyek, órarend változások, hiányok';

  @override
  String get s_notif_push_enabled => 'Push értesítések engedélyezése';

  @override
  String get s_notif_delivery_method_header => 'Kézbesítési mód';

  @override
  String get s_notif_delivery_auto => 'Automatikus';

  @override
  String get s_notif_delivery_fcm => 'Firebase Cloud Messaging (FCM)';

  @override
  String get s_notif_delivery_alarm => 'Ébresztő (háttérellenőrzés)';

  @override
  String get s_notif_wakeup_interval_header => 'Ellenőrzési gyakoriság';

  @override
  String get s_notif_wakeup_hourly => 'Óránként';

  @override
  String get s_notif_wakeup_two_hourly => 'Kétóránként';

  @override
  String get s_notif_categories_header => 'Kategóriák';

  @override
  String get s_notif_grades => 'Jegyek';

  @override
  String get s_notif_homework_tests => 'Házi feladatok és dolgozatok';

  @override
  String get s_notif_absences => 'Hiányzások';

  @override
  String get s_notif_lessons => 'Órarendváltozások';

  @override
  String get s_notif_lessons_cancelled => 'Elmaradt órák';

  @override
  String get s_notif_lessons_substituted => 'Helyettesítések';

  @override
  String get s_notif_messages => 'Üzenetek';

  @override
  String get s_progress_notification => 'Folyamatjelző értesítés';

  @override
  String get s_progress_notification_desc => 'Élő folyamatjelző értesítés a tanítási nap óráiról és szüneteiről';

  @override
  String get progress_notif_channel_name => 'Tanítási nap folyamata';

  @override
  String get progress_notif_channel_desc => 'Élő értesítés a mai órák és szünetek állapotáról';

  @override
  String progress_notif_lesson_title(String number, String name) {
    return '$number. óra: $name';
  }

  @override
  String get progress_notif_substitution => ' (Helyettesítés)';

  @override
  String progress_notif_case1_text(String minutes, String timeRange, String room, String substitution, String remaining) {
    return '$minutes perc múlva ($timeRange)$room$substitution$remaining';
  }

  @override
  String progress_notif_case2_lesson_text(String minutes, String timeRange, String room, String substitution, String remaining) {
    return '$minutes perc van hátra ($timeRange)$room$substitution$remaining';
  }

  @override
  String get progress_notif_case2_break_title => 'Szünet';

  @override
  String progress_notif_case2_break_text(String minutes, String remaining) {
    return '$minutes perc van hátra$remaining';
  }

  @override
  String progress_notif_critical_text(String minutes) {
    return '${minutes}p';
  }

  @override
  String get progress_notif_remaining_lessons_one => ' - Még 1 óra van hátra';

  @override
  String progress_notif_remaining_lessons_other(String count) {
    return ' - Még $count óra van hátra';
  }

  @override
  String get s_fcm_status_title => 'FCM állapot';

  @override
  String get s_fcm_status_initialized => 'Inicializálva';

  @override
  String get s_fcm_status_not_initialized => 'Nincs inicializálva';

  @override
  String get s_fcm_status_token_present => 'Token megvan';

  @override
  String get s_fcm_status_token_missing => 'Nincs token';

  @override
  String get s_fcm_status_permission_label => 'Értesítési engedély';

  @override
  String get s_fcm_status_permission_granted => 'Engedélyezve';

  @override
  String get s_fcm_status_permission_denied => 'Elutasítva';

  @override
  String get s_fcm_status_permission_unknown => 'Ismeretlen';

  @override
  String get s_fcm_status_topic_label => 'Feliratkozott téma';

  @override
  String get s_fcm_status_last_refresh_label => 'Utolsó token frissítés';

  @override
  String get s_fcm_status_last_refresh_never => 'Még nem történt';

  @override
  String get s_fcm_status_refresh_button => 'Frissítés';

  @override
  String get s_fcm_notify_on_message => 'Értesítés FCM üzenetkor';

  @override
  String get s_fcm_test_notifications_title => 'Teszt értesítések';

  @override
  String get s_fcm_test_notifications_multi_title => 'Több fiók szimulálása';

  @override
  String get s_n_all => 'Összes';

  @override
  String get s_n_grades => 'Új jegyek';

  @override
  String get s_n_homework_tests => 'Feladatok & Számonkérések';

  @override
  String get s_n_absences => 'Hiányzások';

  @override
  String get s_n_lessons => 'Órák';

  @override
  String get s_n_messages => 'Üzenetek';

  @override
  String get s_n_by_subject => 'Tantárgyak szerint';
}
