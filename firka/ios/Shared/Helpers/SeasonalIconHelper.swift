import SwiftUI

struct SeasonalIconHelper {
    static func iconName(for mode: String?, season: String?, lessonIcon: String? = nil) -> String {
        guard let mode = mode else {
            return lessonIcon ?? "book.fill"
        }

        switch mode {
        case "xmas":
            return "gift.fill"
        case "newYearEve":
            return "party.popper.fill"
        case "newYearDay":
            return "sparkles"
        case "beforeSchool":
            return "sun.horizon.fill"
        case "seasonalBreak":
            guard let season = season else {
                return "snowflake"
            }
            switch season {
            case "spring":
                return "flower.fill"
            case "summer":
                return "sun.max.fill"
            case "autumn":
                return "leaf.fill"
            case "winter":
                return "snowflake"
            case "other":
                return "calendar.badge.exclamationmark"
            default:
                return "snowflake"
            }
        case "lesson":
            return lessonIcon ?? "book.fill"
        default:
            return lessonIcon ?? "book.fill"
        }
    }

    static func iconColor(for mode: String?, season: String? = nil) -> Color {
        guard let mode = mode else {
            return .green
        }

        switch mode {
        case "beforeSchool":
            return .orange
        case "xmas":
            return .red
        case "newYearEve":
            return .purple
        case "newYearDay":
            return Color(red: 0.4, green: 0.9, blue: 0.8)
        case "seasonalBreak":
            return seasonColor(for: season)
        default:
            return .green
        }
    }

    static func seasonColor(for season: String?) -> Color {
        guard let season = season else {
            return .blue
        }

        switch season {
        case "spring":
            return .green
        case "summer":
            return .blue
        case "autumn":
            return .orange
        case "winter":
            return Color(red: 0.4, green: 0.8, blue: 1.0)
        case "other":
            return .blue
        default:
            return .blue
        }
    }

    static func isSeasonalMode(_ mode: String?) -> Bool {
        guard let mode = mode else {
            return false
        }
        return mode == "seasonalBreak" || mode == "xmas" || mode == "newYearEve" || mode == "newYearDay"
    }
}

