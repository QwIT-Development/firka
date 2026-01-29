import WidgetKit
import SwiftUI
import AppIntents

private let appGroup = "group.app.firka.firkaa"

// MARK: - Home Control

@available(iOS 18.0, *)
struct HomeControl: ControlWidget {
    static let kind = "app.firka.firkaa.control.home"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenHomeIntent()) {
                Label("Főoldal", systemImage: "house.fill")
            }
        }
        .displayName("Firka - Főoldal")
        .description("Firka app főoldal megnyitása")
    }
}

@available(iOS 18.0, *)
struct OpenHomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Firka Főoldal"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: appGroup)?.set("home", forKey: "controlNavigation")
        return .result()
    }
}

// MARK: - Grades Control

@available(iOS 18.0, *)
struct GradesControl: ControlWidget {
    static let kind = "app.firka.firkaa.control.grades"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenGradesIntent()) {
                Label("Jegyek", systemImage: "star.fill")
            }
        }
        .displayName("Firka - Jegyek")
        .description("Firka app jegyek megnyitása")
    }
}

@available(iOS 18.0, *)
struct OpenGradesIntent: AppIntent {
    static var title: LocalizedStringResource = "Firka Jegyek"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: appGroup)?.set("grades", forKey: "controlNavigation")
        return .result()
    }
}

// MARK: - Timetable Control

@available(iOS 18.0, *)
struct TimetableControl: ControlWidget {
    static let kind = "app.firka.firkaa.control.timetable"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTimetableIntent()) {
                Label("Órarend", systemImage: "calendar")
            }
        }
        .displayName("Firka - Órarend")
        .description("Firka app órarend megnyitása")
    }
}

@available(iOS 18.0, *)
struct OpenTimetableIntent: AppIntent {
    static var title: LocalizedStringResource = "Firka Órarend"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: appGroup)?.set("timetable", forKey: "controlNavigation")
        return .result()
    }
}
