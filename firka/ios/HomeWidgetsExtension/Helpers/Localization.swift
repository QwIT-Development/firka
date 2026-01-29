import Foundation

struct WidgetLocalization {
    let locale: String

    init(locale: String = "hu") {
        self.locale = locale
    }

    private var translations: [String: [String: String]] {
        [
            "today_timetable": [
                "hu": "Mai órarend",
                "en": "Today's timetable",
                "de": "Stundenplan heute"
            ],
            "tomorrow_timetable": [
                "hu": "Holnapi órarend",
                "en": "Tomorrow's timetable",
                "de": "Stundenplan morgen"
            ],
            "current_lesson": [
                "hu": "Jelenlegi óra",
                "en": "Current lesson",
                "de": "Aktuelle Stunde"
            ],
            "next_lesson": [
                "hu": "Következő óra",
                "en": "Next lesson",
                "de": "Nächste Stunde"
            ],
            "recent_grades": [
                "hu": "Legutóbbi jegyek",
                "en": "Recent grades",
                "de": "Letzte Noten"
            ],
            "subject_averages": [
                "hu": "Tantárgyi átlagok",
                "en": "Subject averages",
                "de": "Fachdurchschnitte"
            ],
            "overall_average": [
                "hu": "Tanulmányi átlag",
                "en": "Overall average",
                "de": "Gesamtdurchschnitt"
            ],
            "no_lessons": [
                "hu": "Nincs több óra ma",
                "en": "No more lessons today",
                "de": "Keine Stunden mehr heute"
            ],
            "no_grades": [
                "hu": "Még nincsenek jegyeid",
                "en": "No grades yet",
                "de": "Noch keine Noten"
            ],
            "no_averages": [
                "hu": "Még nincsenek átlagok",
                "en": "No averages yet",
                "de": "Noch keine Durchschnitte"
            ],
            "login_required": [
                "hu": "Jelentkezz be újra",
                "en": "Please log in again",
                "de": "Bitte erneut anmelden"
            ],
            "timetable_unavailable": [
                "hu": "Az órarend még nem elérhető",
                "en": "Timetable not available yet",
                "de": "Stundenplan noch nicht verfügbar"
            ],
            "happy_break": [
                "hu": "Kellemes %@ szünetet!",
                "en": "Happy %@ break!",
                "de": "Schöne %@ Ferien!"
            ],
            "days_remaining": [
                "hu": "Még %d nap",
                "en": "%d days left",
                "de": "Noch %d Tage"
            ],
            "break_autumn": [
                "hu": "őszi",
                "en": "autumn",
                "de": "Herbst"
            ],
            "break_winter": [
                "hu": "téli",
                "en": "winter",
                "de": "Winter"
            ],
            "break_spring": [
                "hu": "tavaszi",
                "en": "spring",
                "de": "Frühlings"
            ],
            "break_summer": [
                "hu": "nyári",
                "en": "summer",
                "de": "Sommer"
            ],
            "room": [
                "hu": "Terem",
                "en": "Room",
                "de": "Raum"
            ],
            "until": [
                "hu": "eddig:",
                "en": "until",
                "de": "bis"
            ],
            "no_more_lessons_today": [
                "hu": "Ma már nincs több óra",
                "en": "No more lessons today",
                "de": "Keine Stunden mehr heute"
            ],
            "tomorrow": [
                "hu": "Holnap",
                "en": "Tomorrow",
                "de": "Morgen"
            ],
            "tomorrow_short": [
                "hu": "holnap",
                "en": "tmrw",
                "de": "morgen"
            ],
            "next": [
                "hu": "Következő",
                "en": "Next",
                "de": "Nächste"
            ],
            "minutes_short": [
                "hu": "perc",
                "en": "min",
                "de": "Min"
            ],
            "lesson_short": [
                "hu": "óra",
                "en": "lesson",
                "de": "Std"
            ],
            "in_minutes": [
                "hu": "%d perc múlva",
                "en": "in %d min",
                "de": "in %d Min"
            ],
            "today_new_grades": [
                "hu": "Ma: %d új jegy",
                "en": "Today: %d new",
                "de": "Heute: %d neue"
            ],
            "latest": [
                "hu": "Legutóbbi",
                "en": "Latest",
                "de": "Letzte"
            ],
            "today_grades": [
                "hu": "Mai jegyek",
                "en": "Today's grades",
                "de": "Heutige Noten"
            ],
            "pieces": [
                "hu": "%d db",
                "en": "%d pcs",
                "de": "%d Stk"
            ],
            "latest_grade": [
                "hu": "Legutóbbi jegy",
                "en": "Latest grade",
                "de": "Letzte Note"
            ],
            "average_short": [
                "hu": "Átlag",
                "en": "Avg",
                "de": "Durchschn."
            ],
            "overall_average_title": [
                "hu": "Összesített átlag",
                "en": "Overall average",
                "de": "Gesamtdurchschnitt"
            ],
            "subjects_count": [
                "hu": "%d tárgy",
                "en": "%d subjects",
                "de": "%d Fächer"
            ],
            "subject_averages_title": [
                "hu": "Tantárgy átlagok",
                "en": "Subject averages",
                "de": "Fachdurchschnitte"
            ],
            "subject_short": [
                "hu": "tárgy",
                "en": "subj",
                "de": "Fächer"
            ],
            "minutes_abbrev": [
                "hu": "p",
                "en": "min",
                "de": "Min"
            ],
            "hours_abbrev": [
                "hu": "ó",
                "en": "h",
                "de": "Std"
            ],
            "in_hours": [
                "hu": "%d óra múlva",
                "en": "in %d h",
                "de": "in %d Std"
            ]
        ]
    }

    func string(_ key: String) -> String {
        translations[key]?[locale] ?? translations[key]?["hu"] ?? key
    }

    func string(_ key: String, _ arg: String) -> String {
        let template = string(key)
        return template.replacingOccurrences(of: "%@", with: arg)
    }

    func string(_ key: String, _ arg: Int) -> String {
        let template = string(key)
        return template.replacingOccurrences(of: "%d", with: "\(arg)")
    }
}
