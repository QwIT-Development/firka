import AppIntents

@available(iOS 16.0, *)
struct GetTomorrowTimetableIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_tomorrow_timetable_title", defaultValue: "Tomorrow's timetable")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("shortcut_tomorrow_timetable_description", defaultValue: "Get tomorrow's timetable"))

    func perform() async throws -> some ReturnsValue<[LessonEntity]> & ProvidesDialog {
        guard let data = WidgetData.load() else {
            throw ShortcutError.noData
        }
        guard !data.timetable.tomorrow.isEmpty else {
            throw ShortcutError.noLessonsTomorrow
        }
        let entities = data.timetable.tomorrow.map { LessonEntity(from: $0) }
        let summary = entities.map { "\($0.lessonNumber). \($0.name)" }.joined(separator: ", ")
        return .result(value: entities, dialog: "\(summary)")
    }
}
