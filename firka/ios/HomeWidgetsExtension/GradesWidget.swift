import WidgetKit
import SwiftUI

struct GradesWidget: Widget {
    let kind: String = "GradesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GradesWidgetIntent.self,
            provider: GradesProvider()
        ) { entry in
            GradesWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(LocalizedStringResource("widget_grades_title", defaultValue: "Recent Grades"))
        .description(LocalizedStringResource("widget_grades_description", defaultValue: "Shows your recent grades"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct GradesWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: GradesEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.locale)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                GradesSmallView(entry: entry, localization: localization)
            case .systemMedium:
                GradesMediumView(entry: entry, localization: localization)
            case .systemLarge:
                GradesLargeView(entry: entry, localization: localization)
            default:
                GradesMediumView(entry: entry, localization: localization)
            }
        }
        .widgetURL(URL(string: "firka://widget/grades"))
    }
}
