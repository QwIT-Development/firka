import Foundation
import Observation
import WidgetKit
import WatchConnectivity

// MARK: - Cache Wrapper

struct CachedWatchData: Codable {
    let widgetData: WidgetData
    let lastUpdated: Date
}

// MARK: - DataStore

@Observable
class DataStore {
    static let shared = DataStore()

    var data: WidgetData?
    var lastUpdated: Date?
    var isLoading: Bool = false
    var error: String?

    var isRecoveringToken: Bool = false

    private(set) var recoveryAttempted: Bool = false

    private(set) var hasToken: Bool = false

    var needsReauth: Bool {
        (error == "token_expired" || error == "no_token") && recoveryAttempted && !isRecoveringToken
    }

    private let appGroupID = "group.app.firka.firkaa"
    private let cacheFileName = "watch_data.json"

    private init() {
        checkTokenState()
        loadFromCache()
    }


    var hasValidToken: Bool {
        TokenManager.shared.loadToken() != nil
    }

    func checkTokenState() {
        hasToken = TokenManager.shared.loadToken() != nil
        print("[Watch] Token state updated: hasToken = \(hasToken)")
    }

    // MARK: - Cache Loading

    func loadFromCache() {
        if let widgetData = WidgetData.load() {
            self.data = widgetData
            self.lastUpdated = widgetData.lastUpdated
            return
        }

        guard let cachedData = loadWatchCache() else {
            return
        }

        self.data = cachedData.widgetData
        self.lastUpdated = cachedData.lastUpdated
    }

