import WidgetKit
import SwiftUI

// MARK: - Timetable Inline Widget

struct TimetableInlineWidget: Widget {
    let kind: String = "TimetableInlineWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TimetableWidgetIntent.self,
            provider: TimetableProvider()
        ) { entry in
            TimetableInlineWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(LocalizedStringResource("widget_timetable_title", defaultValue: "Timetable"))
        .description(LocalizedStringResource("widget_timetable_inline_description", defaultValue: "Shows next lesson above the clock"))
        .supportedFamilies([.accessoryInline])
    }
}

struct TimetableInlineWidgetView: View {
    let entry: TimetableEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.data?.locale ?? "hu")
    }

    var body: some View {
        if entry.state == .onBreak, let breakInfo = entry.breakInfo {
            Text(localization.string(breakInfo.nameKey))
        } else if let current = entry.currentLesson {
            let remaining = minutesRemaining(until: current.end)
            Text("\(current.subject.name) · \(remaining) \(localization.string("minutes_abbrev"))")
        } else if entry.isNextSchoolDay {
            if let first = entry.lessons.first {
                let dateStr = WidgetLocalization.formatShortDate(entry.nextSchoolDayDateString, locale: localization.locale)
                let lessonNum = first.lessonNumber ?? 1
                Text("\(dateStr): \(lessonNum). \(first.subject.name)")
            } else {
                Text(localization.string("no_lessons_ahead"))
            }
        } else if entry.isNextDay {
            if let first = entry.lessons.first {
                let lessonNum = first.lessonNumber ?? 1
                Text("\(localization.string("tomorrow")): \(lessonNum). \(first.subject.name)")
            } else {
                Text(localization.string("no_lessons_ahead"))
            }
        } else if let next = entry.nextLesson {
            let until = minutesRemaining(until: next.start)
            if until <= 0 {
                Text("→ \(next.subject.name)")
            } else if until > 60 {
                let hours = until / 60
                Text("→ \(next.subject.name) · \(hours) \(localization.string("hours_abbrev"))")
            } else {
                Text("→ \(next.subject.name) · \(until) \(localization.string("minutes_abbrev"))")
            }
        } else {
            Text(localization.string("no_lessons_ahead"))
        }
    }

    private func minutesRemaining(until date: Date) -> Int {
        let diff = date.timeIntervalSince(entry.date)
        return max(0, Int(ceil(diff / 60)))
    }
}

// MARK: - Grades Inline Widget

struct GradesInlineWidget: Widget {
    let kind: String = "GradesInlineWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GradesWidgetIntent.self,
            provider: GradesProvider()
        ) { entry in
            GradesInlineWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(LocalizedStringResource("widget_grades_title", defaultValue: "Grades"))
        .description(LocalizedStringResource("widget_grades_inline_description", defaultValue: "Shows recent grades above the clock"))
        .supportedFamilies([.accessoryInline])
    }
}

struct GradesInlineWidgetView: View {
    let entry: GradesEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.locale)
    }

    var todayGrades: [WidgetGrade] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entry.grades.filter { calendar.startOfDay(for: $0.recordDate) == today }
    }

    var body: some View {
        if todayGrades.count > 0 {
            Text("📝 \(localization.string("today_new_grades", todayGrades.count))")
        } else if let latest = entry.grades.first {
            // No grades today - show latest
            Text("\(localization.string("latest")): \(latest.displayValue) \(latest.subject.name)")
        } else {
            Text(localization.string("no_grades"))
        }
    }
}

// MARK: - Averages Inline Widget

struct AveragesInlineWidget: Widget {
    let kind: String = "AveragesInlineWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: AveragesWidgetIntent.self,
            provider: AveragesProvider()
        ) { entry in
            AveragesInlineWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(LocalizedStringResource("widget_averages_title", defaultValue: "Averages"))
        .description(LocalizedStringResource("widget_averages_inline_description", defaultValue: "Shows your average above the clock"))
        .supportedFamilies([.accessoryInline])
    }
}

struct AveragesInlineWidgetView: View {
    let entry: AveragesEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.locale)
    }

    var body: some View {
        if let overall = entry.overallAverage {
            Text("\(localization.string("average_short")): \(String(format: "%.2f", overall)) · \(entry.subjectAverages.count) \(localization.string("subject_short"))")
        } else if let first = entry.subjectAverages.first {
            Text("\(first.name): \(String(format: "%.2f", first.average))")
        } else {
            Text(localization.string("no_averages"))
        }
    }
}
