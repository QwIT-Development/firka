import WidgetKit
import SwiftUI

struct AveragesEntry: TimelineEntry {
    let date: Date
    let configuration: AveragesWidgetIntent
    let overallAverage: Double?
    let subjectAverages: [SubjectAverage]
    let locale: String
    let isFiltered: Bool
}

struct AveragesProvider: AppIntentTimelineProvider {
    typealias Entry = AveragesEntry
    typealias Intent = AveragesWidgetIntent

    func placeholder(in context: Context) -> AveragesEntry {
        AveragesEntry(
            date: Date(),
            configuration: AveragesWidgetIntent(),
            overallAverage: nil,
            subjectAverages: [],
            locale: "hu",
            isFiltered: false
        )
    }

    func snapshot(for configuration: AveragesWidgetIntent, in context: Context) async -> AveragesEntry {
        createEntry(for: configuration)
    }

    func timeline(for configuration: AveragesWidgetIntent, in context: Context) async -> Timeline<AveragesEntry> {
        let entry = createEntry(for: configuration)

        // Refresh every 30 minutes
        let refreshDate = Date().addingTimeInterval(30 * 60)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func createEntry(for configuration: AveragesWidgetIntent) -> AveragesEntry {
        let data = WidgetData.load()

        var subjectAverages = data?.averages.subjects ?? []
        let isFiltered = configuration.selectedSubjects?.isEmpty == false

        if isFiltered {
            let selectedIds = Set(configuration.selectedSubjects!.map { $0.id })
            subjectAverages = subjectAverages.filter { selectedIds.contains($0.uid) }
        }

        return AveragesEntry(
            date: Date(),
            configuration: configuration,
            overallAverage: data?.averages.overall,
            subjectAverages: subjectAverages,
            locale: data?.locale ?? "hu",
            isFiltered: isFiltered
        )
    }
}
