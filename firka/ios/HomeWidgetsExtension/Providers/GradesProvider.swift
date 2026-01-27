import WidgetKit
import SwiftUI

struct GradesEntry: TimelineEntry {
    let date: Date
    let configuration: GradesWidgetIntent
    let grades: [WidgetGrade]
    let locale: String
}

struct GradesProvider: AppIntentTimelineProvider {
    typealias Entry = GradesEntry
    typealias Intent = GradesWidgetIntent

    func placeholder(in context: Context) -> GradesEntry {
        GradesEntry(date: Date(), configuration: GradesWidgetIntent(), grades: [], locale: "hu")
    }

    func snapshot(for configuration: GradesWidgetIntent, in context: Context) async -> GradesEntry {
        let data = WidgetData.load()
        return GradesEntry(
            date: Date(),
            configuration: configuration,
            grades: data?.grades ?? [],
            locale: data?.locale ?? "hu"
        )
    }

    func timeline(for configuration: GradesWidgetIntent, in context: Context) async -> Timeline<GradesEntry> {
        let data = WidgetData.load()
        let entry = GradesEntry(
            date: Date(),
            configuration: configuration,
            grades: data?.grades ?? [],
            locale: data?.locale ?? "hu"
        )

        let refreshDate = Date().addingTimeInterval(30 * 60)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}
