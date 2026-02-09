import Foundation

// MARK: - Kréta API Response Models
struct KretaLesson: Decodable {
    let uid: String
    let date: String
    let start: Date
    let end: Date
    let name: String
    let lessonNumber: Int?
    let teacher: String?
    let subject: KretaSubject?
    let theme: String?
    let roomName: String?
    let state: KretaNameUidDesc?
    let substituteTeacher: String?

    enum CodingKeys: String, CodingKey {
        case uid = "Uid"
        case date = "Datum"
        case start = "KezdetIdopont"
        case end = "VegIdopont"
        case name = "Nev"
        case lessonNumber = "Oraszam"
        case teacher = "TanarNeve"
        case subject = "Tantargy"
        case theme = "Tema"
        case roomName = "TeremNeve"
        case state = "Allapot"
        case substituteTeacher = "HelyettesTanarNeve"
    }

    func toWidgetLesson() -> WidgetLesson {
        let widgetSubject = subject.map { sub in
            WidgetSubject(
                uid: sub.uid,
                name: sub.name,
                category: sub.category.map { cat in
                    NameUidDesc(uid: cat.uid, name: cat.name, description: cat.description)
                },
                sortIndex: sub.sortIndex ?? 0,
                teacherName: sub.teacherName
            )
        } ?? WidgetSubject(
            uid: "",
            name: name,
            category: nil,
            sortIndex: 0,
            teacherName: nil
        )

        let isCancelled = state?.name.lowercased().contains("elmarad") ?? false

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: start)
        let dateString = String(format: "%04d-%02d-%02d",
                                components.year ?? 0,
                                components.month ?? 0,
                                components.day ?? 0)

        return WidgetLesson(
            uid: uid,
            date: dateString,
            start: start,
            end: end,
            name: name,
            lessonNumber: lessonNumber,
            teacher: teacher,
            substituteTeacher: substituteTeacher,
            subject: widgetSubject,
            theme: theme,
            roomName: roomName,
            isCancelled: isCancelled,
            isSubstitution: substituteTeacher != nil
        )
    }
}

struct KretaSubject: Decodable {
    let uid: String
    let name: String
    let category: KretaNameUidDesc?
    let sortIndex: Int?
    let teacherName: String?

    enum CodingKeys: String, CodingKey {
        case uid = "Uid"
        case name = "Nev"
        case category = "Kategoria"
        case sortIndex = "SortIndex"
        case teacherName = "alkalmazottNev"
    }
}

struct KretaNameUidDesc: Decodable {
    let uid: String
    let name: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case uid = "Uid"
        case name = "Nev"
        case description = "Leiras"
    }
}

// MARK: - API Grade Response

struct KretaGrade: Decodable {
    let uid: String
    let recordDate: Date
    let subject: KretaSubject
    let topic: String?
    let type: KretaNameUidDesc
    let valueType: KretaNameUidDesc?
    let numericValue: Int?
    let strValue: String?
    let weightPercentage: Int?

    enum CodingKeys: String, CodingKey {
        case uid = "Uid"
        case recordDate = "RogzitesDatuma"
        case subject = "Tantargy"
        case topic = "Tema"
        case type = "Tipus"
        case valueType = "ErtekFajta"
        case numericValue = "SzamErtek"
        case strValue = "SzovegesErtek"
        case weightPercentage = "SulySzazalekErteke"
    }

    func toWidgetGrade() -> WidgetGrade {
        let widgetSubject = WidgetSubject(
            uid: subject.uid,
            name: subject.name,
            category: subject.category.map { cat in
                NameUidDesc(uid: cat.uid, name: cat.name, description: cat.description)
            },
            sortIndex: subject.sortIndex ?? 0,
            teacherName: subject.teacherName
        )

        let widgetType = NameUidDesc(
            uid: type.uid,
            name: type.name,
            description: type.description
        )

        let widgetValueType = valueType.map { vt in
            NameUidDesc(uid: vt.uid, name: vt.name, description: vt.description)
        }

        return WidgetGrade(
            uid: uid,
            recordDate: recordDate,
            subject: widgetSubject,
            topic: topic,
            type: widgetType,
            valueType: widgetValueType,
            numericValue: numericValue,
            strValue: strValue,
            weightPercentage: weightPercentage
        )
    }
}
