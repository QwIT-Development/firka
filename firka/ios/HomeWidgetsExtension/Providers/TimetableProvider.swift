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
                breakInfo: breakInfo,
                state: .onBreak,
                debugInfo: WidgetData.lastError
            )
            entries.append(entry)
            return Timeline(entries: entries, policy: .after(Calendar.current.startOfDay(for: now.addingTimeInterval(86400))))
        }

        let todayLessons = data?.timetable.today ?? []

        entries.append(createEntry(for: configuration, date: now))

        for lesson in todayLessons {
            if lesson.start > now {
                entries.append(createEntry(for: configuration, date: lesson.start))
            }
            if lesson.end > now {
                entries.append(createEntry(for: configuration, date: lesson.end.addingTimeInterval(1)))
            }
        }

        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
        entries.append(createEntry(for: configuration, date: midnight))

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
            return TimetableEntry(
                date: date,
                configuration: configuration,
                data: data,
                lessons: [],
                currentLesson: nil,
                nextLesson: nil,
                isNextDay: isNextDay,
                breakInfo: nil,
                state: isNextDay ? .noMoreLessons : .unavailable,
                debugInfo: WidgetData.lastError
            )
        }

        let currentLesson = lessons.first { lesson in
            let now = Date()
            return now >= lesson.start && now <= lesson.end
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
            breakInfo: nil,
            state: .normal,
            debugInfo: WidgetData.lastError
        )
    }
}
