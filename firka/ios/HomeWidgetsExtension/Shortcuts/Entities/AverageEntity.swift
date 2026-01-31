import AppIntents
import Foundation

@available(iOS 16.0, *)
struct AverageEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("entity_average", defaultValue: "Average"))
    static var defaultQuery = AverageEntityQuery()

    var id: String

    @Property(title: LocalizedStringResource("entity_prop_subject", defaultValue: "Subject"))
    var subjectName: String

    @Property(title: LocalizedStringResource("entity_prop_average", defaultValue: "Average"))
    var average: Double

    @Property(title: LocalizedStringResource("entity_prop_grade_count", defaultValue: "Grade count"))
    var gradeCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(subjectName)",
            subtitle: "\(String(format: "%.2f", average)) (\(gradeCount))"
        )
    }

    init(from avg: SubjectAverage) {
        self.id = avg.uid
        self.subjectName = avg.name
        self.average = avg.average
        self.gradeCount = avg.gradeCount
    }

    init(id: String, subjectName: String, average: Double, gradeCount: Int) {
        self.id = id
        self.subjectName = subjectName
        self.average = average
        self.gradeCount = gradeCount
    }
}

@available(iOS 16.0, *)
struct AverageEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [AverageEntity] {
        guard let data = WidgetData.load() else { return [] }
        return data.averages.subjects
            .filter { identifiers.contains($0.uid) }
            .map { AverageEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [AverageEntity] {
        guard let data = WidgetData.load() else { return [] }
        return data.averages.subjects.map { AverageEntity(from: $0) }
    }
}
