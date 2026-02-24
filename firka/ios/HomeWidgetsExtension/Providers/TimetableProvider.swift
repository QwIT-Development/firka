import WidgetKit
import SwiftUI

struct TimetableEntry: TimelineEntry {
    let date: Date
    let configuration: TimetableWidgetIntent
    let data: WidgetData?
    let lessons: [WidgetLesson]
    let currentLesson: WidgetLesson?
    let nextLesson: WidgetLesson?
    let isNextDay: Bool
    let isNextSchoolDay: Bool
    let nextSchoolDayDateString: String?
    let breakInfo: BreakInfo?
    let state: TimetableState
    let debugInfo: String
}

enum TimetableState {
    case normal
    case noMoreLessons
    case onBreak
    case loginRequired
    case unavailable
}

struct TimetableProvider: AppIntentTimelineProvider {
    typealias Entry = TimetableEntry
    typealias Intent = TimetableWidgetIntent

    private struct LessonCandidate {
        let lessons: [WidgetLesson]
        let day: Date
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let isoFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private func parseNextSchoolDayDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        if let date = Self.isoFormatterWithFractional.date(from: dateString) {
            return date
        }
        if let date = Self.isoFormatter.date(from: dateString) {
            return date
        }
        if let date = Self.dateFormatter.date(from: dateString) {
            return date
        }

        let trimmed = String(dateString.prefix(10))
        return Self.dateFormatter.date(from: trimmed)
    }

    private func startOfDay(for lessons: [WidgetLesson], calendar: Calendar) -> Date? {
        guard let first = lessons.first else { return nil }
        return calendar.startOfDay(for: first.start)
    }

    private func nextSchoolDay(from data: WidgetData, calendar: Calendar) -> Date? {
        if let firstNextLesson = data.timetable.nextSchoolDay?.first {
            return calendar.startOfDay(for: firstNextLesson.start)
        }

        if let parsedDate = parseNextSchoolDayDate(data.timetable.nextSchoolDayDate) {
            return calendar.startOfDay(for: parsedDate)
        }

        return nil
    }

    func placeholder(in context: Context) -> TimetableEntry {
        TimetableEntry(
            date: Date(),
            configuration: TimetableWidgetIntent(),
            data: nil,
            lessons: [],
            currentLesson: nil,
            nextLesson: nil,
            isNextDay: false,
            isNextSchoolDay: false,
            nextSchoolDayDateString: nil,
            breakInfo: nil,
            state: .normal,
            debugInfo: "placeholder"
        )
    }

    func snapshot(for configuration: TimetableWidgetIntent, in context: Context) async -> TimetableEntry {
        createEntry(for: configuration, date: Date())
    }

