import WidgetKit
import SwiftUI

// MARK: - Lock Screen Grades Widget

struct GradesLockScreenWidget: Widget {
    let kind: String = "GradesLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GradesWidgetIntent.self,
            provider: GradesProvider()
        ) { entry in
            GradesLockScreenView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("widget_grades_title", defaultValue: "Recent Grades"))
        .description(LocalizedStringResource("widget_grades_lockscreen_description", defaultValue: "Shows recent grades on lock screen"))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Lock Screen View

struct GradesLockScreenView: View {
    @Environment(\.widgetFamily) var family
    let entry: GradesEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.locale)
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                GradesInlineView(entry: entry, localization: localization)
            case .accessoryCircular:
                GradesCircularView(entry: entry, localization: localization)
            case .accessoryRectangular:
                GradesRectangularView(entry: entry, localization: localization)
            default:
                Text("--")
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Inline View

struct GradesInlineView: View {
    let entry: GradesEntry
    let localization: WidgetLocalization

    var todayGrades: [WidgetGrade] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entry.grades.filter { calendar.startOfDay(for: $0.recordDate) == today }
    }

    var body: some View {
        if let latest = entry.grades.first {
            if todayGrades.count > 0 {
                Text(localization.string("today_new_grades", todayGrades.count))
            } else {
                Text("\(localization.string("latest")): \(latest.displayValue) \(latest.subject.name)")
            }
        } else {
            Text(localization.string("no_grades"))
        }
    }
}

// MARK: - Circular View

struct GradesCircularView: View {
    let entry: GradesEntry
    let localization: WidgetLocalization

    var todayGradesCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entry.grades.filter { calendar.startOfDay(for: $0.recordDate) == today }.count
    }

    var body: some View {
        if let latest = entry.grades.first {
            ZStack {
                AccessoryWidgetBackground()
                Text(latest.displayValue)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(gradeColor(latest.numericValue))
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "graduationcap")
                    .font(.title2)
            }
        }
    }

    private func gradeColor(_ value: Int?) -> Color {
        guard let value = value else { return .primary }
        switch value {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .primary
        }
    }
}

// MARK: - Rectangular View

struct GradesRectangularView: View {
    let entry: GradesEntry
    let localization: WidgetLocalization

    var todayGrades: [WidgetGrade] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entry.grades.filter { calendar.startOfDay(for: $0.recordDate) == today }
    }

    var body: some View {
        if !entry.grades.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                if todayGrades.count > 0 {
                    HStack {
                        Text(localization.string("today_grades"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(localization.string("pieces", todayGrades.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        ForEach(todayGrades.prefix(5), id: \.uid) { grade in
                            GradeBadge(grade: grade)
                        }
                        if todayGrades.count > 5 {
                            Text("+\(todayGrades.count - 5)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                } else if let latest = entry.grades.first {
                    HStack {
                        Text(localization.string("latest_grade"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatDate(latest.recordDate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(latest.displayValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(gradeColor(latest.numericValue))
                        Text(latest.subject.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading) {
                Label(localization.string("no_grades"), systemImage: "graduationcap")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d."
        return formatter.string(from: date)
    }

    private func gradeColor(_ value: Int?) -> Color {
        guard let value = value else { return .primary }
        switch value {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .primary
        }
    }
}

// MARK: - Grade Badge

struct GradeBadge: View {
    let grade: WidgetGrade

    var body: some View {
        Text(grade.displayValue)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(gradeColor(grade.numericValue))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(gradeColor(grade.numericValue).opacity(0.2))
            )
    }

    private func gradeColor(_ value: Int?) -> Color {
        guard let value = value else { return .primary }
        switch value {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .primary
        }
    }
}
