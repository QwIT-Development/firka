import SwiftUI

struct GradeSubjectView: View {
    let subjectName: String
    let grades: [WidgetGrade]
    let average: Double

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                FirkaCard {
                    HStack {
                        Text("average".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", average))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(averageColor(average))
                    }
                }

                ForEach(groupedGrades, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(formatDate(group.date))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(group.grades) { grade in
                            gradeRow(grade)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(subjectName)
    }

    private var groupedGrades: [(date: Date, grades: [WidgetGrade])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: grades) { grade in
            calendar.startOfDay(for: grade.recordDate)
        }
        return grouped
            .map { (date: $0.key, grades: $0.value) }
            .sorted { $0.date > $1.date }
    }

    @ViewBuilder
    private func gradeRow(_ grade: WidgetGrade) -> some View {
        FirkaCard {
            HStack(alignment: .top, spacing: 10) {
                if let normalizedValue = grade.normalizedNumericValue {
                    if grade.isPercentageGrade, let rawValue = grade.numericValue {
                        ZStack {
                            Circle()
                                .fill(gradeColor(normalizedValue))
                                .frame(width: 32, height: 32)
                            Text("\(rawValue)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        GradeBadge(grade: normalizedValue)
                    }
                } else {
                    Text(grade.displayValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.gray)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(grade.displayTypeWithWeight)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let topic = grade.topic, !topic.isEmpty {
                        Text(topic)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
        }
    }

    private func gradeColor(_ value: Int) -> Color {
        switch value {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .orange
        default: return .red
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd."
        return formatter.string(from: date)
    }

    private func averageColor(_ avg: Double) -> Color {
        switch avg {
        case 4.5...: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }
}
