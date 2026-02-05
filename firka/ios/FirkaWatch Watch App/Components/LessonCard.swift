import SwiftUI

struct LessonCard: View {
    let lesson: WidgetLesson
    let isActive: Bool
    let colors: WidgetColors?

    var backgroundColor: Color {
        if let colors = colors {
            return colors.cardColor
        }
        return Color(white: 0.15)
    }

    var textPrimaryColor: Color {
        if let colors = colors {
            return colors.textPrimaryColor
        }
        return .primary
    }

    var textSecondaryColor: Color {
        if let colors = colors {
            return colors.textSecondaryColor
        }
        return .secondary
    }

    var textTertiaryColor: Color {
        if let colors = colors {
            return colors.textTertiaryColor
        }
        return .secondary.opacity(0.7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                if let number = lesson.lessonNumber {
                    Text("\(number)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isActive ? .white : textPrimaryColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isActive ? Color.green : Color.clear)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(lesson.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(lesson.isCancelled ? .red :
                                       lesson.isSubstitution ? .orange : textPrimaryColor)
                        .strikethrough(lesson.isCancelled, color: .red)
                        .lineLimit(1)

                    Text(lesson.timeString)
                        .font(.caption2)
                        .foregroundColor(lesson.isCancelled ? .red.opacity(0.8) :
                                       lesson.isSubstitution ? .orange.opacity(0.8) : textSecondaryColor)
                }

                Spacer()
            }

            if let room = lesson.roomName {
                HStack(spacing: 4) {
                    Image(systemName: "door.right.hand.closed")
                        .font(.caption2)
                    Text(room)
                        .font(.caption2)
                }
                .foregroundColor(lesson.isCancelled ? .red.opacity(0.7) :
                               lesson.isSubstitution ? .orange.opacity(0.7) : textSecondaryColor)
                .lineLimit(1)
            }

            if let teacher = lesson.teacher {
                Text(teacher)
                    .font(.caption2)
                    .foregroundColor(lesson.isCancelled ? .red.opacity(0.7) :
                                   lesson.isSubstitution ? .orange.opacity(0.7) : textTertiaryColor)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isActive ? Color.green : Color.clear,
                    lineWidth: isActive ? 2 : 0
                )
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        LessonCard(
            lesson: WidgetLesson(
                uid: "1",
                date: "2026-02-01",
                start: Date(),
                end: Date().addingTimeInterval(3600),
                name: "Matematika",
                lessonNumber: 3,
                teacher: "Nagy János",
                substituteTeacher: nil,
                subject: WidgetSubject(uid: "math", name: "Matematika", category: nil, sortIndex: 1, teacherName: "Nagy János"),
                theme: nil,
                roomName: "201",
                isCancelled: false,
                isSubstitution: false
            ),
            isActive: true,
            colors: nil
        )

        LessonCard(
            lesson: WidgetLesson(
                uid: "2",
                date: "2026-02-01",
                start: Date().addingTimeInterval(7200),
                end: Date().addingTimeInterval(10800),
                name: "Angol",
                lessonNumber: 4,
                teacher: "Kovács Éva",
                substituteTeacher: nil,
                subject: WidgetSubject(uid: "eng", name: "Angol", category: nil, sortIndex: 2, teacherName: "Kovács Éva"),
                theme: nil,
                roomName: "105",
                isCancelled: false,
                isSubstitution: false
            ),
            isActive: false,
            colors: nil
        )
    }
    .padding()
}
