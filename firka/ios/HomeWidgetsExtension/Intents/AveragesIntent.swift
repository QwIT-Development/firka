import AppIntents
import WidgetKit

struct SubjectEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("subjects_type", defaultValue: "Subjects"))
    }

    static var defaultQuery = SubjectQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct SubjectQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SubjectEntity] {
        let data = WidgetData.load()
        return data?.averages.subjects
            .filter { identifiers.contains($0.uid) }
            .map { SubjectEntity(id: $0.uid, name: $0.name) } ?? []
    }

    func suggestedEntities() async throws -> [SubjectEntity] {
        let data = WidgetData.load()
        return data?.averages.subjects
            .map { SubjectEntity(id: $0.uid, name: $0.name) } ?? []
    }

    func defaultResult() async -> SubjectEntity? {
        try? await suggestedEntities().first
    }
}

struct AveragesWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("widget_averages_title", defaultValue: "Averages")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("widget_averages_description", defaultValue: "Shows subject averages"))

    @Parameter(title: LocalizedStringResource("param_style", defaultValue: "Style"), default: .liquidGlass)
    var style: WidgetStyle?

    @Parameter(title: LocalizedStringResource("param_subjects", defaultValue: "Subjects"))
    var selectedSubjects: [SubjectEntity]?
}
