import AppIntents

@available(iOS 16.0, *)
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

@available(iOS 16.0, *)
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
