import AppIntents
import WidgetKit

enum TimetableDisplayMode: String, AppEnum {
    case current = "current"
    case next = "next"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("display_mode_type", defaultValue: "Display Mode"))
    }

    static var caseDisplayRepresentations: [TimetableDisplayMode: DisplayRepresentation] {
        [
            .current: DisplayRepresentation(title: LocalizedStringResource("display_mode_current", defaultValue: "Current Lesson")),
            .next: DisplayRepresentation(title: LocalizedStringResource("display_mode_next", defaultValue: "Next Lesson"))
        ]
    }
}

enum WidgetStyle: String, AppEnum {
    case liquidGlass = "liquid_glass"
    case appTheme = "app_theme"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("style_type", defaultValue: "Style"))
    }

    static var caseDisplayRepresentations: [WidgetStyle: DisplayRepresentation] {
        [
            .liquidGlass: DisplayRepresentation(title: LocalizedStringResource("style_liquid_glass", defaultValue: "Liquid Glass")),
            .appTheme: DisplayRepresentation(title: LocalizedStringResource("style_app_theme", defaultValue: "App Theme"))
        ]
    }
}

struct TimetableWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("widget_timetable_title", defaultValue: "Timetable")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("widget_timetable_description", defaultValue: "Shows your daily timetable"))

    @Parameter(title: LocalizedStringResource("param_style", defaultValue: "Style"), default: .liquidGlass)
    var style: WidgetStyle?

    @Parameter(title: LocalizedStringResource("param_display_mode_small", defaultValue: "Small Widget Display"), default: .current)
    var displayMode: TimetableDisplayMode?
}
