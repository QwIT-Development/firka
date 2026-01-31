import AppIntents

@available(iOS 16.0, *)
struct GetTodayTimetableIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_today_timetable_title", defaultValue: "Today's timetable")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("shortcut_today_timetable_description", defaultValue: "Get today's full timetable"))

    func perform() async throws -> some ReturnsValue<[LessonEntity]> & ProvidesDialog {
        guard let data = WidgetData.load() else {
            throw ShortcutError.noData
        }
        guard !data.timetable.today.isEmpty else {
            throw ShortcutError.noLessonsToday
        }
        let entities = data.timetable.today.map { LessonEntity(from: $0) }
        let summary = entities.map { "\($0.lessonNumber). \($0.name)" }.joined(separator: ", ")
        return .result(value: entities, dialog: "\(summary)")
    }
}