    func timeline(for configuration: TimetableWidgetIntent, in context: Context) async -> Timeline<TimetableEntry> {
        var entries: [TimetableEntry] = []
        let now = Date()
        let calendar = Calendar.current

        let data = WidgetData.load()

        // If on break, create single entry
        if let breakInfo = data?.timetable.currentBreak {
            let entry = TimetableEntry(
                date: now,
                configuration: configuration,
                data: data,
                lessons: [],
                currentLesson: nil,
                nextLesson: nil,
                isNextDay: false,
                isNextSchoolDay: false,
                nextSchoolDayDateString: nil,
                breakInfo: breakInfo,
                state: .onBreak,
                debugInfo: WidgetData.lastError
            )
            entries.append(entry)
            return Timeline(entries: entries, policy: .after(calendar.startOfDay(for: now.addingTimeInterval(86400))))
        }

        let todayLessons = data?.timetable.today ?? []

        entries.append(createEntry(for: configuration, date: now))

        let currentLesson = todayLessons.first { now >= $0.start && now <= $0.end }
        let nextLesson = todayLessons.first { $0.start > now }

        let isLockScreenWidget = context.family == .accessoryInline ||
                                  context.family == .accessoryCircular ||
                                  context.family == .accessoryRectangular

        if isLockScreenWidget {
            var minuteEntries: [Date] = []

            if let current = currentLesson {
                var time = now.addingTimeInterval(60)
                while time <= current.end && minuteEntries.count < 60 {
                    minuteEntries.append(time)
                    time = time.addingTimeInterval(60)
                }
                minuteEntries.append(current.end.addingTimeInterval(1))
            }

            if let next = nextLesson {
                let minutesUntilNext = next.start.timeIntervalSince(now) / 60

                if minutesUntilNext <= 60 {
                    var time = currentLesson?.end.addingTimeInterval(60) ?? now.addingTimeInterval(60)
                    while time < next.start && minuteEntries.count < 120 {
                        minuteEntries.append(time)
                        time = time.addingTimeInterval(60)
                    }
                } else {
                    let sixtyMinutesBefore = next.start.addingTimeInterval(-60 * 60)
                    if sixtyMinutesBefore > now {
                        minuteEntries.append(sixtyMinutesBefore)
                    }
                }
                minuteEntries.append(next.start)

                var nextLessonTime = next.start.addingTimeInterval(60)
                while nextLessonTime <= next.end && minuteEntries.count < 180 {
                    minuteEntries.append(nextLessonTime)
                    nextLessonTime = nextLessonTime.addingTimeInterval(60)
                }
                minuteEntries.append(next.end.addingTimeInterval(1))
            }

            for time in minuteEntries {
                if time > now {
                    entries.append(createEntry(for: configuration, date: time))
                }
            }
        }

        for lesson in todayLessons {
            if lesson.start > now {
                entries.append(createEntry(for: configuration, date: lesson.start))
            }
            if lesson.end > now {
                entries.append(createEntry(for: configuration, date: lesson.end.addingTimeInterval(1)))
            }
        }

        let tomorrowLessons = data?.timetable.tomorrow ?? []
        for lesson in tomorrowLessons {
            if lesson.start > now {
                entries.append(createEntry(for: configuration, date: lesson.start))
            }
            if lesson.end > now {
                entries.append(createEntry(for: configuration, date: lesson.end.addingTimeInterval(1)))
            }
        }

        let nextSchoolDayLessons = data?.timetable.nextSchoolDay ?? []
        for lesson in nextSchoolDayLessons {
            if lesson.start > now {
                entries.append(createEntry(for: configuration, date: lesson.start))
            }
            if lesson.end > now {
                entries.append(createEntry(for: configuration, date: lesson.end.addingTimeInterval(1)))
            }
        }

        let midnight = calendar.startOfDay(for: now.addingTimeInterval(86400))
        entries.append(createEntry(for: configuration, date: midnight))

        if let data = data,
           let nextSchoolDay = nextSchoolDay(from: data, calendar: calendar) {
            let dayBeforeNextSchoolDay = calendar.date(byAdding: .day, value: -1, to: nextSchoolDay)!

            if dayBeforeNextSchoolDay > now {
                entries.append(createEntry(for: configuration, date: dayBeforeNextSchoolDay))
            }

            if nextSchoolDay > now {
                entries.append(createEntry(for: configuration, date: nextSchoolDay))
            }
        }

        let uniqueDates = Set(entries.map { $0.date })
        entries = uniqueDates.map { date in
            entries.first { $0.date == date }!
        }
        entries.sort { $0.date < $1.date }

        if isLockScreenWidget {
            var refreshDate: Date
            if let current = currentLesson {
                refreshDate = current.end.addingTimeInterval(1)
            } else if let next = nextLesson {
                refreshDate = next.end.addingTimeInterval(1)
            } else {
                refreshDate = midnight
            }
            return Timeline(entries: entries, policy: .after(refreshDate))
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    private func createEntry(for configuration: TimetableWidgetIntent, date: Date) -> TimetableEntry {
        let data = WidgetData.load()
        let calendar = Calendar.current

        guard let data = data else {
            return TimetableEntry(
                date: date,
                configuration: configuration,
                data: nil,
                lessons: [],
                currentLesson: nil,
                nextLesson: nil,
                isNextDay: false,
                isNextSchoolDay: false,
                nextSchoolDayDateString: nil,
                breakInfo: nil,
                state: .loginRequired,
                debugInfo: WidgetData.lastError
            )
        }

        if let breakInfo = data.timetable.currentBreak {
            return TimetableEntry(
                date: date,
                configuration: configuration,
                data: data,
                lessons: [],
                currentLesson: nil,
                nextLesson: nil,
                isNextDay: false,
                isNextSchoolDay: false,
                nextSchoolDayDateString: nil,
                breakInfo: breakInfo,
                state: .onBreak,
                debugInfo: WidgetData.lastError
            )
        }

        let entryDay = calendar.startOfDay(for: date)
        let tomorrowOfEntryDay = calendar.date(byAdding: .day, value: 1, to: entryDay)!

        let todayLessons = data.timetable.today
        let tomorrowLessons = data.timetable.tomorrow
        let nextSchoolDayLessons = data.timetable.nextSchoolDay ?? []

        var candidates: [LessonCandidate] = []

        if let todayDay = startOfDay(for: todayLessons, calendar: calendar), !todayLessons.isEmpty {
            candidates.append(LessonCandidate(lessons: todayLessons, day: todayDay))
        }

        if let tomorrowDay = startOfDay(for: tomorrowLessons, calendar: calendar), !tomorrowLessons.isEmpty {
            candidates.append(LessonCandidate(lessons: tomorrowLessons, day: tomorrowDay))
        }

        if !nextSchoolDayLessons.isEmpty,
           let resolvedNextSchoolDay = nextSchoolDay(from: data, calendar: calendar)
            ?? startOfDay(for: nextSchoolDayLessons, calendar: calendar) {
            candidates.append(LessonCandidate(lessons: nextSchoolDayLessons, day: resolvedNextSchoolDay))
        }

        candidates.sort { $0.day < $1.day }

        // Pick the closest candidate that still has lessons ahead relative to this entry date.
        let selectedCandidate = candidates.first { candidate in
            if candidate.day > entryDay {
                return true
            }

            if candidate.day == entryDay, let lastLesson = candidate.lessons.last {
                return date <= lastLesson.end
            }

            return false
        }

        guard let selectedCandidate = selectedCandidate else {
            let hadLessonsTodayButFinished = candidates.contains { candidate in
                guard candidate.day == entryDay, let lastLesson = candidate.lessons.last else { return false }
                return date > lastLesson.end
            }

            return TimetableEntry(
                date: date,
                configuration: configuration,
                data: data,
                lessons: [],
                currentLesson: nil,
                nextLesson: nil,
                isNextDay: false,
                isNextSchoolDay: false,
                nextSchoolDayDateString: nil,
                breakInfo: nil,
                state: hadLessonsTodayButFinished ? .noMoreLessons : .unavailable,
                debugInfo: WidgetData.lastError
            )
        }

        let lessons = selectedCandidate.lessons
        let isToday = selectedCandidate.day == entryDay
        let isNextDay = selectedCandidate.day == tomorrowOfEntryDay
        let isNextSchoolDay = !isToday && !isNextDay
        let nextSchoolDayDateString = isNextSchoolDay
            ? (data.timetable.nextSchoolDayDate ?? Self.dateFormatter.string(from: selectedCandidate.day))
            : nil

        let currentLesson = lessons.first { lesson in
            return date >= lesson.start && date <= lesson.end
        }
        let nextLesson = lessons.first { $0.start > date }

        return TimetableEntry(
            date: date,
            configuration: configuration,
            data: data,
            lessons: lessons,
            currentLesson: currentLesson,
            nextLesson: nextLesson,
            isNextDay: isNextDay,
            isNextSchoolDay: isNextSchoolDay,
            nextSchoolDayDateString: nextSchoolDayDateString,
            breakInfo: nil,
            state: .normal,
            debugInfo: WidgetData.lastError
        )
    }
}
