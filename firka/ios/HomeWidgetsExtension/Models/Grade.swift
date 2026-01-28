import Foundation
import SwiftUI

struct WidgetGrade: Codable, Identifiable {
    let uid: String
    let recordDate: Date
    let subject: WidgetSubject
    let topic: String?
    let type: NameUidDesc
    let numericValue: Int?
    let strValue: String?
    let weightPercentage: Int?

    var id: String { uid }

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
        guard let value = numericValue else { return .gray }
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
