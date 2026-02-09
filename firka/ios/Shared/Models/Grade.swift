import Foundation
import SwiftUI

struct WidgetGrade: Codable, Identifiable {
    let uid: String
    let recordDate: Date
    let subject: WidgetSubject
    let topic: String?
    let type: NameUidDesc
    let valueType: NameUidDesc?
    let numericValue: Int?
    let strValue: String?
    let weightPercentage: Int?

    var id: String { uid }

    init(uid: String, recordDate: Date, subject: WidgetSubject, topic: String?,
         type: NameUidDesc, valueType: NameUidDesc?, numericValue: Int?, strValue: String?, weightPercentage: Int?) {
        self.uid = uid
        self.recordDate = recordDate
        self.subject = subject
        self.topic = topic
        self.type = type
        self.valueType = valueType
        self.numericValue = numericValue
        self.strValue = strValue
        self.weightPercentage = weightPercentage
    }

    var isPercentageGrade: Bool {
        valueType?.name.lowercased().contains("szazalekos") ?? false
    }

    static func percentageToGrade(_ percentage: Int) -> Int {
        if percentage < 50 { return 1 }
        if percentage < 60 { return 2 }
        if percentage < 70 { return 3 }
        if percentage < 80 { return 4 }
        return 5
    }

    var normalizedNumericValue: Int? {
        guard let numeric = numericValue else { return nil }
        if isPercentageGrade {
            return WidgetGrade.percentageToGrade(numeric)
        }
        return numeric
    }

    var displayValue: String {
        if let numeric = numericValue {
            return "\(numeric)"
        }
        return strValue ?? ""
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d."
        return formatter.string(from: recordDate)
    }

    var gradeColor: Color {
        guard let value = normalizedNumericValue else { return .gray }
        switch value {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .gray
        }
    }

    var subjectNameWithWeight: String {
        if let weight = weightPercentage, weight != 100 {
            return "\(subject.name) (\(weight)%)"
        }
        return subject.name
    }

    var teacherName: String? {
        subject.teacherName
    }
}

extension WidgetGrade {
    var displayType: String {
        let typeMap: [String: String] = [
            "evkozi_jegy_ertekeles": "Órai munka",
            "felevi_jegy_ertekeles": "Félévi jegy",
            "evvegi_jegy_ertekeles": "Év végi jegy",
            "dolgozat": "Dolgozat",
            "ropdolgozat": "Röpdolgozat",
            "hazi_feladat": "Házi feladat",
            "osztalyzat": "Osztályzat",
            "szorgalom": "Szorgalom",
            "magatartas": "Magatartás"
        ]
        return typeMap[type.name.lowercased()] ?? type.name.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var displayTypeWithWeight: String {
        if let weight = weightPercentage, weight != 100 {
            return "\(displayType) (\(weight)%)"
        }
        return displayType
    }

    var displayGradeValue: String {
        if isPercentageGrade, let numeric = numericValue {
            return "\(numeric)%"
        }
        if let numeric = numericValue {
            return "\(numeric)"
        }
        return strValue ?? ""
    }
}
