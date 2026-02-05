import SwiftUI

struct GradesView: View {
    let dataStore: DataStore

    var body: some View {
        NavigationStack {
            if dataStore.data == nil {
                ContentUnavailableView("no_data".localized, systemImage: "graduationcap")
            } else if subjects.isEmpty {
                ContentUnavailableView("no_grades".localized, systemImage: "graduationcap")
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(subjects, id: \.uid) { subject in
                            NavigationLink {
                                GradeSubjectView(
                                    subjectName: subject.name,
                                    grades: gradesFor(subject.uid),
                                    average: subject.average
                                )
                            } label: {
                                subjectRow(subject)
                            }
                            .buttonStyle(.plain)
                        }

                        if let overall = dataStore.data?.averages.overall {
                            overallAverageCard(overall)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var subjects: [SubjectAverage] {
        (dataStore.data?.averages.subjects ?? []).sorted { $0.name < $1.name }
    }

    private func gradesFor(_ uid: String) -> [WidgetGrade] {
        dataStore.data?.grades.filter { $0.subject.uid == uid } ?? []
    }

    @ViewBuilder
    private func subjectRow(_ subject: SubjectAverage) -> some View {
        FirkaCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(subject.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    Text(String(format: "%.2f", subject.average))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(averageColor(subject.average))
                }

                HStack(spacing: 8) {
                    AverageProgressBar(average: subject.average)

                    Text("grades_count".localized(subject.gradeCount))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func overallAverageCard(_ average: Double) -> some View {
        FirkaCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("total_average".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text(String(format: "%.2f", average))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(averageColor(average))

                    Spacer()

                    AverageProgressBar(average: average)
                        .frame(width: 60)
                }
            }
        }
        .padding(.top, 8)
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
