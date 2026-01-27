import Foundation

struct WidgetSubject: Codable {
    let uid: String
    let name: String
    let category: NameUidDesc?
    let sortIndex: Int
    let teacherName: String?
}

struct NameUidDesc: Codable {
    let uid: String
    let name: String
    let description: String?
}
