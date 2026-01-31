import AppIntents
import Foundation

@available(iOS 16.0, *)
struct GradeEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("entity_grade", defaultValue: "Grade"))
    static var defaultQuery = GradeEntityQuery()

    var id: String

    @Property(title: LocalizedStringResource("entity_prop_subject", defaultValue: "Subject"))
    var subject: String

    @Property(title: LocalizedStringResource("entity_prop_value", defaultValue: "Value"))
    var numericValue: Int

    @Property(title: LocalizedStringResource("entity_prop_grade", defaultValue: "Grade"))
    var strValue: String

    @Property(title: LocalizedStringResource("entity_prop_topic", defaultValue: "Topic"))
    var topic: String

    @Property(title: LocalizedStringResource("entity_prop_type", defaultValue: "Type"))
    var type: String

    @Property(title: LocalizedStringResource("entity_prop_teacher", defaultValue: "Teacher"))
    var teacher: String

    @Property(title: LocalizedStringResource("entity_prop_date", defaultValue: "Date"))
    var date: Date

    @Property(title: LocalizedStringResource("entity_prop_weight", defaultValue: "Weight"))
    var weight: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(subject): \(strValue)",
            subtitle: "\(topic)"
        )
    }

    init(from grade: WidgetGrade) {
        self.id = grade.uid
        self.subject = grade.subject.name
        self.numericValue = grade.numericValue ?? 0
        self.strValue = grade.displayValue
        self.topic = grade.topic ?? ""
        self.type = grade.type.name
        self.teacher = grade.subject.teacherName ?? ""
        self.date = grade.recordDate
        self.weight = grade.weightPercentage ?? 100
    }

    init(id: String, subject: String, numericValue: Int, strValue: String, topic: String, type: String, teacher: String, date: Date, weight: Int) {
        self.id = id
        self.subject = subject
        self.numericValue = numericValue
        self.strValue = strValue
        self.topic = topic
        self.type = type
        self.teacher = teacher
        self.date = date
        self.weight = weight
    }
}

@available(iOS 16.0, *)
struct GradeEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [GradeEntity] {
        guard let data = WidgetData.load() else { return [] }
        return data.grades
            .filter { identifiers.contains($0.uid) }
            .map { GradeEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [GradeEntity] {
        guard let data = WidgetData.load() else { return [] }
        return data.grades.prefix(10).map { GradeEntity(from: $0) }
    }
}
