import Foundation
import Security
#if os(watchOS)
import WatchConnectivity
#endif

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
    private let recoveryLock = NSLock()
    private var recoveryInProgress = false

    private func startRecoveryIfNeeded() -> Bool {
        recoveryLock.lock()
        defer { recoveryLock.unlock() }
        if recoveryInProgress {
            return false
        }
        recoveryInProgress = true
        return true
    }

    private func finishRecovery() {
        recoveryLock.lock()
        recoveryInProgress = false
        recoveryLock.unlock()
    }

    private func isRecoveryRunning() -> Bool {
        recoveryLock.lock()
        defer { recoveryLock.unlock() }
        return recoveryInProgress
    }

    private init() {
        iCloudTokenManager.shared.observeChanges { [weak self] iCloudToken in
            guard let self = self else { return }

            let isValidToken = iCloudToken.expiryDate > Date().addingTimeInterval(60)

            let keychainToken = self.loadTokenFromKeychain()
            let fileToken = self.loadTokenFromFile()
            let localToken: WatchToken? = {
                if let k = keychainToken, let f = fileToken {
                    return k.isNewer(than: f) ? k : f
                }
                return keychainToken ?? fileToken
            }()

            if let localToken = localToken {
                if iCloudToken.isNewer(than: localToken) {
                    print("[TokenManager] iCloud token is fresher, updating local cache")
                    try? self.saveTokenToKeychain(iCloudToken)
                    try? self.saveTokenToFile(iCloudToken)

                    #if os(watchOS)
                    DataStore.shared.checkTokenState()
                    #endif

                    #if os(iOS)
                    if isValidToken {
                        self.notifyiOSTokenRecovered()
                    }
                    #endif
                } else {
                    print("[TokenManager] Local token is fresher or equal, ignoring iCloud update")
                }
            } else {
                print("[TokenManager] No local token, using iCloud token")
                try? self.saveTokenToKeychain(iCloudToken)
                try? self.saveTokenToFile(iCloudToken)

                #if os(watchOS)
                DataStore.shared.checkTokenState()
                #endif

                #if os(iOS)
                if isValidToken {
                    self.notifyiOSTokenRecovered()
                }
                #endif
            }
        }
    }

    #if os(iOS)
    private func notifyiOSTokenRecovered() {
        print("[TokenManager] Valid token received from iCloud, notifying Flutter to clear reauth flag")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("TokenRecoveredFromiCloud"),
                object: nil
            )
        }
    }
    #endif

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

        let freshest = candidates.dropFirst().reduce(candidates[0]) { currentBest, candidate in
            candidate.token.isNewer(than: currentBest.token) ? candidate : currentBest
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current

        print("[TokenManager] Token sources found: \(candidates.map { "\($0.source): \(formatter.string(from: $0.token.expiryDate))" }.joined(separator: ", "))")
        print("[TokenManager] Using freshest token from \(freshest.source) (expiry: \(formatter.string(from: freshest.token.expiryDate)))")

        if keychainToken == nil || freshest.token.isNewer(than: keychainToken!) {
            print("[TokenManager] Syncing fresher token to keychain")
            try? saveTokenToKeychain(freshest.token)
        }
        if fileToken == nil || freshest.token.isNewer(than: fileToken!) {
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

    // MARK: - Save Token
    func saveToken(_ token: WatchToken, syncToICloud: Bool = false) throws {
        if let currentToken = loadToken(), !token.isNewer(than: currentToken) {
            print("[TokenManager] Ignoring stale or same token save attempt")
            return
        }

        print("[TokenManager] Saving token locally (Keychain + file)")

        try saveTokenToKeychain(token)

        if syncToICloud {
            iCloudTokenManager.shared.saveToken(token, deviceName: deviceName)
        }

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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(token)

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
        if let token = try? decoder.decode(WatchToken.self, from: data) {
            return token
        }

        if let legacyToken = try? JSONDecoder().decode(WatchToken.self, from: data) {
            try? saveTokenToKeychain(legacyToken)
            return legacyToken
        }

        return nil
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
        guard let token = loadToken() else {
            print("[TokenManager] No token available for proactive refresh")
            return
        }

        let proactiveThreshold = token.expiryDate.addingTimeInterval(-12 * 3600)
        guard Date() >= proactiveThreshold else {
            print("[TokenManager] Token still valid, no proactive refresh needed")
            return
        }

        print("[TokenManager] Proactively refreshing token...")
        do {
            _ = try await refreshTokenInternal(token)
            print("[TokenManager] Proactive token refresh succeeded")
        } catch {
            print("[TokenManager] Proactive token refresh failed: \(error)")
        }
    }

    // MARK: - Central Token Recovery
    func recoverToken() async -> WatchToken? {
        if !startRecoveryIfNeeded() {
            print("[TokenManager] Recovery already in progress, waiting for current recovery...")
            for _ in 0..<40 {
                if let token = loadToken(), !isTokenExpired() {
                    print("[TokenManager] Current recovery produced a valid token")
                    return token
                }

                if !isRecoveryRunning() {
                    break
                }
                try? await Task.sleep(nanoseconds: 250_000_000)
            }

            if let token = loadToken(), !isTokenExpired() {
                print("[TokenManager] Valid token became available after waiting")
                return token
            }

            print("[TokenManager] Existing recovery did not yield a valid token")
            return nil
        }

        defer { finishRecovery() }

        print("[TokenManager] Starting central token recovery...")

        print("[TokenManager] Step 1: Trying local token refresh...")
        if let token = loadToken() {
            do {
                let refreshedToken = try await refreshTokenInternal(token)
                print("[TokenManager] Step 1 SUCCESS: Local refresh succeeded")
                return refreshedToken
            } catch {
                print("[TokenManager] Step 1 FAILED: Local refresh failed: \(error)")
            }
        } else {
            print("[TokenManager] Step 1 SKIPPED: No local token found")
        }

        print("[TokenManager] Step 2: Checking Keychain and WatchConnectivity...")
        if let recoveredToken = await tryRecoverFromKeychainAndWatch() {
            do {
                let refreshedToken = try await refreshTokenInternal(recoveredToken)
                print("[TokenManager] Step 2 SUCCESS: Keychain/Watch token refresh succeeded")
                return refreshedToken
            } catch {
                print("[TokenManager] Step 2 FAILED: Keychain/Watch token refresh failed: \(error)")
            }
        } else {
            print("[TokenManager] Step 2 SKIPPED: No token from Keychain/Watch")
        }

        print("[TokenManager] Step 3: Trying iCloud recovery with retries...")
        let retryDelays: [TimeInterval] = [0, 5, 10, 5, 10]
        var iCloudHasToken = false

        for (attempt, delay) in retryDelays.enumerated() {
            if delay > 0 {
                if !iCloudHasToken && attempt > 0 {
                    print("[TokenManager] Step 3: Skipping retries - iCloud has no token")
                    break
                }
                print("[TokenManager] Step 3: Waiting \(Int(delay))s before attempt \(attempt + 1)...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            print("[TokenManager] Step 3: iCloud attempt \(attempt + 1)/\(retryDelays.count)...")

            if let iCloudToken = iCloudTokenManager.shared.loadToken() {
                iCloudHasToken = true
                if iCloudToken.expiryDate > Date() {
                    print("[TokenManager] Step 3: Found valid iCloud token, trying refresh...")
                    do {
                        let refreshedToken = try await refreshTokenInternal(iCloudToken)
                        print("[TokenManager] Step 3 SUCCESS: iCloud token refresh succeeded on attempt \(attempt + 1)")
                        return refreshedToken
                    } catch {
                        print("[TokenManager] Step 3: iCloud token refresh failed on attempt \(attempt + 1): \(error)")
                    }
                } else {
                    print("[TokenManager] Step 3: iCloud token is expired, trying refresh anyway...")
                    do {
                        let refreshedToken = try await refreshTokenInternal(iCloudToken)
                        print("[TokenManager] Step 3 SUCCESS: Expired iCloud token refresh succeeded on attempt \(attempt + 1)")
                        return refreshedToken
                    } catch {
                        print("[TokenManager] Step 3: Expired iCloud token refresh failed on attempt \(attempt + 1): \(error)")
                    }
                }
            } else {
                print("[TokenManager] Step 3: No token in iCloud on attempt \(attempt + 1)")
                if attempt == 0 {
                    iCloudHasToken = false
                }
            }
        }

        print("[TokenManager] All recovery attempts failed")
        return nil
    }

    private func tryRecoverFromKeychainAndWatch() async -> WatchToken? {
        var candidates: [(token: WatchToken, source: String)] = []

        if let keychainToken = loadTokenFromKeychain() {
            candidates.append((keychainToken, "keychain"))
            print("[TokenManager] Found token in Keychain")
        }

        if let fileToken = loadTokenFromFile() {
            candidates.append((fileToken, "file"))
            print("[TokenManager] Found token in file storage")
        }

        #if os(watchOS)
        if let watchToken = await requestTokenFromiPhoneForRecovery() {
            candidates.append((watchToken, "WatchConnectivity"))
            print("[TokenManager] Found token from iPhone via WatchConnectivity")
        }
        #endif

        guard !candidates.isEmpty else {
            return nil
        }

        let freshest = candidates.dropFirst().reduce(candidates[0]) { currentBest, candidate in
            candidate.token.isNewer(than: currentBest.token) ? candidate : currentBest
        }
        print("[TokenManager] Using freshest token from \(freshest.source)")
        return freshest.token
    }

    #if os(watchOS)
    private func requestTokenFromiPhoneForRecovery() async -> WatchToken? {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("[TokenManager] iPhone not reachable for recovery")
            return nil
        }

        let timeoutSeconds: UInt64 = 10

        return await withTaskGroup(of: WatchToken?.self) { group in
            group.addTask {
                do {
                    try await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                } catch {
                    return nil
                }
                if Task.isCancelled {
                    return nil
                }
                print("[TokenManager] iPhone request timed out after \(timeoutSeconds)s")
                return nil
            }

            group.addTask {
                await withCheckedContinuation { continuation in
                    var hasResumed = false
                    let resumeOnce: (WatchToken?) -> Void = { token in
                        guard !hasResumed else { return }
                        hasResumed = true
                        continuation.resume(returning: token)
                    }

                    WCSession.default.sendMessage(
                        ["action": "requestToken"],
                        replyHandler: { response in
                            if let authDict = response["auth"] as? [String: Any] {
                                do {
                                    let jsonData = try JSONSerialization.data(withJSONObject: authDict)
                                    let decoder = JSONDecoder()
                                    decoder.dateDecodingStrategy = .custom { decoder in
                                        let container = try decoder.singleValueContainer()
                                        let timestamp = try container.decode(Int64.self)
                                        return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
                                    }
                                    let token = try decoder.decode(WatchToken.self, from: jsonData)
                                    print("[TokenManager] Received token from iPhone for recovery")
                                    resumeOnce(token)
                                } catch {
                                    print("[TokenManager] Failed to decode iPhone token: \(error)")
                                    resumeOnce(nil)
                                }
                            } else {
                                print("[TokenManager] iPhone returned no token for recovery")
                                resumeOnce(nil)
                            }
                        },
                        errorHandler: { error in
                            print("[TokenManager] iPhone request failed: \(error)")
                            resumeOnce(nil)
                        }
                    )
                }
            }

            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            return nil
        }
    }
    #endif

    private func refreshTokenInternal(_ token: WatchToken) async throws -> WatchToken {
        let response = try await performTokenRefresh(
            refreshToken: token.refreshToken,
            instituteCode: token.iss
        )
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let tokenVersion = WatchToken.extractIatMillis(from: response.idToken) ?? nowMs

        let newToken = WatchToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            idToken: response.idToken,
            iss: token.iss,
            studentId: token.studentId,
            studentIdNorm: token.studentIdNorm,
            expiryDate: Date().addingTimeInterval(Double(response.expiresIn) - 60),
            tokenVersion: tokenVersion,
            updatedAtMs: nowMs
        )

        try saveToken(newToken, syncToICloud: true)

        #if os(watchOS)
        WatchConnectivityManager.shared.sendTokenToiPhoneInBackground()
        #endif

        return newToken
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
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let tokenVersion = WatchToken.extractIatMillis(from: response.idToken) ?? nowMs

        let newToken = WatchToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            idToken: response.idToken,
            iss: currentToken.iss,
            studentId: currentToken.studentId,
            studentIdNorm: currentToken.studentIdNorm,
            expiryDate: Date().addingTimeInterval(Double(response.expiresIn) - 60),
            tokenVersion: tokenVersion,
            updatedAtMs: nowMs
        )

        try saveToken(newToken, syncToICloud: true)

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
