import WidgetKit
import SwiftUI

struct AveragesWidget: Widget {
    let kind: String = "AveragesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: AveragesWidgetIntent.self,
            provider: AveragesProvider()
        ) { entry in
            AveragesWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(LocalizedStringResource("widget_averages_title", defaultValue: "Averages"))
        .description(LocalizedStringResource("widget_averages_description", defaultValue: "Shows subject averages"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct AveragesWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: AveragesEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.locale)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                AveragesSmallView(entry: entry, localization: localization)
            case .systemMedium:
                AveragesMediumView(entry: entry, localization: localization)
            case .systemLarge:
                AveragesLargeView(entry: entry, localization: localization)
            default:
                AveragesMediumView(entry: entry, localization: localization)
            }
        }
        .widgetURL(URL(string: "firka://widget/grades"))
    }
}
