import Foundation
import Security

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

    #if os(iOS)
    private let deviceName = "iPhone"
    #elseif os(watchOS)
    private let deviceName = "Watch"
    #endif

    private init() {
        iCloudTokenManager.shared.observeChanges { [weak self] iCloudToken in
            guard let self = self else { return }

            if let localToken = self.loadTokenFromKeychain() {
                if iCloudToken.expiryDate > localToken.expiryDate {
                    print("[TokenManager] iCloud token is fresher (\(iCloudToken.expiryDate) > \(localToken.expiryDate)), updating local cache")
                    try? self.saveTokenToKeychain(iCloudToken)
                    try? self.saveTokenToFile(iCloudToken)

                    #if os(watchOS)
                    DataStore.shared.checkTokenState()
                    #endif
                } else {
                    print("[TokenManager] Local token is fresher or equal, ignoring iCloud update and pushing local to iCloud")
                    iCloudTokenManager.shared.saveToken(localToken, deviceName: self.deviceName)
                }
            } else {
                print("[TokenManager] No local token, using iCloud token")
                try? self.saveTokenToKeychain(iCloudToken)
                try? self.saveTokenToFile(iCloudToken)

                #if os(watchOS)
                DataStore.shared.checkTokenState()
                #endif
            }
        }
    }

    // MARK: - File Management
    private func getTokenFilePath() -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        return containerURL.appendingPathComponent(tokenFileName)
    }

    // MARK: - Load Token (fresher-wins strategy)
    func loadToken() -> WatchToken? {
        let iCloudToken = iCloudTokenManager.shared.loadToken()
        let keychainToken = loadTokenFromKeychain()
        let fileToken = loadTokenFromFile()

        var candidates: [(token: WatchToken, source: String)] = []
        if let t = iCloudToken { candidates.append((t, "iCloud")) }
        if let t = keychainToken { candidates.append((t, "keychain")) }
        if let t = fileToken { candidates.append((t, "file")) }

        guard !candidates.isEmpty else {
            print("[TokenManager] No token found anywhere")
            return nil
        }

        let freshest = candidates.max(by: { $0.token.expiryDate < $1.token.expiryDate })!

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current

        print("[TokenManager] Token sources found: \(candidates.map { "\($0.source): \(formatter.string(from: $0.token.expiryDate))" }.joined(separator: ", "))")
        print("[TokenManager] Using freshest token from \(freshest.source) (expiry: \(formatter.string(from: freshest.token.expiryDate)))")

        if iCloudToken == nil || iCloudToken!.expiryDate < freshest.token.expiryDate {
            print("[TokenManager] Syncing fresher token to iCloud")
            iCloudTokenManager.shared.saveToken(freshest.token, deviceName: deviceName)
        }
        if keychainToken == nil || keychainToken!.expiryDate < freshest.token.expiryDate {
            print("[TokenManager] Syncing fresher token to keychain")
            try? saveTokenToKeychain(freshest.token)
        }
        if fileToken == nil || fileToken!.expiryDate < freshest.token.expiryDate {
            print("[TokenManager] Syncing fresher token to file")
            try? saveTokenToFile(freshest.token)
        }

        return freshest.token
    }

    private func loadTokenFromFile() -> WatchToken? {
        guard let filePath = getTokenFilePath() else {
            return nil
        }

        do {
            let data = try Data(contentsOf: filePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(WatchToken.self, from: data)
        } catch {
            return nil
        }
    }

    // MARK: - Delete Token
    func deleteToken() {
        print("[TokenManager] Deleting token from all storage locations")
        deleteTokenFromKeychain()
        iCloudTokenManager.shared.deleteToken()

        guard let filePath = getTokenFilePath() else { return }
        try? FileManager.default.removeItem(at: filePath)
    }

    // MARK: - Save Token (to all storage locations)
    func saveToken(_ token: WatchToken) throws {
        print("[TokenManager] Saving token to all storage locations")

        try saveTokenToKeychain(token)

        iCloudTokenManager.shared.saveToken(token, deviceName: deviceName)

        guard let filePath = getTokenFilePath() else {
            throw TokenError.networkError
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(token)
        try data.write(to: filePath)
    }

    private func saveTokenToFile(_ token: WatchToken) throws {
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
