import Foundation

@available(iOS 16.0, *)
enum ShortcutError: Error, CustomLocalizedStringResourceConvertible {
    case noData
    case noUpcomingLesson
    case noLessonsToday
    case noLessonsTomorrow
    case subjectNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noData:
            return LocalizedStringResource("shortcut_error_no_data", defaultValue: "No data available. Open the Firka app to refresh.")
        case .noUpcomingLesson:
            return LocalizedStringResource("shortcut_error_no_upcoming_lesson", defaultValue: "No more lessons today.")
        case .noLessonsToday:
            return LocalizedStringResource("shortcut_error_no_lessons_today", defaultValue: "No lessons today.")
        case .noLessonsTomorrow:
            return LocalizedStringResource("shortcut_error_no_lessons_tomorrow", defaultValue: "No lessons tomorrow.")
        case .subjectNotFound:
            return LocalizedStringResource("shortcut_error_subject_not_found", defaultValue: "Subject not found.")
        }
    }
}
