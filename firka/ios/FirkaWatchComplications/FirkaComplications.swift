#if os(watchOS)
import WidgetKit
import SwiftUI

// MARK: - Complication Localization Helper

private struct ComplicationL10n {
    private static let appGroupID = "group.app.firka.firkaa"

    enum Language: String {
        case hungarian = "hu"
        case english = "en"
        case german = "de"
    }

    static var currentLanguage: Language {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return .hungarian
        }
        let code = defaults.string(forKey: "watch_language") ?? "hu"
        return Language(rawValue: code) ?? .hungarian
    }

    static func string(_ key: String) -> String {
        switch currentLanguage {
        case .hungarian: return hungarianStrings[key] ?? key
        case .english: return englishStrings[key] ?? key
        case .german: return germanStrings[key] ?? key
        }
    }

    private static let hungarianStrings: [String: String] = [
        "current_lesson": "Jelenlegi óra",
        "next": "Következő",
        "no_more_lessons": "Nincs több óra",
        "average_abbrev": "Átl",
        "next_lesson_title": "Következő óra",
        "average_title": "Átlag",
        "lesson_inline": "Óra (inline)"
    ]

    private static let englishStrings: [String: String] = [
        "current_lesson": "Current Lesson",
        "next": "Next",
        "no_more_lessons": "No more lessons",
        "average_abbrev": "Avg",
        "next_lesson_title": "Next Lesson",
        "average_title": "Average",
        "lesson_inline": "Lesson (inline)"
    ]

    private static let germanStrings: [String: String] = [
        "current_lesson": "Aktuelle Stunde",
        "next": "Nächste",
        "no_more_lessons": "Keine Stunden mehr",
        "average_abbrev": "Ø",
        "next_lesson_title": "Nächste Stunde",
        "average_title": "Durchschnitt",
        "lesson_inline": "Stunde (inline)"
    ]
}

// MARK: - Watch Cache Loader

private struct WatchCacheLoader {
    private static let appGroupID = "group.app.firka.firkaa"
    private static let cacheFileName = "watch_data.json"

    static func loadWidgetData() -> WidgetData? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            print("[WatchComplication] No App Group container")
            return nil
        }

        let fileURL = containerURL.appendingPathComponent(cacheFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("[WatchComplication] Cache file not found: \(fileURL.path)")
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            print("[WatchComplication] Could not read cache file")
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct CachedWatchData: Codable {
            let widgetData: WidgetData
            let lastUpdated: Date
        }

        do {
            let cached = try decoder.decode(CachedWatchData.self, from: data)
            print("[WatchComplication] Loaded cache from \(cached.lastUpdated)")
            return cached.widgetData
        } catch {
            print("[WatchComplication] Failed to decode: \(error)")
            return nil
        }
    }
}

// MARK: - Timeline Entry

struct FirkaTimelineEntry: TimelineEntry {
    let date: Date
    let data: WidgetData?
}

// MARK: - Timeline Provider

struct FirkaTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FirkaTimelineEntry {
        FirkaTimelineEntry(date: Date(), data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (FirkaTimelineEntry) -> Void) {
        let data = WatchCacheLoader.loadWidgetData()
        completion(FirkaTimelineEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FirkaTimelineEntry>) -> Void) {
        let data = WatchCacheLoader.loadWidgetData()
        let entry = FirkaTimelineEntry(date: Date(), data: data)

        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let isSchoolHours = (weekday >= 2 && weekday <= 6) && (hour >= 6 && hour <= 16)

        let refreshInterval: TimeInterval = isSchoolHours ? 15 * 60 : 60 * 60
        let nextRefresh = now.addingTimeInterval(refreshInterval)

        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }
}

// MARK: - Next Lesson Complication (accessoryRectangular)

struct NextLessonComplication: Widget {
    let kind = "NextLessonComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FirkaTimelineProvider()) { entry in
            NextLessonView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(ComplicationL10n.string("next_lesson_title"))
        .description("Shows the current or next lesson.")
        .supportedFamilies([.accessoryRectangular])
    }
}

