import WidgetKit
import SwiftUI

struct TimetableWidget: Widget {
    let kind: String = "TimetableWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TimetableWidgetIntent.self,
            provider: TimetableProvider()
        ) { entry in
            TimetableWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(LocalizedStringResource("widget_timetable_title", defaultValue: "Timetable"))
        .description(LocalizedStringResource("widget_timetable_description", defaultValue: "Shows your daily timetable"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TimetableWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: TimetableEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.data?.locale ?? "hu")
    }

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var body: some View {
        switch entry.state {
        case .onBreak:
            if let breakInfo = entry.breakInfo {
                BreakView(breakInfo: breakInfo, localization: localization, style: style)
            }
        case .loginRequired:
            EmptyStateView(message: localization.string("login_required"), style: style)
        case .unavailable:
            EmptyStateView(message: localization.string("timetable_unavailable"), style: style)
        case .noMoreLessons, .normal:
            switch family {
            case .systemSmall:
                TimetableSmallView(entry: entry, localization: localization)
            case .systemMedium:
                TimetableMediumView(entry: entry, localization: localization)
            case .systemLarge:
                TimetableLargeView(entry: entry, localization: localization)
            default:
                TimetableMediumView(entry: entry, localization: localization)
            }
        }
    }
}
