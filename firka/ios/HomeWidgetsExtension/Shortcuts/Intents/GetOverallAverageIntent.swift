import AppIntents

@available(iOS 16.0, *)
struct GetOverallAverageIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_overall_average_title", defaultValue: "Overall average")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("shortcut_overall_average_description", defaultValue: "Get the overall academic average"))

    func perform() async throws -> some ReturnsValue<Double> & ProvidesDialog {
        guard let data = WidgetData.load() else {
            throw ShortcutError.noData
        }
        guard let overall = data.averages.overall else {
            throw ShortcutError.noData
        }
        let rounded = (overall * 100).rounded() / 100
        return .result(value: rounded, dialog: "\(String(format: "%.2f", rounded))")
    }
}
