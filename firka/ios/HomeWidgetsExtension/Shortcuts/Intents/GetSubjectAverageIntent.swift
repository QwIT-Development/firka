import AppIntents

@available(iOS 16.0, *)
struct GetSubjectAverageIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_subject_average_title", defaultValue: "Subject average")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("shortcut_subject_average_description", defaultValue: "Get the average for a subject"))

    @Parameter(title: LocalizedStringResource("shortcut_param_subject", defaultValue: "Subject"))
    var subject: SubjectEntity

    func perform() async throws -> some ReturnsValue<AverageEntity> & ProvidesDialog {
        guard let data = WidgetData.load() else {
            throw ShortcutError.noData
        }
        guard let avg = data.averages.subjects.first(where: { $0.uid == subject.id }) else {
            throw ShortcutError.subjectNotFound
        }
        let entity = AverageEntity(from: avg)
        return .result(value: entity, dialog: "\(entity.subjectName): \(String(format: "%.2f", entity.average))")
    }
}
