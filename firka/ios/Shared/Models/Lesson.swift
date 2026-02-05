import Foundation

struct WidgetLesson: Codable, Identifiable {
    let uid: String
    let date: String
    let start: Date
    let end: Date
    let name: String
    let lessonNumber: Int?
    let teacher: String?
    let substituteTeacher: String?
    let subject: WidgetSubject
    let theme: String?
    let roomName: String?
    let isCancelled: Bool
    let isSubstitution: Bool

    var id: String { uid }

    init(uid: String, date: String, start: Date, end: Date, name: String,
         lessonNumber: Int?, teacher: String?, substituteTeacher: String?, subject: WidgetSubject,
         theme: String?, roomName: String?, isCancelled: Bool, isSubstitution: Bool) {
        self.uid = uid
        self.date = date
        self.start = start
        self.end = end
        self.name = name
        self.lessonNumber = lessonNumber
        self.teacher = teacher
        self.substituteTeacher = substituteTeacher
        self.subject = subject
        self.theme = theme
        self.roomName = roomName
        self.isCancelled = isCancelled
        self.isSubstitution = isSubstitution
    }

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
