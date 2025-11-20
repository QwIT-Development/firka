import ActivityKit
import Foundation

struct TimetableActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isBreak: Bool
        var lessonName: String
        var lessonTheme: String?
        var roomName: String?
        var teacherName: String?
        var startTime: Date
        var endTime: Date
        var lessonNumber: Int?
        
        var mode: String? // "lesson" | "break" | "seasonalBreak" | "xmas" | "newYear"
        var message: String?
        var season: String?
        
        var nextLessonName: String?
        var nextRoomName: String?
        var nextStartTime: Date?

                var isSubstitution: Bool?
        
                var isCancelled: Bool?
        
                var substituteTeacher: String?

                var currentTime: Date

                enum CodingKeys: String, CodingKey {
        
                    case isBreak
        
                    case lessonName
        
                    case lessonTheme
        
                    case roomName
        
                    case teacherName
        
                    case startTime
        
                    case endTime
        
                    case lessonNumber
        
                    case mode
        
                    case message
        
                    case season
        
                    case nextLessonName
        
                    case nextRoomName
        
                    case nextStartTime
        
                    case isSubstitution
        
                    case isCancelled
        
                    case substituteTeacher
        
                    case currentTime
        
                }

                init(isBreak: Bool, lessonName: String, lessonTheme: String?, roomName: String?, teacherName: String?, startTime: Date, endTime: Date, lessonNumber: Int?, mode: String?, message: String?, season: String?, nextLessonName: String?, nextRoomName: String?, nextStartTime: Date?, isSubstitution: Bool?, isCancelled: Bool?, substituteTeacher: String?, currentTime: Date) {
        
                    self.isBreak = isBreak
        
                    self.lessonName = lessonName
        
                    self.lessonTheme = lessonTheme
        
                    self.roomName = roomName
        
                    self.teacherName = teacherName
        
                    self.startTime = startTime
        
                    self.endTime = endTime
        
                    self.lessonNumber = lessonNumber
        
                    self.mode = mode
        
                    self.message = message
        
                    self.season = season
        
                    self.nextLessonName = nextLessonName
        
                    self.nextRoomName = nextRoomName
        
                    self.nextStartTime = nextStartTime
        
                    self.isSubstitution = isSubstitution
        
                    self.isCancelled = isCancelled
        
                    self.substituteTeacher = substituteTeacher
        
                    self.currentTime = currentTime
        
                }
        
                
        
                init(from decoder: Decoder) throws {
        
                    let container = try decoder.container(keyedBy: CodingKeys.self)
        
                    

                    let isoFormatter = ISO8601DateFormatter()
        
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
                    
        
                    isBreak = try container.decode(Bool.self, forKey: .isBreak)
        
                    lessonName = try container.decode(String.self, forKey: .lessonName)
        
                    lessonTheme = try container.decodeIfPresent(String.self, forKey: .lessonTheme)
        
                    roomName = try container.decodeIfPresent(String.self, forKey: .roomName)
        
                    teacherName = try container.decodeIfPresent(String.self, forKey: .teacherName)
        
                    

                    let startTimeStr = try container.decode(String.self, forKey: .startTime)
        
                    guard let startTimeDate = isoFormatter.date(from: startTimeStr) else {
        
                        throw DecodingError.dataCorruptedError(forKey: .startTime, in: container, debugDescription: "Invalid startTime format: \(startTimeStr)")
        
                    }
        
                    startTime = startTimeDate
        
                    
        
                    let endTimeStr = try container.decode(String.self, forKey: .endTime)
        
                    guard let endTimeDate = isoFormatter.date(from: endTimeStr) else {
        
                        throw DecodingError.dataCorruptedError(forKey: .endTime, in: container, debugDescription: "Invalid endTime format: \(endTimeStr)")
        
                    }
        
                    endTime = endTimeDate
        
                    
        
                    lessonNumber = try container.decodeIfPresent(Int.self, forKey: .lessonNumber)
        
                    mode = try container.decodeIfPresent(String.self, forKey: .mode)
        
                    message = try container.decodeIfPresent(String.self, forKey: .message)
        
                    season = try container.decodeIfPresent(String.self, forKey: .season)
        
                    nextLessonName = try container.decodeIfPresent(String.self, forKey: .nextLessonName)
        
                    nextRoomName = try container.decodeIfPresent(String.self, forKey: .nextRoomName)
        
                    
        
                    if let nextStartTimeStr = try container.decodeIfPresent(String.self, forKey: .nextStartTime) {
        
                        nextStartTime = isoFormatter.date(from: nextStartTimeStr)
        
                    } else {
        
                        nextStartTime = nil
        
                    }
        
                    
        
                    isSubstitution = try container.decodeIfPresent(Bool.self, forKey: .isSubstitution)
        
                    isCancelled = try container.decodeIfPresent(Bool.self, forKey: .isCancelled)
        
                    substituteTeacher = try container.decodeIfPresent(String.self, forKey: .substituteTeacher)
        
                    

                    let currentTimeStr = try container.decode(String.self, forKey: .currentTime)
        
                    guard let currentTimeDate = isoFormatter.date(from: currentTimeStr) else {
        
                        throw DecodingError.dataCorruptedError(forKey: .currentTime, in: container, debugDescription: "Invalid currentTime format: \(currentTimeStr)")
        
                    }
        
                    currentTime = currentTimeDate
        
                }
        
                
        
                func encode(to encoder: Encoder) throws {
        
                    var container = encoder.container(keyedBy: CodingKeys.self)
        
                    

                    let isoFormatter = ISO8601DateFormatter()
        
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
                    
        
                    try container.encode(isBreak, forKey: .isBreak)
        
                    try container.encode(lessonName, forKey: .lessonName)
        
                    try container.encodeIfPresent(lessonTheme, forKey: .lessonTheme)
        
                    try container.encodeIfPresent(roomName, forKey: .roomName)
        
                    try container.encodeIfPresent(teacherName, forKey: .teacherName)
        
                    

                    try container.encode(isoFormatter.string(from: startTime), forKey: .startTime)
        
                    try container.encode(isoFormatter.string(from: endTime), forKey: .endTime)
        
                    
        
                    try container.encodeIfPresent(lessonNumber, forKey: .lessonNumber)
        
                    try container.encodeIfPresent(mode, forKey: .mode)
        
                    try container.encodeIfPresent(message, forKey: .message)
        
                    try container.encodeIfPresent(season, forKey: .season)
        
                    try container.encodeIfPresent(nextLessonName, forKey: .nextLessonName)
        
                    try container.encodeIfPresent(nextRoomName, forKey: .nextRoomName)
        
                    
        
                    if let nextStartTime = nextStartTime {
        
                        try container.encode(isoFormatter.string(from: nextStartTime), forKey: .nextStartTime)
        
                    }
        
                    
        
                    try container.encodeIfPresent(isSubstitution, forKey: .isSubstitution)
        
                    try container.encodeIfPresent(isCancelled, forKey: .isCancelled)
        
                    try container.encodeIfPresent(substituteTeacher, forKey: .substituteTeacher)
        
                    

                    try container.encode(isoFormatter.string(from: currentTime), forKey: .currentTime)
        
                }
        
            }
        
            

            var studentName: String
        
            var schoolName: String
        
        }
        
        

        extension TimetableActivityAttributes.ContentState {
        
            var timeRemaining: TimeInterval {
        
                return endTime.timeIntervalSince(currentTime)
        
            }
        
            
        
            var isBeforeSchool: Bool {
        
                return currentTime < startTime && !isBreak
        
            }
        
            
        
            var formattedStartTime: String {
        
                let formatter = DateFormatter()
        
                formatter.dateFormat = "HH:mm"

                formatter.timeZone = TimeZone(identifier: "UTC")
        

                let adjustedDate = Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
        
                return formatter.string(from: adjustedDate)
        
            }
        
            
        
            var formattedEndTime: String {
        
                let formatter = DateFormatter()
        
                formatter.dateFormat = "HH:mm"
        

                formatter.timeZone = TimeZone(identifier: "UTC")
        
                let adjustedDate = Calendar.current.date(byAdding: .hour, value: 1, to: endTime) ?? endTime
        
                return formatter.string(from: adjustedDate)
        
            }
        
            
        
            var formattedNextStartTime: String {
        
                guard let nextStartTime = nextStartTime else { return "" }
        
                let formatter = DateFormatter()
        
                formatter.dateFormat = "HH:mm"
        

                formatter.timeZone = TimeZone(identifier: "UTC")
        
                let adjustedDate = Calendar.current.date(byAdding: .hour, value: 1, to: nextStartTime) ?? nextStartTime
        
                return formatter.string(from: adjustedDate)
        
            }
        
            
        
            var timeRemainingText: String {
        
                let remaining = timeRemaining
        
                
        
                if remaining < 0 {
        
                    return "0:00"
        
                }
        
                
        
                let hours = Int(remaining) / 3600
        
                let minutes = (Int(remaining) % 3600) / 60
        
                let seconds = Int(remaining) % 60
        
                
        
                if hours > 0 {
        
                    return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        
                } else if minutes > 0 {
        
                    return String(format: "%d:%02d", minutes, seconds)
        
                } else {
        
                    return String(format: "0:%02d", seconds)
        
                }
        
            }
        
            
        

            var seasonalRemainingText: String {
        
                let remaining = max(0, timeRemaining)
        
                let hours = Int(remaining) / 3600
        
                if hours >= 24 {
        
                    let days = hours / 24
        
                    return "Szünetből hátralévő idő: \(days) nap"
        
                }
        
                return "Szünetből hátralévő idő: \(hours) óra"
        
            }
        
            
        
            var seasonalDisplayValue: String {
        
                let remaining = max(0, timeRemaining)
        
                let hours = Int(remaining) / 3600
        
                if hours >= 24 {
        
                    let days = hours / 24
        
                    return "\(days) nap"
        
                }
        
                return "\(hours) óra"
        
            }
        
        }
        
        
        

        extension TimetableActivityAttributes.ContentState {
        
            func toJSON() -> [String: Any] {
        
                var json: [String: Any] = [
        
                    "isBreak": isBreak,
        
                    "lessonName": lessonName,
        
                    "startTime": ISO8601DateFormatter().string(from: startTime),
        
                    "endTime": ISO8601DateFormatter().string(from: endTime),
        
                    "currentTime": ISO8601DateFormatter().string(from: currentTime)
        
                ]
        
                
        
                if let isSubstitution = isSubstitution {
        
                    json["isSubstitution"] = isSubstitution
        
                }
        
                if let isCancelled = isCancelled {
        
                    json["isCancelled"] = isCancelled
        
                }
        
                if let lessonTheme = lessonTheme {
        
                    json["lessonTheme"] = lessonTheme
        
                }
        
                if let roomName = roomName {
        
                    json["roomName"] = roomName
        
                }
        
                if let teacherName = teacherName {
        
                    json["teacherName"] = teacherName
        
                }
        
                if let lessonNumber = lessonNumber {
        
                    json["lessonNumber"] = lessonNumber
        
                }
        
                if let nextLessonName = nextLessonName {
        
                    json["nextLessonName"] = nextLessonName
        
                }
        
                if let nextRoomName = nextRoomName {
        
                    json["nextRoomName"] = nextRoomName
        
                }
        
                if let nextStartTime = nextStartTime {
        
                    json["nextStartTime"] = ISO8601DateFormatter().string(from: nextStartTime)
        
                }
        
                if let substituteTeacher = substituteTeacher {
        
                    json["substituteTeacher"] = substituteTeacher
        
                }
        
                if let mode = mode {
        
                    json["mode"] = mode
        
                }
        
                if let message = message {
        
                    json["message"] = message
        
                }
        
                if let season = season {
        
                    json["season"] = season
        
                }
        
                
        
                return json
        
            }
        
            
        
            static func fromJSON(_ json: [String: Any]) -> TimetableActivityAttributes.ContentState? {
        
                let isoFormatter = ISO8601DateFormatter()
        
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                
        
                guard let isBreak = json["isBreak"] as? Bool,
        
                      let lessonName = json["lessonName"] as? String,
        
                      let startTimeStr = json["startTime"] as? String,
        
                      let endTimeStr = json["endTime"] as? String,
        
                      let startTime = isoFormatter.date(from: startTimeStr),
        
                      let endTime = isoFormatter.date(from: endTimeStr) else {
        
                    return nil
        
                }
        

                let currentTimeStr = json["currentTime"] as? String
        
                let currentTime = currentTimeStr.flatMap { isoFormatter.date(from: $0) } ?? Date()
        
                
        
                let nextStartTime: Date?
        
                if let nextStartTimeStr = json["nextStartTime"] as? String {
        
                    nextStartTime = isoFormatter.date(from: nextStartTimeStr)
        
                } else {
        
                    nextStartTime = nil
        
                }
        
                
        
                return TimetableActivityAttributes.ContentState(
        
                    isBreak: isBreak,
        
                    lessonName: lessonName,
        
                    lessonTheme: json["lessonTheme"] as? String,
        
                    roomName: json["roomName"] as? String,
        
                    teacherName: json["teacherName"] as? String,
        
                    startTime: startTime,
        
                    endTime: endTime,
        
                    lessonNumber: json["lessonNumber"] as? Int,
        
                    mode: json["mode"] as? String,
        
                    message: json["message"] as? String,
        
                    season: json["season"] as? String,
        
                    nextLessonName: json["nextLessonName"] as? String,
        
                    nextRoomName: json["nextRoomName"] as? String,
        
                    nextStartTime: nextStartTime,
        
                    isSubstitution: json["isSubstitution"] as? Bool,
        
                    isCancelled: json["isCancelled"] as? Bool,
        
                    substituteTeacher: json["substituteTeacher"] as? String,
        
                    currentTime: currentTime
        
                )
        
            }
        
        }
        
        