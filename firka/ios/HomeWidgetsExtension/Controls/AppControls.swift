import WidgetKit
import SwiftUI
import AppIntents

private let appGroup = "group.app.firka.firkaa"

// MARK: - Navigation Intents (iOS 16+, used by Controls and Shortcuts)

@available(iOS 16.0, *)
struct OpenHomeIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("control_home_title", defaultValue: "Firka Home")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("control_home_description", defaultValue: "Open Firka home screen"))
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: appGroup)?.set("home", forKey: "controlNavigation")
        return .result()
    }
}

@available(iOS 16.0, *)
struct OpenGradesIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("control_grades_title", defaultValue: "Firka Grades")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("control_grades_description", defaultValue: "Open Firka grades"))
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: appGroup)?.set("grades", forKey: "controlNavigation")
        return .result()
    }
}

@available(iOS 16.0, *)
struct OpenTimetableIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("control_timetable_title", defaultValue: "Firka Timetable")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource("control_timetable_description", defaultValue: "Open Firka timetable"))
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: appGroup)?.set("timetable", forKey: "controlNavigation")
        return .result()
    }
}

// MARK: - Home Control (iOS 18+)

@available(iOS 18.0, *)
struct HomeControl: ControlWidget {
    static let kind = "app.firka.firkaa.control.home"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenHomeIntent()) {
                Label(LocalizedStringResource("control_home_label", defaultValue: "Home"), systemImage: "house.fill")
            }
        }
        .displayName(LocalizedStringResource("control_home_display", defaultValue: "Firka - Home"))
        .description(LocalizedStringResource("control_home_description", defaultValue: "Open Firka home screen"))
    }
}

// MARK: - Grades Control (iOS 18+)

@available(iOS 18.0, *)
struct GradesControl: ControlWidget {
    static let kind = "app.firka.firkaa.control.grades"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenGradesIntent()) {
                Label(LocalizedStringResource("control_grades_label", defaultValue: "Grades"), systemImage: "star.fill")
            }
        }
        .displayName(LocalizedStringResource("control_grades_display", defaultValue: "Firka - Grades"))
        .description(LocalizedStringResource("control_grades_description", defaultValue: "Open Firka grades"))
    }
}

// MARK: - Timetable Control (iOS 18+)

@available(iOS 18.0, *)
struct TimetableControl: ControlWidget {
    static let kind = "app.firka.firkaa.control.timetable"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTimetableIntent()) {
                Label(LocalizedStringResource("control_timetable_label", defaultValue: "Timetable"), systemImage: "calendar")
            }
        }
        .displayName(LocalizedStringResource("control_timetable_display", defaultValue: "Firka - Timetable"))
        .description(LocalizedStringResource("control_timetable_description", defaultValue: "Open Firka timetable"))
    }
}
