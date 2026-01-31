import AppIntents
import WidgetKit

struct AveragesWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("widget_averages_title", defaultValue: "Averages")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("widget_averages_description", defaultValue: "Shows subject averages"))

    @Parameter(title: LocalizedStringResource("param_style", defaultValue: "Style"), default: .liquidGlass)
    var style: WidgetStyle?

    @Parameter(title: LocalizedStringResource("param_subjects", defaultValue: "Subjects"))
    var selectedSubjects: [SubjectEntity]?
}
