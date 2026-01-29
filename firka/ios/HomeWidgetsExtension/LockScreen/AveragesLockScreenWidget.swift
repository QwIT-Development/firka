import WidgetKit
import SwiftUI

// MARK: - Lock Screen Averages Widget

struct AveragesLockScreenWidget: Widget {
    let kind: String = "AveragesLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: AveragesWidgetIntent.self,
            provider: AveragesProvider()
        ) { entry in
            AveragesLockScreenView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("widget_averages_title", defaultValue: "Averages"))
        .description(LocalizedStringResource("widget_averages_lockscreen_description", defaultValue: "Shows your averages on lock screen"))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Lock Screen View

struct AveragesLockScreenView: View {
    @Environment(\.widgetFamily) var family
    let entry: AveragesEntry

    var localization: WidgetLocalization {
        WidgetLocalization(locale: entry.locale)
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                AveragesInlineView(entry: entry, localization: localization)
            case .accessoryCircular:
                AveragesCircularView(entry: entry, localization: localization)
            case .accessoryRectangular:
                AveragesRectangularView(entry: entry, localization: localization)
            default:
                Text("--")
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Inline View

struct AveragesInlineView: View {
    let entry: AveragesEntry
    let localization: WidgetLocalization

    var body: some View {
        if let overall = entry.overallAverage {
            Text("\(localization.string("average_short")): \(String(format: "%.2f", overall))")
        } else if let first = entry.subjectAverages.first {
            Text("\(first.name): \(String(format: "%.2f", first.average))")
        } else {
            Text(localization.string("no_averages"))
        }
    }
}

// MARK: - Circular View

struct AveragesCircularView: View {
    let entry: AveragesEntry
    let localization: WidgetLocalization

    var body: some View {
        if let overall = entry.overallAverage {
            Gauge(value: overall, in: 1...5) {
                Text("")
            } currentValueLabel: {
                Text(String(format: "%.1f", overall))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(averageColor(overall))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(averageColor(overall))
        } else if let first = entry.subjectAverages.first {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text(String(format: "%.1f", first.average))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(averageColor(first.average))
                    Text(String(first.name.prefix(4)))
                        .font(.system(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "chart.bar")
                    .font(.title2)
            }
        }
    }

    private func averageColor(_ value: Double) -> Color {
        switch value {
        case 4.5...: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }
}

// MARK: - Rectangular View

struct AveragesRectangularView: View {
    let entry: AveragesEntry
    let localization: WidgetLocalization

    var body: some View {
        if let overall = entry.overallAverage {
            HStack(spacing: 8) {
                Text(String(format: "%.2f", overall))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(averageColor(overall))
                    .fixedSize()

                VStack(alignment: .leading, spacing: 0) {
                    Text(localization.string("average_short"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(localization.string("subjects_count", entry.subjectAverages.count))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if !entry.subjectAverages.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.string("subject_averages_title"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(entry.subjectAverages.prefix(3), id: \.uid) { subject in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(String(format: "%.1f", subject.average))
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(averageColor(subject.average))
                            Text(String(subject.name.prefix(5)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading) {
                Label(localization.string("no_averages"), systemImage: "chart.bar")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func averageColor(_ value: Double) -> Color {
        switch value {
        case 4.5...: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }
}
