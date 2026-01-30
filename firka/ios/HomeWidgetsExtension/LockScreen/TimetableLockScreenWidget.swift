import WidgetKit
import SwiftUI

// MARK: - Lock Screen Timetable Widget

struct TimetableLockScreenWidget: Widget {
    let kind: String = "TimetableLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TimetableWidgetIntent.self,
            provider: TimetableProvider()
        ) { entry in
            TimetableLockScreenView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("widget_timetable_title", defaultValue: "Timetable"))
        .description(LocalizedStringResource("widget_timetable_lockscreen_description", defaultValue: "Shows current lesson on lock screen"))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Lock Screen View

struct TimetableLockScreenView: View {
    @Environment(\.widgetFamily) var family
    let entry: TimetableEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.data?.locale ?? "hu")
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                TimetableInlineView(entry: entry, localization: localization)
            case .accessoryCircular:
                TimetableCircularView(entry: entry, localization: localization)
            case .accessoryRectangular:
                TimetableRectangularView(entry: entry, localization: localization)
            default:
                Text("--")
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Inline View (single line next to date)

struct TimetableInlineView: View {
    let entry: TimetableEntry
    let localization: WidgetLocalization

    var body: some View {
        if entry.state == .onBreak, let breakInfo = entry.breakInfo {
            Text("🏖️ \(localization.string(breakInfo.nameKey))")
        } else if let current = entry.currentLesson {
            let remaining = minutesRemaining(until: current.end)
            Text("\(current.subject.name) - \(remaining) \(localization.string("minutes_short"))")
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
                Text("\(localization.string("next")): \(next.subject.name)")
            } else if until > 60 {
                let hours = until / 60
                Text("\(next.subject.name) \(localization.string("in_hours", hours))")
            } else {
                Text("\(next.subject.name) \(localization.string("in_minutes", until))")
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

// MARK: - Circular View (small circle)

struct TimetableCircularView: View {
    let entry: TimetableEntry
    let localization: WidgetLocalization

    var body: some View {
        if entry.state == .onBreak {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "sun.max.fill")
                    .font(.title2)
            }
        } else if let current = entry.currentLesson {
            let remaining = minutesRemaining(until: current.end)
            Gauge(value: Double(remaining), in: 0...45) {
                Text("")
            } currentValueLabel: {
                Text("\(remaining)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        } else if entry.isNextSchoolDay || entry.isNextDay {
            let lessonCount = entry.lessons.count
            if lessonCount > 0 {
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Text("\(lessonCount)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text(localization.string("lesson_short"))
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.title2)
                }
            }
        } else if let next = entry.nextLesson {
            let until = minutesRemaining(until: next.start)
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    if until > 60 {
                        let hours = until / 60
                        Text("\(hours)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text(localization.string("hours_abbrev"))
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(until)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text(localization.string("minutes_abbrev"))
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else if let lesson = entry.lessons.first, let lessonNum = lesson.lessonNumber {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(lessonNum).")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text(localization.string("lesson_short"))
                        .font(.system(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
            }
        }
    }

    private func minutesRemaining(until date: Date) -> Int {
        let diff = date.timeIntervalSince(entry.date)
        return max(0, Int(ceil(diff / 60)))
    }
}

// MARK: - Rectangular View (medium rectangle)

struct TimetableRectangularView: View {
    let entry: TimetableEntry
    let localization: WidgetLocalization

    var body: some View {
        if entry.state == .onBreak, let breakInfo = entry.breakInfo {
            VStack(alignment: .leading, spacing: 2) {
                Label(localization.string(breakInfo.nameKey), systemImage: "sun.max.fill")
                    .font(.headline)
                Text(localization.string("until") + " " + formatDate(breakInfo.endDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let current = entry.currentLesson {
            let remaining = minutesRemaining(until: current.end)
            let lessonNum = current.lessonNumber ?? 0
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(lessonNum). \(current.subject.name)")
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(remaining)'")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    if let room = current.roomName {
                        Label(room, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(formatTimeRange(current.start, current.end))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let next = entry.nextLesson {
            let until = minutesRemaining(until: next.start)
            let isFutureDay = entry.isNextDay || entry.isNextSchoolDay
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if entry.isNextSchoolDay {
                        let dateStr = WidgetLocalization.formatShortDate(entry.nextSchoolDayDateString, locale: localization.locale)
                        Text(dateStr)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(entry.isNextDay ? localization.string("tomorrow") : localization.string("next"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if until > 0 && !isFutureDay {
                        if until > 60 {
                            Text(localization.string("in_hours", until / 60))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(localization.string("in_minutes", until))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Text("\(next.lessonNumber ?? 0). \(next.subject.name)")
                    .font(.headline)
                    .lineLimit(1)
                HStack {
                    if let room = next.roomName {
                        Label(room, systemImage: "mappin")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(formatTimeRange(next.start, next.end))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading) {
                Label(localization.string("no_lessons"), systemImage: "checkmark.circle")
                    .font(.headline)
                Text(localization.string("no_more_lessons_today"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func minutesRemaining(until date: Date) -> Int {
        let diff = date.timeIntervalSince(entry.date)
        return max(0, Int(ceil(diff / 60)))
    }

    private func formatTimeRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d."
        return formatter.string(from: date)
    }
}
