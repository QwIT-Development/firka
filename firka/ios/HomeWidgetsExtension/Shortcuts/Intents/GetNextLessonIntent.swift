import AppIntents

@available(iOS 16.0, *)
struct GetNextLessonIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_next_lesson_title", defaultValue: "Next lesson")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("shortcut_next_lesson_description", defaultValue: "Get the next lesson details"))

    func perform() async throws -> some ReturnsValue<LessonEntity> & ProvidesDialog {
        guard let data = WidgetData.load() else {
            throw ShortcutError.noData
        }
        let now = Date()
        let upcoming = data.timetable.today.first { $0.start > now }
            ?? data.timetable.today.first { $0.end > now }
        guard let lesson = upcoming else {
            throw ShortcutError.noUpcomingLesson
        }
        let entity = LessonEntity(from: lesson)
        return .result(value: entity, dialog: "\(entity.name) - \(entity.room)")
    }
}