private struct NextLessonView: View {
    let entry: FirkaTimelineEntry

    private var now: Date { Date() }

    private var todayLessons: [WidgetLesson] {
        (entry.data?.timetable.today ?? []).sorted { $0.start < $1.start }
    }

    private var currentLesson: WidgetLesson? {
        todayLessons.first { now >= $0.start && now <= $0.end }
    }

    private var nextLesson: WidgetLesson? {
        todayLessons.first { $0.start > now }
    }

    var body: some View {
        if let breakInfo = entry.data?.timetable.currentBreak {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: SeasonalIconHelper.iconName(for: breakInfo.nameKey, season: nil))
                        .font(.caption)
                    Text(breakInfo.name)
                        .font(.headline)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let lesson = currentLesson {
            VStack(alignment: .leading, spacing: 2) {
                Text(ComplicationL10n.string("current_lesson"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(lesson.displayName)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let room = lesson.roomName {
                        Image(systemName: "door.right.hand.closed")
                            .font(.caption2)
                        Text(room)
                            .font(.caption2)
                    }
                    Text("→ \(lesson.end, formatter: Self.timeFormatter)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let lesson = nextLesson {
            VStack(alignment: .leading, spacing: 2) {
                Text(ComplicationL10n.string("next"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(lesson.displayName)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let room = lesson.roomName {
                        Image(systemName: "door.right.hand.closed")
                            .font(.caption2)
                        Text(room)
                            .font(.caption2)
                    }
                    Text(lesson.start, formatter: Self.timeFormatter)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if entry.data != nil {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                Text(ComplicationL10n.string("no_more_lessons"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: "book.fill")
                    .font(.title3)
                Text("Firka")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}

// MARK: - Average Complication (accessoryCircular)

struct AverageComplication: Widget {
    let kind = "AverageComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FirkaTimelineProvider()) { entry in
            AverageView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(ComplicationL10n.string("average_title"))
        .description("Shows the overall grade average.")
        .supportedFamilies([.accessoryCircular])
    }
}

private struct AverageView: View {
    let entry: FirkaTimelineEntry

    private var averageColor: Color {
        guard let avg = entry.data?.averages.overall else { return .gray }
        switch avg {
        case 4.5...: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }

    var body: some View {
        if let average = entry.data?.averages.overall {
            Gauge(value: average, in: 1...5) {
                Text(ComplicationL10n.string("average_abbrev"))
            } currentValueLabel: {
                Text(String(format: "%.1f", average))
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(averageColor)
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Text("—")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
    }
}

// MARK: - Inline Complication (accessoryInline)

struct InlineComplication: Widget {
    let kind = "InlineComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FirkaTimelineProvider()) { entry in
            InlineView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(ComplicationL10n.string("lesson_inline"))
        .description("One-line summary of the next lesson.")
        .supportedFamilies([.accessoryInline])
    }
}

private struct InlineView: View {
    let entry: FirkaTimelineEntry

    private var now: Date { Date() }

    private var todayLessons: [WidgetLesson] {
        (entry.data?.timetable.today ?? []).sorted { $0.start < $1.start }
    }

    private var currentOrNextLesson: WidgetLesson? {
        todayLessons.first { now >= $0.start && now <= $0.end }
            ?? todayLessons.first { $0.start > now }
    }

    var body: some View {
        if let breakInfo = entry.data?.timetable.currentBreak {
            Text(breakInfo.name)
        } else if let lesson = currentOrNextLesson {
            Text("\(lesson.displayName) \(lesson.start, formatter: Self.timeFormatter)")
        } else if entry.data != nil {
            Text(ComplicationL10n.string("no_more_lessons"))
        } else {
            Text("Firka")
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}

// MARK: - Widget Bundle

@main
struct FirkaWatchWidgets: WidgetBundle {
    var body: some Widget {
        NextLessonComplication()
        AverageComplication()
        InlineComplication()
    }
}
#endif
