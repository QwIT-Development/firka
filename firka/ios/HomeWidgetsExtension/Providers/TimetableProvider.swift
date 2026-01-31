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

        let midnight = calendar.startOfDay(for: now.addingTimeInterval(86400))
        entries.append(createEntry(for: configuration, date: midnight))

        let uniqueDates = Set(entries.map { $0.date })
        entries = uniqueDates.map { date in
            entries.first { $0.date == date }!
        }
        entries.sort { $0.date < $1.date }

        if isLockScreenWidget {
            var refreshDate: Date
            if let next = nextLesson {
                refreshDate = next.start
            } else if let current = currentLesson {
                refreshDate = current.end.addingTimeInterval(1)
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

        var lessons = data.timetable.today
        var isNextDay = false

        if let firstTodayLesson = lessons.first {
            let todayLessonDay = calendar.startOfDay(for: firstTodayLesson.start)

            if entryDay > todayLessonDay {
                lessons = data.timetable.tomorrow
                if let firstTomorrowLesson = lessons.first {
                    let tomorrowLessonDay = calendar.startOfDay(for: firstTomorrowLesson.start)
                    isNextDay = entryDay < tomorrowLessonDay
                }
            } else {
                let lastLesson = lessons.last
                if let last = lastLesson, date > last.end {
                    lessons = data.timetable.tomorrow
                    isNextDay = true
                }
            }
        } else {
            lessons = data.timetable.tomorrow
            if !lessons.isEmpty {
                isNextDay = true
            }
        }

        if lessons.isEmpty {
            if let nextSchoolDayLessons = data.timetable.nextSchoolDay, !nextSchoolDayLessons.isEmpty {
                return TimetableEntry(
                    date: date,
                    configuration: configuration,
                    data: data,
                    lessons: nextSchoolDayLessons,
                    currentLesson: nil,
                    nextLesson: nextSchoolDayLessons.first,
                    isNextDay: false,
                    isNextSchoolDay: true,
                    nextSchoolDayDateString: data.timetable.nextSchoolDayDate,
                    breakInfo: nil,
                    state: .normal,
                    debugInfo: WidgetData.lastError
                )
            }

            return TimetableEntry(
                date: date,
                configuration: configuration,
                data: data,
                lessons: [],
                currentLesson: nil,
                nextLesson: nil,
                isNextDay: isNextDay,
                isNextSchoolDay: false,
                nextSchoolDayDateString: nil,
                breakInfo: nil,
                state: isNextDay ? .noMoreLessons : .unavailable,
                debugInfo: WidgetData.lastError
            )
        }

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
            isNextSchoolDay: false,
            nextSchoolDayDateString: nil,
            breakInfo: nil,
            state: .normal,
            debugInfo: WidgetData.lastError
        )
    }
}
