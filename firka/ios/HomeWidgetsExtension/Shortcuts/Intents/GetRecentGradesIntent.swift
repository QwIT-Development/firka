import AppIntents

@available(iOS 16.0, *)
struct GetRecentGradesIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_recent_grades_title", defaultValue: "Recent grades")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("shortcut_recent_grades_description", defaultValue: "Get the most recent grades"))

    @Parameter(title: LocalizedStringResource("shortcut_param_count", defaultValue: "Count"), default: 5)
    var count: Int

    func perform() async throws -> some ReturnsValue<[GradeEntity]> & ProvidesDialog {
        guard let data = WidgetData.load() else {
            throw ShortcutError.noData
        }
        let grades = Array(data.grades.prefix(count))
        let entities = grades.map { GradeEntity(from: $0) }
        let summary = entities.map { "\($0.subject): \($0.strValue)" }.joined(separator: ", ")
        return .result(value: entities, dialog: "\(summary)")
    }
}
