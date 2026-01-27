import Foundation

struct WidgetData: Codable {
    let lastUpdated: Date?
    let locale: String
    let theme: String
    let timetable: TimetableData
    let grades: [WidgetGrade]
    let averages: AveragesData

    static var lastError: String = "Not loaded yet"

    static func load() -> WidgetData? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.app.firka.firkaa"
        ) else {
            lastError = "No App Group container"
            return nil
        }

        let fileURL = containerURL.appendingPathComponent("widget_data.json")

        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        if !fileExists {
            lastError = "File not found at: \(fileURL.path)"
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            lastError = "Could not read file"
            return nil
        }

        lastError = "Read \(data.count) bytes, decoding..."

        let decoder = JSONDecoder()

        let iso8601Full = ISO8601DateFormatter()
        iso8601Full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime]

        let formatterLocal = DateFormatter()
        formatterLocal.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatterLocal.locale = Locale(identifier: "en_US_POSIX")
        formatterLocal.timeZone = TimeZone.current

        let formatterShort = DateFormatter()
        formatterShort.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatterShort.locale = Locale(identifier: "en_US_POSIX")
        formatterShort.timeZone = TimeZone.current

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = iso8601Full.date(from: dateString) {
                return date
            }
            if let date = iso8601.date(from: dateString) {
                return date
            }
            if let date = formatterLocal.date(from: dateString) {
                return date
            }
            if let date = formatterShort.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
        }

        do {
            let widgetData = try decoder.decode(WidgetData.self, from: data)
            lastError = "OK: \(widgetData.timetable.today.count) lessons, \(widgetData.grades.count) grades"
            return widgetData
        } catch let DecodingError.keyNotFound(key, context) {
            lastError = "Missing key: \(key.stringValue) in \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            lastError = "Type mismatch: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            return nil
        } catch let DecodingError.valueNotFound(type, context) {
            lastError = "Null value: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            return nil
        } catch {
            lastError = "Other: \(error)"
            return nil
        }
    }

    static var placeholder: WidgetData {
        WidgetData(
            lastUpdated: nil,
            locale: "hu",
            theme: "dark",
            timetable: TimetableData(today: [], tomorrow: [], currentBreak: nil),
            grades: [],
            averages: AveragesData(overall: nil, subjects: [])
        )
    }
}

struct TimetableData: Codable {
    let today: [WidgetLesson]
    let tomorrow: [WidgetLesson]
    let currentBreak: BreakInfo?
}

struct BreakInfo: Codable {
    let name: String
    let nameKey: String
    let endDate: Date
}

struct AveragesData: Codable {
    let overall: Double?
    let subjects: [SubjectAverage]
}

struct SubjectAverage: Codable, Identifiable {
    let uid: String
    let name: String
    let average: Double
    let gradeCount: Int

    var id: String { uid }
}
