import SwiftUI
import WidgetKit

struct AveragesSmallView: View {
    let entry: AveragesEntry
    let localization: WidgetLocalization

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(spacing: 8) {
                Text(localization.string("overall_average"))
                    .font(.caption)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)

                if let average = entry.overallAverage {
                    Text(String(format: "%.2f", average))
                        .font(.system(size: 36, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(averageColor(for: average))
                } else {
                    Text("-")
                        .font(.system(size: 36, weight: .bold))
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                }
            }
            .padding()
        }
    }

    func averageColor(for value: Double) -> Color {
        switch value {
        case 4.5...: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }
}

struct AveragesMediumView: View {
    let entry: AveragesEntry
    let localization: WidgetLocalization
    private let maxVisible = 4

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var totalCount: Int {
        entry.subjectAverages.count
    }

    var showingCount: Int {
        min(totalCount, maxVisible)
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localization.string("subject_averages"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)

                    Spacer()

                    if entry.isFiltered && totalCount > maxVisible {
                        Text("\(showingCount)/\(totalCount)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.2))
                            )
                            .widgetTextStyle(style, colors: nil, isPrimary: false)
                    }
                }

                if entry.subjectAverages.isEmpty {
                    Spacer()
                    Text(localization.string("no_averages"))
                        .font(.subheadline)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                    Spacer()
                } else {
                    ForEach(entry.subjectAverages.prefix(maxVisible)) { subject in
                        AverageRow(subject: subject, style: style)
                    }
                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct AveragesLargeView: View {
    let entry: AveragesEntry
    let localization: WidgetLocalization
    private let maxVisible = 9

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var totalCount: Int {
        entry.subjectAverages.count
    }

    var showingCount: Int {
        min(totalCount, maxVisible)
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localization.string("subject_averages"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .widgetTextStyle(style, colors: nil)

                    Spacer()

                    if entry.isFiltered && totalCount > maxVisible {
                        Text("\(showingCount)/\(totalCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.2))
                            )
                            .widgetTextStyle(style, colors: nil, isPrimary: false)
                    }

                    if let overall = entry.overallAverage {
                        Text(String(format: "%.2f", overall))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(averageColor(for: overall))
                    }
                }

                if entry.subjectAverages.isEmpty {
                    Spacer()
                    Text(localization.string("no_averages"))
                        .font(.subheadline)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                    Spacer()
                } else {
                    ForEach(entry.subjectAverages.prefix(maxVisible)) { subject in
                        AverageRow(subject: subject, style: style, showGradeCount: true)
                    }
                    Spacer()
                }
            }
            .padding()
        }
    }

    func averageColor(for value: Double) -> Color {
        switch value {
        case 4.5...: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }
}

struct AverageRow: View {
    let subject: SubjectAverage
    let style: WidgetStyleType
    var showGradeCount: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(subject.name)
                .font(.subheadline)
                .widgetTextStyle(style, colors: nil)
                .lineLimit(1)

            Spacer()

            if showGradeCount {
                Text("(\(subject.gradeCount))")
                    .font(.caption)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)
            }

            Text(subject.formattedAverage)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(subject.averageColor)
        }
        .padding(.vertical, 4)
    }
}
