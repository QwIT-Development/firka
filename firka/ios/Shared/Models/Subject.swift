import Foundation

struct WidgetSubject: Codable {
    let uid: String
    let name: String
    let category: NameUidDesc?
    let sortIndex: Int?
    let teacherName: String?

    init(uid: String, name: String, category: NameUidDesc?, sortIndex: Int?, teacherName: String?) {
        self.uid = uid
        self.name = name
        self.category = category
        self.sortIndex = sortIndex
        self.teacherName = teacherName
    }
}

struct NameUidDesc: Codable {
    let uid: String
    let name: String
    let description: String?

    init(uid: String, name: String, description: String?) {
        self.uid = uid
        self.name = name
        self.description = description
    }
}
