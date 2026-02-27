import Foundation
import SwiftUI
import WidgetKit

enum WatchLanguage: String, CaseIterable, Codable {
    case hungarian = "hu"
    case english = "en"
    case german = "de"

    var displayName: String {
        switch self {
        case .hungarian: return "Magyar"
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }

    var flag: String {
        switch self {
        case .hungarian: return "🇭🇺"
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"
        }
    }
}

@Observable
class WatchL10n {
    static let shared = WatchL10n()

    private let languageKey = "watch_language"
    private let syncWithiPhoneKey = "watch_sync_language_with_iphone"
    private let lastAppliedSharedLanguageVersionKey = "watch_last_applied_shared_language_version"
    private static let appGroupID = "group.app.firka.firkaa"
    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupID)
    }

    var currentLanguage: WatchLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
            appGroupDefaults?.set(currentLanguage.rawValue, forKey: languageKey)
        }
    }

    var syncWithiPhone: Bool {
        didSet {
            UserDefaults.standard.set(syncWithiPhone, forKey: syncWithiPhoneKey)
            appGroupDefaults?.set(syncWithiPhone, forKey: syncWithiPhoneKey)
            if syncWithiPhone {
                refreshFromiPhoneAndSharedState()
            }
        }
    }

    private var strings: [String: String] = [:]

    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: languageKey) ?? "hu"
        self.currentLanguage = WatchLanguage(rawValue: savedLanguage) ?? .hungarian
        if let storedSyncPref = UserDefaults.standard.object(forKey: syncWithiPhoneKey) as? Bool {
            self.syncWithiPhone = storedSyncPref
        } else {
            self.syncWithiPhone = true
            UserDefaults.standard.set(true, forKey: syncWithiPhoneKey)
            appGroupDefaults?.set(true, forKey: syncWithiPhoneKey)
        }
        appGroupDefaults?.set(currentLanguage.rawValue, forKey: languageKey)
        loadStrings()
    }

    private func loadStrings() {
        strings = Self.stringsForLanguage(currentLanguage)
    }

    func setLanguage(_ language: WatchLanguage) {
        if Thread.isMainThread {
            currentLanguage = language
            loadStrings()
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            DispatchQueue.main.async { [self] in
                currentLanguage = language
                loadStrings()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    func updateFromiPhone(languageCode: String, sharedStateVersion: Int64? = nil) {
        guard syncWithiPhone else { return }
        let lastAppliedVersion = lastAppliedSharedLanguageVersion()
        if let sharedStateVersion,
           sharedStateVersion > 0,
           sharedStateVersion < lastAppliedVersion {
            print("[WatchL10n] Ignoring stale WC language update (version: \(sharedStateVersion), lastApplied: \(lastAppliedVersion))")
            return
        }

        if let language = WatchLanguage(rawValue: languageCode) {
            if language != currentLanguage {
                setLanguage(language)
            }
            if let sharedStateVersion, sharedStateVersion > 0 {
                setLastAppliedSharedLanguageVersion(max(lastAppliedVersion, sharedStateVersion))
            }
        }
    }

    private func parseInt64(_ value: Any?) -> Int64? {
        if let value = value as? Int64 { return value }
        if let value = value as? Int { return Int64(value) }
        if let value = value as? Double { return Int64(value) }
        if let value = value as? String, let parsed = Int64(value) { return parsed }
        return nil
    }

    private func lastAppliedSharedLanguageVersion() -> Int64 {
        parseInt64(UserDefaults.standard.object(forKey: lastAppliedSharedLanguageVersionKey)) ?? 0
    }

    private func setLastAppliedSharedLanguageVersion(_ value: Int64) {
        UserDefaults.standard.set(value, forKey: lastAppliedSharedLanguageVersionKey)
    }

    func resetLanguageVersionTracking() {
        setLastAppliedSharedLanguageVersion(0)
        print("[WatchL10n] Language version tracking reset for account switch")
    }

    func reconcileFromSharedState() {
        guard syncWithiPhone else { return }
        guard let sharedState = SharedLanguageStateManager.shared.loadState() else { return }
        let lastAppliedVersion = lastAppliedSharedLanguageVersion()
        guard sharedState.stateVersion > lastAppliedVersion else { return }

        if let language = WatchLanguage(rawValue: sharedState.languageCode) {
            if language != currentLanguage {
                setLanguage(language)
            }
            setLastAppliedSharedLanguageVersion(sharedState.stateVersion)
        }
    }

    func refreshFromiPhoneAndSharedState() {
        guard syncWithiPhone else { return }
        requestLanguageFromiPhone()
        reconcileFromSharedState()
    }

    private func requestLanguageFromiPhone() {
        WatchConnectivityManager.shared.requestLanguageFromPhone()
    }

    func string(_ key: String) -> String {
        return strings[key] ?? key
    }

    func string(_ key: String, _ args: CVarArg...) -> String {
        let format = strings[key] ?? key
        return String(format: format, arguments: args)
    }

    static func stringsForLanguage(_ language: WatchLanguage) -> [String: String] {
        switch language {
        case .hungarian:
            return hungarianStrings
        case .english:
            return englishStrings
        case .german:
            return germanStrings
        }
    }

    private static let hungarianStrings: [String: String] = [
        // Home View
        "current_lesson": "Jelenlegi óra",
        "next": "Következő",
        "break": "Szünet",
        "next_lesson": "Következő: %@",
        "first_lesson": "Első órád",
        "today_lessons_count": "Ma %d órád van",
        "no_more_lessons": "Ma nincs több órád",
        "pair_with_iphone": "Párosítsd az iPhone-oddal",
        "open_firka_on_iphone": "Nyisd meg a Firka appot az iPhone-odon",
        "login_on_iphone": "Jelentkezz be iPhone-on",
        "open_and_login_on_iphone": "Nyisd meg a Firka appot iPhone-on, és lépj be egy fiókba",
        "updated": "Frissítve: %@",
        "minutes": "perc",
        "time_now": "most",
        "time_hours_minutes": "%d ó %d p",
        "time_hours": "%d óra",
        "time_minutes_only": "%d perc",
        "time_since_minutes_one": "1 perce",
        "time_since_minutes_many": "%d perce",
        "time_since_hours_one": "1 órája",
        "time_since_hours_many": "%d órája",
        "time_since_days_one": "1 napja",
        "time_since_days_many": "%d napja",

        // Timetable View
        "free_day": "Szabad nap",
        "lesson_number": "%d. óra",
        "day_mon": "H",
        "day_tue": "K",
        "day_wed": "Sz",
        "day_thu": "Cs",
        "day_fri": "P",

        // Grades View
        "grades_count": "%d jegy",
        "total_average": "Teljes átlag",
        "average": "Átlag:",
        "no_data": "Nincs adat",
        "no_grades": "Nincsenek jegyek",

        // Lesson Detail
        "lesson_details": "Óra részletei",
        "cancelled": "Elmarad",
        "substitution": "Helyettesítés",
        "teacher": "Tanár",
        "room": "Terem",
        "topic": "Téma",

        // Settings
        "settings": "Beállítások",
        "refresh_interval": "Frissítési időköz",
        "auto": "Automatikus",
        "15_minutes": "15 perc",
        "30_minutes": "30 perc",
        "1_hour": "1 óra",
        "version": "Verzió",
        "language": "Nyelv",
        "sync_with_iphone": "iPhone nyelvével",
        "clear_cache": "Cache törlése",
        "logout": "Kijelentkezés",

        // Refresh
        "refresh": "Frissítés",
        "refreshing": "Frissítés...",
        "refresh_success": "Sikeres!",
        "refresh_failed": "Sikertelen",
        "error_api": "Kréta API hiba",
        "error_network": "Hálózati hiba",

        // Date labels
        "tomorrow_first_lesson": "Holnap első órád",
        "day_first_lesson": "%@ első órád",
        "next_school_day": "Következő iskolai nap",

        // Navigation
        "home": "Kezdőlap",
        "timetable": "Órarend",
        "grades": "Jegyek",

        // Reauth
        "reauth_required": "Újrabelépés szükséges",
        "reauth_description": "A munkamenet lejárt. Lépj be újra az iPhone appban.",
        "sync_button": "Szinkronizálás",
        "syncing": "Szinkronizálás...",
        "sync_success": "Sikeres!",
        "sync_failed": "Sikertelen",
        "phone_not_reachable": "iPhone nem elérhető",
        "connecting": "Kapcsolódás...",
        "recovering_token": "Token helyreállítása...",
    ]

    private static let englishStrings: [String: String] = [
        // Home View
        "current_lesson": "Current Lesson",
        "next": "Next",
        "break": "Break",
        "next_lesson": "Next: %@",
        "first_lesson": "First Lesson",
        "today_lessons_count": "You have %d lessons today",
        "no_more_lessons": "No more lessons today",
        "pair_with_iphone": "Pair with iPhone",
        "open_firka_on_iphone": "Open Firka app on your iPhone",
        "login_on_iphone": "Sign in on iPhone",
        "open_and_login_on_iphone": "Open Firka on your iPhone and sign in to an account",
        "updated": "Updated: %@",
        "minutes": "min",
        "time_now": "now",
        "time_hours_minutes": "%dh %dm",
        "time_hours": "%d hours",
        "time_minutes_only": "%d min",
        "time_since_minutes_one": "1 min ago",
        "time_since_minutes_many": "%d mins ago",
        "time_since_hours_one": "1 hour ago",
        "time_since_hours_many": "%d hours ago",
        "time_since_days_one": "1 day ago",
        "time_since_days_many": "%d days ago",

        // Timetable View
        "free_day": "Free Day",
        "lesson_number": "Lesson %d",
        "day_mon": "Mon",
        "day_tue": "Tue",
        "day_wed": "Wed",
        "day_thu": "Thu",
        "day_fri": "Fri",

        // Grades View
        "grades_count": "%d grades",
        "total_average": "Total Average",
        "average": "Average:",
        "no_data": "No data",
        "no_grades": "No grades",

        // Lesson Detail
        "lesson_details": "Lesson Details",
        "cancelled": "Cancelled",
        "substitution": "Substitution",
        "teacher": "Teacher",
        "room": "Room",
        "topic": "Topic",

        // Settings
        "settings": "Settings",
        "refresh_interval": "Refresh Interval",
        "auto": "Auto",
        "15_minutes": "15 minutes",
        "30_minutes": "30 minutes",
        "1_hour": "1 hour",
        "version": "Version",
        "language": "Language",
        "sync_with_iphone": "Sync with iPhone",
        "clear_cache": "Clear Cache",
        "logout": "Log Out",

        // Refresh
        "refresh": "Refresh",
        "refreshing": "Refreshing...",
        "refresh_success": "Success!",
        "refresh_failed": "Failed",
        "error_api": "Kréta API Error",
        "error_network": "Network Error",

        // Date labels
        "tomorrow_first_lesson": "Tomorrow's first lesson",
        "day_first_lesson": "%@'s first lesson",
        "next_school_day": "Next school day",

        // Navigation
        "home": "Home",
        "timetable": "Timetable",
        "grades": "Grades",

        // Reauth
        "reauth_required": "Re-login Required",
        "reauth_description": "Your session has expired. Please log in again on your iPhone.",
        "sync_button": "Sync",
        "syncing": "Syncing...",
        "sync_success": "Success!",
        "sync_failed": "Failed",
        "phone_not_reachable": "iPhone not reachable",
        "connecting": "Connecting...",
        "recovering_token": "Recovering session...",
    ]

    private static let germanStrings: [String: String] = [
        // Home View
        "current_lesson": "Aktuelle Stunde",
        "next": "Nächste",
        "break": "Pause",
        "next_lesson": "Nächste: %@",
        "first_lesson": "Erste Stunde",
        "today_lessons_count": "Du hast heute %d Stunden",
        "no_more_lessons": "Keine Stunden mehr heute",
        "pair_with_iphone": "Mit iPhone koppeln",
        "open_firka_on_iphone": "Öffne Firka auf deinem iPhone",
        "login_on_iphone": "Auf iPhone anmelden",
        "open_and_login_on_iphone": "Öffne Firka auf deinem iPhone und melde dich mit einem Konto an",
        "updated": "Aktualisiert: %@",
        "minutes": "Min",
        "time_now": "jetzt",
        "time_hours_minutes": "%d Std %d Min",
        "time_hours": "%d Stunden",
        "time_minutes_only": "%d Min",
        "time_since_minutes_one": "vor 1 Min",
        "time_since_minutes_many": "vor %d Min",
        "time_since_hours_one": "vor 1 Std",
        "time_since_hours_many": "vor %d Std",
        "time_since_days_one": "vor 1 Tag",
        "time_since_days_many": "vor %d Tagen",

        // Timetable View
        "free_day": "Freier Tag",
        "lesson_number": "%d. Stunde",
        "day_mon": "Mo",
        "day_tue": "Di",
        "day_wed": "Mi",
        "day_thu": "Do",
        "day_fri": "Fr",

        // Grades View
        "grades_count": "%d Noten",
        "total_average": "Gesamtdurchschnitt",
        "average": "Durchschnitt:",
        "no_data": "Keine Daten",
        "no_grades": "Keine Noten",

        // Lesson Detail
        "lesson_details": "Stundendetails",
        "cancelled": "Entfällt",
        "substitution": "Vertretung",
        "teacher": "Lehrer",
        "room": "Raum",
        "topic": "Thema",

        // Settings
        "settings": "Einstellungen",
        "refresh_interval": "Aktualisierungsintervall",
        "auto": "Automatisch",
        "15_minutes": "15 Minuten",
        "30_minutes": "30 Minuten",
        "1_hour": "1 Stunde",
        "version": "Version",
        "language": "Sprache",
        "sync_with_iphone": "Mit iPhone synchronisieren",
        "clear_cache": "Cache löschen",
        "logout": "Abmelden",

        // Refresh
        "refresh": "Aktualisieren",
        "refreshing": "Wird aktualisiert...",
        "refresh_success": "Erfolgreich!",
        "refresh_failed": "Fehlgeschlagen",
        "error_api": "Kréta API Fehler",
        "error_network": "Netzwerkfehler",

        // Date labels
        "tomorrow_first_lesson": "Morgen erste Stunde",
        "day_first_lesson": "%@ erste Stunde",
        "next_school_day": "Nächster Schultag",

        // Navigation
        "home": "Startseite",
        "timetable": "Stundenplan",
        "grades": "Noten",

        // Reauth
        "reauth_required": "Erneute Anmeldung erforderlich",
        "reauth_description": "Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut auf dem iPhone an.",
        "sync_button": "Synchronisieren",
        "syncing": "Synchronisierung...",
        "sync_success": "Erfolgreich!",
        "sync_failed": "Fehlgeschlagen",
        "phone_not_reachable": "iPhone nicht erreichbar",
        "connecting": "Verbindung...",
        "recovering_token": "Sitzung wiederherstellen...",
    ]
}

extension String {
    var localized: String {
        WatchL10n.shared.string(self)
    }

    func localized(_ args: CVarArg...) -> String {
        let format = WatchL10n.shared.string(self)
        return String(format: format, arguments: args)
    }
}
