import SwiftUI

struct LessonDetailView: View {
    let lesson: WidgetLesson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let number = lesson.lessonNumber {
                        Text("lesson_number".localized(number))
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }

                    Spacer()

                    Text("\(formatTime(lesson.start)) - \(formatTime(lesson.end))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(lesson.displayName)
                    .font(.headline)
                    .lineLimit(3)

                if lesson.isCancelled || lesson.isSubstitution {
                    HStack(spacing: 8) {
                        if lesson.isCancelled {
                            Label("cancelled".localized, systemImage: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        if lesson.isSubstitution {
                            Label("substitution".localized, systemImage: "person.2.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    if lesson.isSubstitution, let substitute = lesson.substituteTeacher {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("teacher".localized, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let original = lesson.teacher {
                                HStack(spacing: 4) {
                                    Text(original)
                                        .strikethrough()
                                        .foregroundColor(.secondary)
                                    Text("→")
                                        .foregroundColor(.orange)
                                    Text(substitute)
                                        .foregroundColor(.orange)
                                }
                                .font(.subheadline)
                            } else {
                                Text(substitute)
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        }
                    } else if let teacher = lesson.teacher {
                        detailRow(icon: "person.fill", label: "teacher".localized, value: teacher)
                    }

                    if let room = lesson.roomName {
                        detailRow(icon: "door.right.hand.closed", label: "room".localized, value: room)
                    }

                    if let theme = lesson.theme, !theme.isEmpty {
                        detailRow(icon: "doc.text.fill", label: "topic".localized, value: theme)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("lesson_details".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailRow(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .lineLimit(5)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
