import SwiftUI
import WidgetKit

struct TimetableSmallView: View {
    let entry: TimetableEntry
    let localization: WidgetLocalization
    @Environment(\.colorScheme) var colorScheme

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var displayLesson: WidgetLesson? {
        let mode = entry.configuration.displayMode ?? .current
        if mode == .current {
            return entry.currentLesson ?? entry.nextLesson
        } else {
            return entry.nextLesson
        }
    }

    var isShowingNextLesson: Bool {
        let mode = entry.configuration.displayMode ?? .current
        if mode == .current {
            return entry.currentLesson == nil && entry.nextLesson != nil
        }
        return true
    }

    var liquidGlassPrimary: Color {
        colorScheme == .dark ? .white : .black
    }

    var liquidGlassSecondary: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 4) {
                Text(isShowingNextLesson ?
                     localization.string("next_lesson") :
                     localization.string("current_lesson"))
                    .font(.caption)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)

                if let lesson = displayLesson {
                    if entry.isNextSchoolDay {
                        let dateStr = WidgetLocalization.formatShortDate(entry.nextSchoolDayDateString, locale: localization.locale)
                        Text(dateStr)
                            .font(.caption2)
                            .widgetTextStyle(style, colors: nil, isPrimary: false)
                    }

                    Text(lesson.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .strikethrough(lesson.isCancelled, color: .red)
                        .foregroundColor(lesson.isCancelled ? .red :
                                        lesson.isSubstitution ? .orange :
                                        (style == .liquidGlass ? liquidGlassPrimary : .primary))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(lesson.timeString)
                        .font(.subheadline)
                        .foregroundColor(lesson.isCancelled ? .red.opacity(0.8) :
                                        lesson.isSubstitution ? .orange.opacity(0.8) :
                                        (style == .liquidGlass ? liquidGlassSecondary : .secondary))

                    if let room = lesson.roomName {
                        Text(room)
                            .font(.caption2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .foregroundColor(lesson.isCancelled ? .red.opacity(0.7) :
                                            lesson.isSubstitution ? .orange.opacity(0.7) :
                                            (style == .liquidGlass ? liquidGlassSecondary : .secondary))
                    }
                } else {
                    Text(localization.string("no_lessons_ahead"))
                        .font(.subheadline)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct TimetableMediumView: View {
    let entry: TimetableEntry
    let localization: WidgetLocalization

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    func isLessonActive(_ lesson: WidgetLesson) -> Bool {
        let checkDate = entry.date
        return checkDate >= lesson.start && checkDate <= lesson.end
    }

    var currentLessonIndex: Int {
        let checkDate = entry.date
        if let index = entry.lessons.firstIndex(where: { checkDate >= $0.start && checkDate <= $0.end }) {
            return index
        }
        if let index = entry.lessons.firstIndex(where: { $0.start > checkDate }) {
            return index
        }
        return max(0, entry.lessons.count - 1)
    }

    var hasActiveBreak: Bool {
        let checkDate = entry.date
        for i in 0..<entry.lessons.count - 1 {
            if checkDate > entry.lessons[i].end && checkDate < entry.lessons[i + 1].start {
                return true
            }
        }
        return false
    }

    var visibleLessons: [WidgetLesson] {
        let totalLessons = entry.lessons.count
        let maxVisible = hasActiveBreak ? 3 : 4

        if totalLessons <= maxVisible {
            return Array(entry.lessons)
        }

        var startIndex = max(0, currentLessonIndex - 1)

        startIndex = min(startIndex, totalLessons - maxVisible)

        let endIndex = min(startIndex + maxVisible, totalLessons)
        return Array(entry.lessons[startIndex..<endIndex])
    }

    var headerText: String {
        if entry.isNextSchoolDay {
            let dateStr = WidgetLocalization.formatShortDate(entry.nextSchoolDayDateString, locale: localization.locale)
            return localization.string("next_school_day_timetable", dateStr)
        } else if entry.isNextDay {
            return localization.string("tomorrow_timetable")
        } else {
            return localization.string("today_timetable")
        }
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 6) {
                Text(headerText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)

                Spacer(minLength: 0)
                ForEach(Array(visibleLessons.enumerated()), id: \.element.id) { index, lesson in
                    LessonRow(lesson: lesson, isActive: isLessonActive(lesson), style: style, compact: true)

                    if index < visibleLessons.count - 1 {
                        let nextLesson = visibleLessons[index + 1]
                        let isInBreak = entry.date > lesson.end && entry.date < nextLesson.start
                        if isInBreak {
                            let breakMinutes = Int(ceil(nextLesson.start.timeIntervalSince(entry.date) / 60))
                            BreakIndicatorRow(minutesLeft: breakMinutes, localization: localization, style: style, compact: true)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding()
        }
        .clipped()
    }
}

struct TimetableLargeView: View {
    let entry: TimetableEntry
    let localization: WidgetLocalization

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    func isLessonActive(_ lesson: WidgetLesson) -> Bool {
        let checkDate = entry.date
        return checkDate >= lesson.start && checkDate <= lesson.end
    }

    var hasActiveBreak: Bool {
        let checkDate = entry.date
        for i in 0..<entry.lessons.count - 1 {
            if checkDate > entry.lessons[i].end && checkDate < entry.lessons[i + 1].start {
                return true
            }
        }
        return false
    }

    var headerText: String {
        if entry.isNextSchoolDay {
            let dateStr = WidgetLocalization.formatShortDate(entry.nextSchoolDayDateString, locale: localization.locale)
            return localization.string("next_school_day_timetable", dateStr)
        } else if entry.isNextDay {
            return localization.string("tomorrow_timetable")
        } else {
            return localization.string("today_timetable")
        }
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 6) {
                Text(headerText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .widgetTextStyle(style, colors: nil)

                let maxLessons = hasActiveBreak ? 6 : 7
                let lessonsToShow = Array(entry.lessons.prefix(maxLessons))
                ForEach(Array(lessonsToShow.enumerated()), id: \.element.id) { index, lesson in
                    LessonRow(lesson: lesson, isActive: isLessonActive(lesson), style: style, showRoom: true)

                    if index < lessonsToShow.count - 1 {
                        let nextLesson = lessonsToShow[index + 1]
                        let isInBreak = entry.date > lesson.end && entry.date < nextLesson.start
                        if isInBreak {
                            let breakMinutes = Int(ceil(nextLesson.start.timeIntervalSince(entry.date) / 60))
                            BreakIndicatorRow(minutesLeft: breakMinutes, localization: localization, style: style)
                        }
                    }
                }
            }
            .padding()
        }
        .clipped()
    }
}

struct BreakIndicatorRow: View {
    let minutesLeft: Int
    let localization: WidgetLocalization
    let style: WidgetStyleType
    var compact: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var liquidGlassPrimary: Color {
        colorScheme == .dark ? .white : .black
    }

    var liquidGlassSecondary: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("–")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.3))
                )
                .foregroundColor(style == .liquidGlass ? liquidGlassPrimary : .primary)

            Text(localization.string("break_between"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(style == .liquidGlass ? liquidGlassPrimary : .primary)

            Spacer()

            Text("\(minutesLeft) \(localization.string("minutes_abbrev"))")
                .font(.caption)
                .foregroundColor(style == .liquidGlass ? liquidGlassSecondary : .secondary)
        }
        .padding(.vertical, compact ? 2 : 4)
        .padding(.horizontal, 8)
        .currentLessonGlow(isActive: true)
    }
}

struct LessonRow: View {
    let lesson: WidgetLesson
    let isActive: Bool
    let style: WidgetStyleType
    var showRoom: Bool = false
    var compact: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var lessonTextColor: Color? {
        if lesson.isCancelled {
            return .red
        } else if lesson.isSubstitution {
            return .orange
        }
        return nil
    }

    var liquidGlassPrimary: Color {
        colorScheme == .dark ? .white : .black
    }

    var liquidGlassSecondary: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }

    var numberBackgroundColor: Color {
        if lesson.isCancelled {
            return Color.red.opacity(0.3)
        } else if lesson.isSubstitution {
            return Color.orange.opacity(0.3)
        } else if isActive {
            return Color.green.opacity(0.3)
        }
        return Color.secondary.opacity(0.2)
    }

    var body: some View {
        HStack(spacing: 12) {
            if let number = lesson.lessonNumber {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(numberBackgroundColor)
                    )
                    .foregroundColor(lessonTextColor ?? (style == .liquidGlass ? liquidGlassPrimary : .primary))
            }

            Text(lesson.displayName)
                .font(.subheadline)
                .fontWeight(isActive ? .semibold : .regular)
                .strikethrough(lesson.isCancelled, color: .red)
                .foregroundColor(lessonTextColor ?? (style == .liquidGlass ? liquidGlassPrimary : .primary))
                .lineLimit(1)

            Spacer()

            Text(lesson.timeString)
                .font(.caption)
                .foregroundColor(lessonTextColor?.opacity(0.8) ?? (style == .liquidGlass ? liquidGlassSecondary : .secondary))

            if showRoom, let room = lesson.roomName {
                Text(room)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(lesson.isCancelled ? Color.red.opacity(0.2) :
                                  lesson.isSubstitution ? Color.orange.opacity(0.2) :
                                  Color.secondary.opacity(0.2))
                    )
                    .foregroundColor(lessonTextColor?.opacity(0.8) ?? (style == .liquidGlass ? liquidGlassSecondary : .secondary))
            }
        }
        .padding(.vertical, compact ? 2 : 4)
        .padding(.horizontal, 8)
        .currentLessonGlow(isActive: isActive && !lesson.isCancelled)
    }
}

struct BreakView: View {
    let breakInfo: BreakInfo
    let localization: WidgetLocalization
    let style: WidgetStyleType

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: breakInfo.endDate).day ?? 0
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(spacing: 12) {
                Image(systemName: "snowflake")
                    .font(.largeTitle)
                    .widgetTextStyle(style, colors: nil)

                Text(localization.string("happy_break", localization.string(breakInfo.nameKey)))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .widgetTextStyle(style, colors: nil)

                Text(localization.string("days_remaining", daysRemaining))
                    .font(.subheadline)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)
            }
            .padding()
        }
    }
}

struct EmptyStateView: View {
    let message: String
    let style: WidgetStyleType

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.largeTitle)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)

                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)
            }
            .padding()
        }
    }
}
