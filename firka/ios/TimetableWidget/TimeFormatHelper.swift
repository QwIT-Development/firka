import Foundation

struct TimeFormatHelper {
    static func compactTime(remaining: TimeInterval) -> String {
        let lang = Locale.current.languageCode ?? "hu"

        let hours = Int(max(0, remaining)) / 3600
        let minutes = (Int(max(0, remaining)) % 3600) / 60

        if hours >= 1 {
            return shortHours(hours, language: lang)
        } else {
            return shortMinutes(minutes, language: lang)
        }
    }

    static func compactSeasonalBreak(from message: String) -> String {
        let lang = Locale.current.languageCode ?? "hu"

        let components = message.split(separator: " ")
        let number = components.first.map(String.init) ?? ""

        let isDay = message.lowercased().contains("day") ||
                    message.lowercased().contains("nap") ||
                    message.lowercased().contains("tag")

        if isDay {
            return shortDays(Int(number) ?? 0, language: lang)
        } else {
            return shortHours(Int(number) ?? 0, language: lang)
        }
    }

    // MARK: - Private Helpers

    private static func shortHours(_ hours: Int, language: String) -> String {
        switch language {
        case "en": return "\(hours)h"
        case "de": return "\(hours)h"
        case "hu": return "\(hours)ó"
        default: return "\(hours)h"
        }
    }

    private static func shortMinutes(_ minutes: Int, language: String) -> String {
        switch language {
        case "en": return "\(minutes)m"
        case "de": return "\(minutes)m"
        case "hu": return "\(minutes)p"
        default: return "\(minutes)m"
        }
    }

    private static func shortDays(_ days: Int, language: String) -> String {
        switch language {
        case "en": return "\(days)d"
        case "de": return "\(days)d"
        case "hu": return "\(days)n"
        default: return "\(days)d"
        }
    }
}
