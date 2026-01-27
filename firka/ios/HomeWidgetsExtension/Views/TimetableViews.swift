import SwiftUI
import WidgetKit

struct TimetableSmallView: View {
    let entry: TimetableEntry
    let localization: WidgetLocalization

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var displayLesson: WidgetLesson? {
        (entry.configuration.displayMode ?? .current) == .current ? entry.currentLesson : entry.nextLesson
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 4) {
                Text((entry.configuration.displayMode ?? .current) == .current ?
                     localization.string("current_lesson") :
                     localization.string("next_lesson"))
                    .font(.caption)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)

                if let lesson = displayLesson {
                    Text(lesson.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .strikethrough(lesson.isCancelled, color: .red)
                        .foregroundColor(lesson.isCancelled ? .red :
                                        lesson.isSubstitution ? .orange :
                                        (style == .liquidGlass ? .white : .primary))
                        .lineLimit(2)

                    Text(lesson.timeString)
                        .font(.subheadline)
                        .foregroundColor(lesson.isCancelled ? .red.opacity(0.8) :
                                        lesson.isSubstitution ? .orange.opacity(0.8) :
                                        (style == .liquidGlass ? .white.opacity(0.7) : .secondary))

                    if let room = lesson.roomName {
                        Text(room)
                            .font(.caption2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .foregroundColor(lesson.isCancelled ? .red.opacity(0.7) :
                                            lesson.isSubstitution ? .orange.opacity(0.7) :
                                            (style == .liquidGlass ? .white.opacity(0.6) : .secondary))
                    }
                } else {
                    Text(localization.string("no_lessons"))
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

    var remainingLessons: [WidgetLesson] {
        let now = Date()
        return entry.lessons.filter { $0.end > now }
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.isNextDay ? localization.string("tomorrow_timetable") : localization.string("today_timetable"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)

                ForEach(remainingLessons.prefix(4)) { lesson in
                    LessonRow(lesson: lesson, isActive: lesson.isCurrentlyActive, style: style)
                }
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

    var remainingLessons: [WidgetLesson] {
        let now = Date()
        return entry.lessons.filter { $0.end > now }
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.isNextDay ? localization.string("tomorrow_timetable") : localization.string("today_timetable"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .widgetTextStyle(style, colors: nil)

                ForEach(remainingLessons.prefix(7)) { lesson in
                    LessonRow(lesson: lesson, isActive: lesson.isCurrentlyActive, style: style, showRoom: true)
                }
            }
            .padding()
        }
        .clipped()
    }
}

struct LessonRow: View {
    let lesson: WidgetLesson
    let isActive: Bool
    let style: WidgetStyleType
    var showRoom: Bool = false

    var lessonTextColor: Color? {
        if lesson.isCancelled {
            return .red
        } else if lesson.isSubstitution {
            return .orange
        }
        return nil
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
                    .foregroundColor(lessonTextColor ?? (style == .liquidGlass ? .white : .primary))
            }

            Text(lesson.displayName)
                .font(.subheadline)
                .fontWeight(isActive ? .semibold : .regular)
                .strikethrough(lesson.isCancelled, color: .red)
                .foregroundColor(lessonTextColor ?? (style == .liquidGlass ? .white : .primary))
                .lineLimit(1)

            Spacer()

            Text(lesson.timeString)
                .font(.caption)
                .foregroundColor(lessonTextColor?.opacity(0.8) ?? (style == .liquidGlass ? .white.opacity(0.7) : .secondary))

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
                    .foregroundColor(lessonTextColor?.opacity(0.8) ?? (style == .liquidGlass ? .white.opacity(0.7) : .secondary))
            }
        }
        .padding(.vertical, 4)
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