    private func loadWatchCache() -> CachedWatchData? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            return nil
        }

        let fileURL = containerURL.appendingPathComponent(cacheFileName)

        guard let cacheData = try? Data(contentsOf: fileURL) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(CachedWatchData.self, from: cacheData)
    }

    private func saveToCache(_ data: WidgetData) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            return
        }

        let fileURL = containerURL.appendingPathComponent(cacheFileName)
        let cached = CachedWatchData(widgetData: data, lastUpdated: Date())

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let encodedData = try encoder.encode(cached)
            try encodedData.write(to: fileURL)
        } catch {
            self.error = "Failed to save cache"
        }
    }

    // MARK: - Cache Management

    func clearCache() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }

        let fileURL = containerURL.appendingPathComponent(cacheFileName)
        try? FileManager.default.removeItem(at: fileURL)

        data = nil
        lastUpdated = nil

        print("[Watch] Cache cleared")
    }

    func clearAll() {
        clearCache()
        error = nil
        isLoading = false
        checkTokenState()

        print("[Watch] All data cleared")
    }

    func clearError() {
        error = nil
        print("[Watch] Error cleared")
    }

    func setReauthRequired() {
        error = "token_expired"
        print("[Watch] Reauth required state set")
    }

    func resetRecoveryState() {
        recoveryAttempted = false
        error = nil
        print("[Watch] Recovery state reset")
    }

    func attemptTokenRecovery() async -> Bool {
        guard !isRecoveringToken else {
            print("[Watch] Token recovery already in progress")
            return false
        }

        isRecoveringToken = true
        recoveryAttempted = false
        error = nil
        print("[Watch] Starting background token recovery...")

        defer {
            isRecoveringToken = false
        }

        let retryDelays: [UInt64] = [0, 2, 5]
        var isNetworkError = false
        var isTokenPermanentlyInvalid = false

        for (attemptIndex, delaySeconds) in retryDelays.enumerated() {
            if delaySeconds > 0 {
                print("[Watch] Recovery attempt \(attemptIndex + 1): waiting \(delaySeconds)s before retry...")
                try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            }

            print("[Watch] Recovery attempt \(attemptIndex + 1)/\(retryDelays.count) - Step 1: Checking iCloud for updated token...")
            if let iCloudToken = iCloudTokenManager.shared.loadToken() {
                if !isTokenExpired(iCloudToken) {
                    print("[Watch] Recovery: Found valid token in iCloud!")
                    try? TokenManager.shared.saveToken(iCloudToken)
                    checkTokenState()
                    return true
                } else {
                    print("[Watch] Recovery: iCloud token is expired, trying refresh...")
                }
            }

            print("[Watch] Recovery attempt \(attemptIndex + 1)/\(retryDelays.count) - Step 2: Attempting API token refresh...")
            do {
                _ = try await TokenManager.shared.refreshToken()
                print("[Watch] Recovery: Token refresh succeeded!")
                checkTokenState()
                return true
            } catch let tokenError as TokenError {
                print("[Watch] Recovery: API token refresh failed: \(tokenError)")
                switch tokenError {
                case .networkError:
                    isNetworkError = true
                case .refreshExpired, .invalidGrant:
                    isTokenPermanentlyInvalid = true
                default:
                    break
                }
            } catch {
                print("[Watch] Recovery: API token refresh failed with unknown error: \(error)")
                isNetworkError = true
            }

            print("[Watch] Recovery attempt \(attemptIndex + 1)/\(retryDelays.count) - Step 3: Checking if iPhone is reachable...")
            if await requestTokenFromiPhoneAsync() {
                print("[Watch] Recovery: Got token from iPhone!")
                checkTokenState()
                return true
            }

            if attemptIndex < retryDelays.count - 1 {
                print("[Watch] Recovery attempt \(attemptIndex + 1) failed, retrying...")
            }
        }

        if isTokenPermanentlyInvalid {
            print("[Watch] Recovery: Token permanently invalid, showing reauth screen")
            recoveryAttempted = true
            self.error = "token_expired"
        } else if isNetworkError {
            print("[Watch] Recovery: Network error - not showing reauth, user can retry")
            self.error = "network"
        } else {
            print("[Watch] Recovery: All retries failed, treating as transient/network issue")
            self.error = "network"
        }

        return false
    }

    private func isTokenExpired(_ token: WatchToken) -> Bool {
        let expiryThreshold = token.expiryDate.addingTimeInterval(-60)
        return Date() >= expiryThreshold
    }

    private func requestTokenFromiPhoneAsync() async -> Bool {
        return await withCheckedContinuation { continuation in
            guard WCSession.default.activationState == .activated,
                  WCSession.default.isReachable else {
                print("[Watch] Recovery: iPhone not reachable")
                continuation.resume(returning: false)
                return
            }

            print("[Watch] Recovery: Requesting token from iPhone...")

            WCSession.default.sendMessage(
                ["action": "requestToken"],
                replyHandler: { response in
                    if let authDict = response["auth"] as? [String: Any] {
                        print("[Watch] Recovery: Received token from iPhone")
                        self.processAuthDataSync(authDict)
                        continuation.resume(returning: true)
                    } else {
                        print("[Watch] Recovery: iPhone returned no token")
                        continuation.resume(returning: false)
                    }
                },
                errorHandler: { error in
                    print("[Watch] Recovery: iPhone request failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                }
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            }
        }
    }

    private func processAuthDataSync(_ authDict: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: authDict)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let timestamp = try container.decode(Int64.self)
                return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
            }
            let token = try decoder.decode(WatchToken.self, from: jsonData)
            try TokenManager.shared.saveToken(token)
            print("[Watch] Recovery: Token saved from iPhone")
        } catch {
            print("[Watch] Recovery: Failed to process auth data: \(error)")
        }
    }

    private func refreshComplications() {
        WidgetCenter.shared.reloadAllTimelines()
        print("[Watch] Complications refreshed")
    }

    // MARK: - Proactive Token Refresh

    func refreshTokenProactively() async {
        guard hasValidToken else { return }
        await TokenManager.shared.refreshTokenProactively()
        checkTokenState()
    }

    // MARK: - Data Refresh

    func refreshAll() async {
        guard !isLoading else {
            print("[Watch] DataStore.refreshAll() already in progress, skipping duplicate call")
            return
        }

        print("[Watch] DataStore.refreshAll() called")
        isLoading = true
        error = nil

        defer { isLoading = false }

        await TokenManager.shared.refreshTokenProactively()

        guard hasValidToken else {
            print("[Watch] No valid token, setting error = no_token")
            error = "no_token"
            return
        }

        do {
            let (startOfWeek, endOfWeek) = getCurrentWeekDateRange()

            async let timetableTask = KretaAPIClient.shared.fetchTimetable(
                from: startOfWeek,
                to: endOfWeek
            )
            async let gradesTask = KretaAPIClient.shared.fetchGrades()

            let (lessons, grades) = try await (timetableTask, gradesTask)

            let timetableData = buildTimetableData(from: lessons)
            let averagesData = buildAveragesData(from: grades)

            let widgetData = WidgetData(
                lastUpdated: Date(),
                locale: Locale.current.language.languageCode?.identifier ?? "hu",
                theme: "dark",
                timetable: timetableData,
                grades: grades,
                averages: averagesData
            )

            self.data = widgetData
            self.lastUpdated = Date()

            saveToCache(widgetData)

            refreshComplications()

            print("[Watch] refreshAll() completed successfully")

        } catch let error as APIError {
            handleAPIError(error)
        } catch {
            print("[Watch] refreshAll() network error: \(error)")
            self.error = "network"
        }
    }

    func refreshAllWithRecovery() async {
        await refreshAll()

        guard error == "token_expired" || error == "no_token" else {
            return
        }

        print("[Watch] Token issue after refreshAll(), starting auto-recovery flow...")
        let recovered = await attemptTokenRecovery()
        if recovered {
            await refreshAll()
        }
    }

    /// Handles API errors and maps them to user-friendly messages
    private func handleAPIError(_ error: APIError) {
        print("[Watch] handleAPIError: \(error)")
        switch error {
        case .tokenError(let tokenError):
            switch tokenError {
            case .noToken:
                print("[Watch] Setting error = no_token")
                self.error = "no_token"
            case .refreshExpired, .invalidGrant:
                print("[Watch] Setting error = token_expired")
                self.error = "token_expired"
            case .invalidResponse, .networkError:
                print("[Watch] Setting error = network (token error)")
                self.error = "network"
            }
        case .unauthorized:
            print("[Watch] Setting error = token_expired (unauthorized)")
            self.error = "token_expired"
        case .requestFailed(let statusCode):
            if statusCode >= 500 {
                print("[Watch] Setting error = api_error (server error \(statusCode))")
                self.error = "api_error"
            } else {
                print("[Watch] Setting error = network (request failed \(statusCode))")
                self.error = "network"
            }
        case .decodingFailed, .invalidURL:
            print("[Watch] Setting error = network")
            self.error = "network"
        }
    }

    // MARK: - Data Processing

    private func buildTimetableData(from lessons: [WidgetLesson]) -> TimetableData {
        let today = Date()
        let todayString = formatDateForComparison(today)
        let tomorrowString = formatDateForComparison(today.addingTimeInterval(86400))

        let todayLessons = lessons.filter { $0.date == todayString }.sorted { $0.start < $1.start }
        let tomorrowLessons = lessons.filter { $0.date == tomorrowString }.sorted { $0.start < $1.start }

        var nextSchoolDayLessons: [WidgetLesson]? = nil
        var nextSchoolDayDateString: String? = nil

        for daysOffset in 2...14 {
            let checkDate = today.addingTimeInterval(TimeInterval(daysOffset * 86400))
            let checkDateString = formatDateForComparison(checkDate)
            let checkLessons = lessons.filter { $0.date == checkDateString }

            if !checkLessons.isEmpty {
                nextSchoolDayLessons = checkLessons.sorted { $0.start < $1.start }
                nextSchoolDayDateString = checkDateString
                break
            }
        }

        let currentBreak: BreakInfo? = nil

        return TimetableData(
            today: todayLessons,
            tomorrow: tomorrowLessons,
            nextSchoolDay: nextSchoolDayLessons,
            nextSchoolDayDate: nextSchoolDayDateString,
            currentBreak: currentBreak,
            allLessons: lessons
        )
    }

    /// Builds AveragesData from grades (matching Flutter's calculation)
    private func buildAveragesData(from grades: [WidgetGrade]) -> AveragesData {
        guard !grades.isEmpty else {
            return AveragesData(overall: nil, subjects: [])
        }

        var subjectGradesMap: [String: [(value: Int, weight: Double)]] = [:]

        for grade in grades {
            if let numeric = grade.normalizedNumericValue {
                let key = grade.subject.uid
                let weight = Double(grade.weightPercentage ?? 100) / 100.0
                subjectGradesMap[key, default: []].append((value: numeric, weight: weight))
            }
        }

        var subjectAverages: [SubjectAverage] = []

        for (uid, gradeValues) in subjectGradesMap {
            if let firstGrade = grades.first(where: { $0.subject.uid == uid }) {
                var weightedSum = 0.0
                var totalWeight = 0.0

                for (value, weight) in gradeValues {
                    weightedSum += Double(value) * weight
                    totalWeight += weight
                }

                let average = totalWeight > 0 ? weightedSum / totalWeight : Double.nan

                if !average.isNaN {
                    subjectAverages.append(
                        SubjectAverage(
                            uid: uid,
                            name: firstGrade.subject.name,
                            average: average,
                            gradeCount: gradeValues.count
                        )
                    )
                }
            }
        }

        let overall: Double?
        if !subjectAverages.isEmpty {
            let sumOfAverages = subjectAverages.reduce(0.0) { $0 + $1.average }
            overall = sumOfAverages / Double(subjectAverages.count)
        } else {
            overall = nil
        }

        return AveragesData(overall: overall, subjects: subjectAverages)
    }

    private func getCurrentWeekDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()

        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = weekday == 1 ? -6 : (2 - weekday)
        let monday = calendar.date(byAdding: .day, value: daysToMonday, to: today)!

        let nextSunday = calendar.date(byAdding: .day, value: 13, to: monday)!

        return (monday, nextSunday)
    }

    private func formatDateForComparison(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d",
                      components.year ?? 0,
                      components.month ?? 0,
                      components.day ?? 0)
    }

    // MARK: - Computed Helpers

    var timeSinceUpdate: String? {
        guard let lastUpdated = lastUpdated else { return nil }

        let elapsed = Date().timeIntervalSince(lastUpdated)

        if elapsed < 60 {
            return nil
        }

        // Minutes
        let minutes = Int(elapsed / 60)
        if minutes < 60 {
            return minutes == 1 ? "1 perce" : "\(minutes) perce"
        }

        // Hours
        let hours = Int(elapsed / 3600)
        if hours < 24 {
            return hours == 1 ? "1 órája" : "\(hours) órája"
        }

        // Days
        let days = Int(elapsed / 86400)
        return days == 1 ? "1 napja" : "\(days) napja"
    }

    /// Returns true if data is stale (> 1 hour old or never updated)
    var isStale: Bool {
        guard let lastUpdated = lastUpdated else { return true }

        let elapsed = Date().timeIntervalSince(lastUpdated)
        return elapsed > 3600 // 1 hour
    }
}
