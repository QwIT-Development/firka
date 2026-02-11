import Foundation

// MARK: - API Error Types

enum APIError: Error {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    case unauthorized
    case tokenError(TokenError)
}

// MARK: - Kréta API Client

class KretaAPIClient {
    static let shared = KretaAPIClient()

    private let apiKey = "21ff6c25-d1da-4a68-a811-c881a6057463"
    private let userAgent = "eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0"
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    private init() {}

    // MARK: - Public API Methods
    func fetchTimetable(from: Date, to: Date) async throws -> [WidgetLesson] {
        let token = try await getValidToken()
        let fromString = dateFormatter.string(from: from)
        let toString = dateFormatter.string(from: to)

        let path = "/ellenorzo/v3/sajat/OrarendElemek"
        let queryItems = [
            URLQueryItem(name: "datumTol", value: fromString),
            URLQueryItem(name: "datumIg", value: toString)
        ]

        let data = try await performRequest(
            path: path,
            queryItems: queryItems,
            token: token
        )

        let kretaLessons = try decodeJSON([KretaLesson].self, from: data)
        return kretaLessons.map { $0.toWidgetLesson() }
    }

    func fetchGrades() async throws -> [WidgetGrade] {
        let token = try await getValidToken()
        let path = "/ellenorzo/v3/sajat/Ertekelesek"

        let data = try await performRequest(
            path: path,
            token: token
        )

        let kretaGrades = try decodeJSON([KretaGrade].self, from: data)
        return kretaGrades.map { $0.toWidgetGrade() }
    }

    func fetchTests() async throws -> [[String: Any]] {
        let token = try await getValidToken()
        let path = "/ellenorzo/v3/sajat/BejelentettSzamonkeresek"

        let data = try await performRequest(
            path: path,
            token: token
        )

        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw APIError.decodingFailed(DecodingError.typeMismatch(
                [[String: Any]].self,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Expected array of dictionaries"
                )
            ))
        }

        return json
    }

    // MARK: - Token Management

    func getValidToken() async throws -> WatchToken {
        if let token = TokenManager.shared.loadToken() {
            let expiryThreshold = token.expiryDate.addingTimeInterval(-60)
            if Date() < expiryThreshold {
                return token
            }
        }

        print("[KretaAPI] Token invalid or expired, starting recovery...")
        if let recoveredToken = await TokenManager.shared.recoverToken() {
            print("[KretaAPI] Token recovery succeeded")
            return recoveredToken
        }

        print("[KretaAPI] Token recovery failed")
        throw APIError.tokenError(.noToken)
    }

    // MARK: - Private Helper Methods
    private func performRequest(
        path: String,
        queryItems: [URLQueryItem] = [],
        token: WatchToken
    ) async throws -> Data {
        let baseURLString = "https://\(token.iss).e-kreta.hu"
        guard let baseURL = URL(string: baseURLString) else {
            throw APIError.invalidURL
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue(apiKey, forHTTPHeaderField: "X-ApiKey")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.requestFailed(statusCode: -1)
            }

            switch httpResponse.statusCode {
            case 200:
                return data

            case 401:
                throw APIError.unauthorized

            case 400...599:
                throw APIError.requestFailed(statusCode: httpResponse.statusCode)

            default:
                throw APIError.requestFailed(statusCode: httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(statusCode: -1)
        }
    }

    private func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = createJSONDecoder()

        do {
            return try decoder.decode(type, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingFailed(error)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    private func createJSONDecoder() -> JSONDecoder {
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

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(dateString)"
            )
        }

        return decoder
    }
}
