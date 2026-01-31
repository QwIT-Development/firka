import AppIntents

@available(iOS 16.0, *)
struct GetClosestTimetableIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_closest_timetable_title", defaultValue: "Closest timetable")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("shortcut_closest_timetable_description", defaultValue: "Get the closest school day's timetable (today, tomorrow, or next school day)"))

    func perform() async throws -> some ReturnsValue<[LessonEntity]> & ProvidesDialog {
        guard let data = WidgetData.load() else {
            throw ShortcutError.noData
        }
        let now = Date()

        let remaining = data.timetable.today.filter { $0.end > now }
        if !remaining.isEmpty {
            let entities = remaining.map { LessonEntity(from: $0) }
            let summary = entities.map { "\($0.lessonNumber). \($0.name)" }.joined(separator: ", ")
            return .result(value: entities, dialog: "\(summary)")
        }

        if !data.timetable.tomorrow.isEmpty {
            let entities = data.timetable.tomorrow.map { LessonEntity(from: $0) }
            let summary = entities.map { "\($0.lessonNumber). \($0.name)" }.joined(separator: ", ")
            return .result(value: entities, dialog: "\(summary)")
        }

        if let nextDay = data.timetable.nextSchoolDay, !nextDay.isEmpty {
            let entities = nextDay.map { LessonEntity(from: $0) }
            let summary = entities.map { "\($0.lessonNumber). \($0.name)" }.joined(separator: ", ")
            return .result(value: entities, dialog: "\(summary)")
        }

        throw ShortcutError.noUpcomingLesson
    }
}
