import AppIntents

@available(iOS 16.0, *)
struct GetClosestLessonIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_closest_lesson_title", defaultValue: "Closest lesson")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("shortcut_closest_lesson_description", defaultValue: "Get the closest lesson (today, tomorrow, or next school day)"))

    func perform() async throws -> some ReturnsValue<LessonEntity> & ProvidesDialog {
        guard let data = WidgetData.load() else {
            throw ShortcutError.noData
        }
        let now = Date()

        if let lesson = data.timetable.today.first(where: { $0.start > now })
            ?? data.timetable.today.first(where: { $0.end > now }) {
            let entity = LessonEntity(from: lesson)
            return .result(value: entity, dialog: "\(entity.name) - \(entity.room)")
        }

        if let lesson = data.timetable.tomorrow.first {
            let entity = LessonEntity(from: lesson)
            return .result(value: entity, dialog: "\(entity.name) - \(entity.room)")
        }

        if let lesson = data.timetable.nextSchoolDay?.first {
            let entity = LessonEntity(from: lesson)
            return .result(value: entity, dialog: "\(entity.name) - \(entity.room)")
        }

        throw ShortcutError.noUpcomingLesson
    }
}
