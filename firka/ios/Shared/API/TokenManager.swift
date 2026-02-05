import Foundation
import Security

// MARK: - Token Structure
struct WatchToken: Codable {
    let accessToken: String
    let refreshToken: String
    let idToken: String
    let iss: String
    let studentId: String
    let studentIdNorm: Int64
    let expiryDate: Date

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case idToken
        case iss
        case studentId
        case studentIdNorm
        case expiryDate
    }
}

// MARK: - Token Response Structure
private struct TokenRefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let idToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - Error Types
enum TokenError: Error {
    case noToken
    case refreshExpired
    case invalidGrant
    case invalidResponse
    case networkError
}

// MARK: - Token Manager
class TokenManager {
    static let shared = TokenManager()

    private let appGroupID = "group.app.firka.firkaa"
    private let tokenFileName = "watch_token.json"

    private static let keychainService = "app.firka.watch.token"
    private static let keychainAccount = "token"
    private let tokenRefreshURL = "https://idp.e-kreta.hu/connect/token"
    private let clientID = "kreta-ellenorzo-student-mobile-ios"
    private let userAgent = "eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0"

    private init() {}

    // MARK: - File Management
    private func getTokenFilePath() -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        return containerURL.appendingPathComponent(tokenFileName)
    }

    // MARK: - Load Token
    func loadToken() -> WatchToken? {
        if let token = loadTokenFromKeychain() {
            return token
        }

        guard let filePath = getTokenFilePath() else {
            return nil
        }

        do {
            let data = try Data(contentsOf: filePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let token = try decoder.decode(WatchToken.self, from: data)

            try? saveTokenToKeychain(token)

            return token
        } catch {
            return nil
        }
    }

    // MARK: - Delete Token
    func deleteToken() {
        deleteTokenFromKeychain()

        guard let filePath = getTokenFilePath() else { return }
        try? FileManager.default.removeItem(at: filePath)
    }

    // MARK: - Save Token
    func saveToken(_ token: WatchToken) throws {
        try saveTokenToKeychain(token)

        guard let filePath = getTokenFilePath() else {
            throw TokenError.networkError
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(token)
        try data.write(to: filePath)
    }

    // MARK: - Keychain Methods
    func saveTokenToKeychain(_ token: WatchToken) throws {
        let data = try JSONEncoder().encode(token)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("[TokenManager] Keychain save failed: \(status)")
            throw TokenError.networkError
        }
        print("[TokenManager] Token saved to Keychain")
    }

    func loadTokenFromKeychain() -> WatchToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WatchToken.self, from: data)
    }

    func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]

        SecItemDelete(query as CFDictionary)
        print("[TokenManager] Token deleted from Keychain")
    }

    // MARK: - Check Expiry
    func isTokenExpired() -> Bool {
        guard let token = loadToken() else {
            return true
        }

        let expiryThreshold = token.expiryDate.addingTimeInterval(-60)
        return Date() >= expiryThreshold
    }

    func shouldRefreshProactively() -> Bool {
        guard let token = loadToken() else {
            return false
        }

        let proactiveThreshold = token.expiryDate.addingTimeInterval(-12 * 3600)
        return Date() >= proactiveThreshold
    }

    func refreshTokenProactively() async {
        guard shouldRefreshProactively() else {
            print("[TokenManager] Token still valid, no proactive refresh needed")
            return
        }

        print("[TokenManager] Proactively refreshing token...")
        do {
            _ = try await refreshToken()
            print("[TokenManager] Proactive token refresh succeeded")
        } catch {
            print("[TokenManager] Proactive token refresh failed: \(error)")
        }
    }

    // MARK: - Refresh Token
    func refreshToken() async throws -> WatchToken {
        guard let currentToken = loadToken() else {
            throw TokenError.noToken
        }

        let response = try await performTokenRefresh(
            refreshToken: currentToken.refreshToken,
            instituteCode: currentToken.iss
        )

        let newToken = WatchToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            idToken: response.idToken,
            iss: currentToken.iss,
            studentId: currentToken.studentId,
            studentIdNorm: currentToken.studentIdNorm,
            expiryDate: Date().addingTimeInterval(Double(response.expiresIn) - 60)
        )

        try saveToken(newToken)

        #if os(watchOS)
        WatchConnectivityManager.shared.sendTokenToiPhoneInBackground()
        #endif

        return newToken
    }

    // MARK: - Private Helper Methods
    private func performTokenRefresh(
        refreshToken: String,
        instituteCode: String
    ) async throws -> TokenRefreshResponse {
        guard let url = URL(string: tokenRefreshURL) else {
            throw TokenError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        let formParameters: [String: String] = [
            "institute_code": instituteCode,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
            "client_id": clientID
        ]

        request.httpBody = encodeFormData(formParameters).data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TokenError.networkError
            }

            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(TokenRefreshResponse.self, from: data)

            case 400:
                throw TokenError.refreshExpired

            case 401:
                throw TokenError.invalidGrant

            default:
                throw TokenError.invalidResponse
            }
        } catch let error as TokenError {
            throw error
        } catch {
            throw TokenError.networkError
        }
    }

    private func encodeFormData(_ parameters: [String: String]) -> String {
        return parameters
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
    }
}
