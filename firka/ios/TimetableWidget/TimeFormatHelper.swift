import Foundation
import ActivityKit

struct TimeFormatHelper {
    static func compactTime(remaining: TimeInterval, labels: TimetableActivityAttributes.ContentState.Labels?) -> String {
        let lang = detectLanguage(from: labels)

        let hours = Int(max(0, remaining)) / 3600
        let minutes = (Int(max(0, remaining)) % 3600) / 60

        if hours >= 1 {
            return shortHours(hours, language: lang)
        } else {
            return shortMinutes(minutes, language: lang)
        }
    }

    static func compactSeasonalBreak(from message: String, labels: TimetableActivityAttributes.ContentState.Labels?) -> String {
        let lang = detectLanguage(from: labels)

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

    // MARK: - Language Detection

    private static func detectLanguage(from labels: TimetableActivityAttributes.ContentState.Labels?) -> String {
        guard let labels = labels else {
            return Locale.current.languageCode ?? "hu"
        }

        if let text = labels.remainingLabel ?? labels.cancelledText {
            let lower = text.lowercased()

            if lower.contains("time") || lower.contains("remaining") || lower.contains("cancelled") {
                return "en"
            } else if lower.contains("verbleibende") || lower.contains("zeit") || lower.contains("entfallen") {
                return "de"
            } else {
                return "hu"
            }
        }

        return Locale.current.languageCode ?? "hu"
    }

    // MARK: - Private Helpers

    private static func shortHours(_ hours: Int, language: String) -> String {
        switch language {
        case "en": return "\(hours)h"
        case "de": return "\(hours)td"
        case "hu": return "\(hours)ó"
        default: return "\(hours)h"
        }
    }

    private static func shortMinutes(_ minutes: Int, language: String) -> String {
        switch language {
        case "en": return "\(minutes)m"
        case "de": return "\(minutes)Min"
        case "hu": return "\(minutes)p"
        default: return "\(minutes)m"
        }
    }

    private static func shortDays(_ days: Int, language: String) -> String {
        switch language {
        case "en": return "\(days)d"
        case "de": return "\(days)T"
        case "hu": return "\(days)n"
        default: return "\(days)d"
        }
    }
}
