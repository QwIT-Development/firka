import SwiftUI
import WidgetKit

struct GradesSmallView: View {
    let entry: GradesEntry
    let localization: WidgetLocalization

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 4) {
                Text(localization.string("recent_grades"))
                    .font(.caption)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)

                if let grade = entry.grades.first {
                    Spacer()

                    HStack {
                        Text(grade.displayValue)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(grade.gradeColor)

                        Spacer()
                    }

                    Text(grade.subject.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .widgetTextStyle(style, colors: nil)
                        .lineLimit(1)

                    Text(grade.dateString)
                        .font(.caption)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                } else {
                    Spacer()
                    Text(localization.string("no_grades"))
                        .font(.subheadline)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct GradesMediumView: View {
    let entry: GradesEntry
    let localization: WidgetLocalization

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.string("recent_grades"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .widgetTextStyle(style, colors: nil, isPrimary: false)

                if entry.grades.isEmpty {
                    Spacer()
                    Text(localization.string("no_grades"))
                        .font(.subheadline)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                    Spacer()
                } else {
                    ForEach(entry.grades.prefix(3)) { grade in
                        GradeRow(grade: grade, style: style, showType: true)
                    }
                }
            }
            .padding()
        }
        .clipped()
    }
}

struct GradesLargeView: View {
    let entry: GradesEntry
    let localization: WidgetLocalization

    var style: WidgetStyleType {
        (entry.configuration.style ?? .appTheme) == .liquidGlass ? .liquidGlass : .appTheme
    }

    var body: some View {
        ZStack {
            WidgetBackground(style: style, colors: nil)

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.string("recent_grades"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .widgetTextStyle(style, colors: nil)

                if entry.grades.isEmpty {
                    Spacer()
                    Text(localization.string("no_grades"))
                        .font(.subheadline)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                    Spacer()
                } else {
                    ForEach(entry.grades.prefix(6)) { grade in
                        GradeRow(grade: grade, style: style, showType: true, showTopic: true)
                    }
                }
            }
            .padding()
        }
        .clipped()
    }
}

struct GradeRow: View {
    let grade: WidgetGrade
    let style: WidgetStyleType
    var showType: Bool = false
    var showTopic: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(grade.displayValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(grade.gradeColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(grade.subject.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .widgetTextStyle(style, colors: nil)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if showType {
                        Text(grade.type.name)
                            .font(.caption)
                            .widgetTextStyle(style, colors: nil, isPrimary: false)
                    }

                    Text("•")
                        .font(.caption)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)

                    Text(grade.dateString)
                        .font(.caption)
                        .widgetTextStyle(style, colors: nil, isPrimary: false)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
