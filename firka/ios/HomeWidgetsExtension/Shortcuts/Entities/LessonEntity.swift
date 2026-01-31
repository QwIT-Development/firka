import AppIntents
import Foundation

@available(iOS 16.0, *)
struct LessonEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("entity_lesson", defaultValue: "Lesson"))
    static var defaultQuery = LessonEntityQuery()

    var id: String

    @Property(title: LocalizedStringResource("entity_prop_name", defaultValue: "Name"))
    var name: String

    @Property(title: LocalizedStringResource("entity_prop_teacher", defaultValue: "Teacher"))
    var teacher: String

    @Property(title: LocalizedStringResource("entity_prop_room", defaultValue: "Room"))
    var room: String

    @Property(title: LocalizedStringResource("entity_prop_start_time", defaultValue: "Start time"))
    var startTime: Date

    @Property(title: LocalizedStringResource("entity_prop_end_time", defaultValue: "End time"))
    var endTime: Date

    @Property(title: LocalizedStringResource("entity_prop_lesson_number", defaultValue: "Lesson number"))
    var lessonNumber: Int

    @Property(title: LocalizedStringResource("entity_prop_cancelled", defaultValue: "Cancelled"))
    var isCancelled: Bool

    @Property(title: LocalizedStringResource("entity_prop_substitution", defaultValue: "Substitution"))
    var isSubstitution: Bool

    @Property(title: LocalizedStringResource("entity_prop_theme", defaultValue: "Theme"))
    var theme: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(lessonNumber). \(room) - \(teacher)"
        )
    }

    init(from lesson: WidgetLesson) {
        self.id = lesson.uid
        self.name = lesson.subject.name
        self.teacher = lesson.teacher ?? ""
        self.room = lesson.roomName ?? ""
        self.startTime = lesson.start
        self.endTime = lesson.end
        self.lessonNumber = lesson.lessonNumber ?? 0
        self.isCancelled = lesson.isCancelled
        self.isSubstitution = lesson.isSubstitution
        self.theme = lesson.theme ?? ""
    }

    init(id: String, name: String, teacher: String, room: String, startTime: Date, endTime: Date, lessonNumber: Int, isCancelled: Bool, isSubstitution: Bool, theme: String) {
        self.id = id
        self.name = name
        self.teacher = teacher
        self.room = room
        self.startTime = startTime
        self.endTime = endTime
        self.lessonNumber = lessonNumber
        self.isCancelled = isCancelled
        self.isSubstitution = isSubstitution
        self.theme = theme
    }
}

@available(iOS 16.0, *)
struct LessonEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [LessonEntity] {
        guard let data = WidgetData.load() else { return [] }
        let allLessons = data.timetable.today + data.timetable.tomorrow + (data.timetable.nextSchoolDay ?? [])
        return allLessons
            .filter { identifiers.contains($0.uid) }
            .map { LessonEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [LessonEntity] {
        guard let data = WidgetData.load() else { return [] }
        return data.timetable.today.map { LessonEntity(from: $0) }
    }
}
