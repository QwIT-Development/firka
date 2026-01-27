import AppIntents
import WidgetKit

struct GradesWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("widget_grades_title", defaultValue: "Recent Grades")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("widget_grades_description", defaultValue: "Shows your recent grades"))

    @Parameter(title: LocalizedStringResource("param_style", defaultValue: "Style"), default: .appTheme)
    var style: WidgetStyle?
}
