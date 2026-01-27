import Foundation

struct WidgetLesson: Codable, Identifiable {
    let uid: String
    let date: String
    let start: Date
    let end: Date
    let name: String
    let lessonNumber: Int?
    let teacher: String?
    let subject: WidgetSubject
    let theme: String?
    let roomName: String?
    let isCancelled: Bool
    let isSubstitution: Bool

    var id: String { uid }

    var displayName: String {
        subject.name
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: start)
    }

    var isCurrentlyActive: Bool {
        let now = Date()
        return now >= start && now <= end
    }

    var isUpcoming: Bool {
        return Date() < start
    }
}
