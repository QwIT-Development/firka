import SwiftUI

struct SeasonalIconHelper {
    static func iconName(for mode: String?, season: String?) -> String {
        guard let mode = mode else {
            return "book.fill"
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
        default:
            return "book.fill"
        }
    }

    static func iconColor(for mode: String?) -> Color {
        guard let mode = mode else {
            return .green
        }
        
        switch mode {
        case "beforeSchool":
            return .orange
        case "xmas", "newYearEve", "newYearDay", "seasonalBreak":
            return .green
        default:
            return .green
        }
    }

    static func isSeasonalMode(_ mode: String?) -> Bool {
        guard let mode = mode else {
            return false
        }
        return mode == "seasonalBreak" || mode == "xmas" || mode == "newYearEve" || mode == "newYearDay"
    }
}

