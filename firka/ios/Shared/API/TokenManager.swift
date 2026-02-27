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
    private let activeStudentIdNormKey = "firka.active_student_id_norm"
    private let proactiveRefreshLeadTime: TimeInterval = 5 * 60
    private let minimumProactiveRefreshInterval: TimeInterval = 60
    private let iCloudProbeTimeoutNs: UInt64 = 1_500_000_000
    private let refreshRequestTimeout: TimeInterval = 12
    private let refreshResourceTimeout: TimeInterval = 20
    #if os(watchOS)
    private let watchRefreshLeaseTtlMs: Int64 = 180_000
    private let iPhoneRefreshLeaseMaxWaitMs: Int64 = 150_000
    private let refreshLeasePollIntervalMs: Int64 = 250
    #endif

    #if os(iOS)
    private let deviceName = "iPhone"
    #elseif os(watchOS)
    private let deviceName = "Watch"
    #endif
    private let recoveryLock = NSLock()
    private var recoveryInProgress = false
    private var lastProactiveRefreshAttemptAt: Date?
    private(set) var lastRecoveryFailure: TokenError?
    #if os(watchOS)
    private var lastPhoneRecoveryRequestAt: Date?
    #endif

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

    func clearLastRecoveryFailure() {
        lastRecoveryFailure = nil
    }

    #if os(watchOS)
    private func withWatchRefreshLease<T>(
        studentIdNorm: Int64,
        _ operation: () async throws -> T
    ) async throws -> T {
        let waitResult = await RefreshLeaseManager.shared.waitForPeerLeaseRelease(
            owner: .watch,
            studentIdNorm: studentIdNorm,
            maxWaitMs: iPhoneRefreshLeaseMaxWaitMs,
            pollIntervalMs: refreshLeasePollIntervalMs
        )

        guard waitResult.ready else {
            print("[TokenManager] Watch refresh lease wait timed out (waited \(waitResult.waitedMs)ms, changed: \(waitResult.leaseChanged))")
            throw TokenError.networkError
        }

        let lease = RefreshLeaseManager.shared.acquireLease(
            owner: .watch,
            studentIdNorm: studentIdNorm,
            ttlMs: watchRefreshLeaseTtlMs
        )

        defer {
            RefreshLeaseManager.shared.releaseLease(
                owner: .watch,
                studentIdNorm: studentIdNorm,
                operationId: lease.operationId
            )
        }

        return try await operation()
    }
    #endif

    private func getActiveStudentIdNorm() -> Int64? {
        if let value = UserDefaults.standard.object(forKey: activeStudentIdNormKey) as? Int64 {
            return value
        }
        if let value = UserDefaults.standard.object(forKey: activeStudentIdNormKey) as? Int {
            return Int64(value)
        }
        if let value = UserDefaults.standard.object(forKey: activeStudentIdNormKey) as? Double {
            return Int64(value)
        }
        if let value = UserDefaults.standard.object(forKey: activeStudentIdNormKey) as? String,
           let parsed = Int64(value) {
            return parsed
        }
        return nil
    }

    private func setActiveStudentIdNorm(_ studentIdNorm: Int64) {
        UserDefaults.standard.set(studentIdNorm, forKey: activeStudentIdNormKey)
    }

    private func localTokenFromKeychainAndFile(preferredStudentIdNorm: Int64? = nil) -> WatchToken? {
        let keychainToken = loadTokenFromKeychain()
        let fileToken = loadTokenFromFile()

        var candidates: [WatchToken] = []
        if let keychainToken { candidates.append(keychainToken) }
        if let fileToken { candidates.append(fileToken) }

        if let preferredStudentIdNorm {
            let filtered = candidates.filter { $0.studentIdNorm == preferredStudentIdNorm }
            if !filtered.isEmpty {
                candidates = filtered
            }
        }

        return candidates.dropFirst().reduce(candidates.first) { best, candidate in
            guard let best else { return candidate }
            return candidate.isNewer(than: best) ? candidate : best
        }
    }

    private func probeSharedKeychainTokenWithTimeout() async -> WatchToken? {
        await withTaskGroup(of: WatchToken?.self) { group in
            group.addTask {
                SharedKeychainManager.shared.loadToken()
            }
            group.addTask { [iCloudProbeTimeoutNs] in
                try? await Task.sleep(nanoseconds: iCloudProbeTimeoutNs)
                return nil
            }

            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    private init() {
        runKVStoreMigrationIfNeeded()
    }

    private let kvStoreMigrationKey = "firka_kv_store_migrated_v1"

    private func runKVStoreMigrationIfNeeded() {
        let alreadyMigrated = UserDefaults.standard.bool(forKey: kvStoreMigrationKey)
        if alreadyMigrated {
            return
        }

        print("[TokenManager] Running KV Store migration...")

        if let migratedToken = SharedKeychainManager.shared.migrateFromKVStoreAndClear() {
            SharedKeychainManager.shared.saveToken(migratedToken)

            try? saveTokenToKeychain(migratedToken)
            try? saveTokenToFile(migratedToken)
            setActiveStudentIdNorm(migratedToken.studentIdNorm)

            print("[TokenManager] KV Store migration completed, token migrated")
        } else {
            SharedKeychainManager.shared.clearKVStore()
            print("[TokenManager] KV Store migration completed, no token to migrate")
        }

        UserDefaults.standard.set(true, forKey: kvStoreMigrationKey)
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

    // MARK: - Load Token (active-account first)
    func loadToken() -> WatchToken? {
        let sharedKeychainToken = SharedKeychainManager.shared.loadToken()
        let keychainToken = loadTokenFromKeychain()
        let fileToken = loadTokenFromFile()

        var candidates: [(token: WatchToken, source: String)] = []
        if let t = sharedKeychainToken { candidates.append((t, "sharedKeychain")) }
        if let t = keychainToken { candidates.append((t, "keychain")) }
        if let t = fileToken { candidates.append((t, "file")) }

        guard !candidates.isEmpty else {
            print("[TokenManager] No token found anywhere")
            return nil
        }

        var preferredStudentIdNorm = getActiveStudentIdNorm()
        var requirePreferredAccount = false
        #if os(watchOS)
        if let sessionState = SharedSessionStateManager.shared.loadState() {
            if !sessionState.hasAnyAccount {
                print("[TokenManager] Shared session state indicates no active accounts, returning no token")
                return nil
            }
            if let sharedActiveStudentIdNorm = sessionState.activeStudentIdNorm {
                preferredStudentIdNorm = sharedActiveStudentIdNorm
                requirePreferredAccount = true
                if getActiveStudentIdNorm() != sharedActiveStudentIdNorm {
                    setActiveStudentIdNorm(sharedActiveStudentIdNorm)
                }
            }
        }
        #endif

        let freshest: (token: WatchToken, source: String)
        if let preferredStudentIdNorm {
            let filtered = candidates.filter { $0.token.studentIdNorm == preferredStudentIdNorm }
            if let preferredFreshest = filtered.dropFirst().reduce(filtered.first) { best, candidate in
                guard let best else { return candidate }
                return candidate.token.isNewer(than: best.token) ? candidate : best
            } {
                freshest = preferredFreshest
            } else {
                if requirePreferredAccount {
                    print("[TokenManager] Active shared-session account token (\(preferredStudentIdNorm)) not found yet, falling back to best available token")
                    #if os(watchOS)
                    if WCSession.default.activationState == .activated && WCSession.default.isReachable {
                        print("[TokenManager] iPhone reachable, requesting active account token")
                        WatchConnectivityManager.shared.requestTokenFromPhone()
                    }
                    #endif
                }
                freshest = candidates.dropFirst().reduce(candidates[0]) { currentBest, candidate in
                    candidate.token.isNewer(than: currentBest.token) ? candidate : currentBest
                }
            }
        } else {
            freshest = candidates.dropFirst().reduce(candidates[0]) { currentBest, candidate in
                candidate.token.isNewer(than: currentBest.token) ? candidate : currentBest
            }
        }
        let previousActiveStudentIdNorm = getActiveStudentIdNorm()
        setActiveStudentIdNorm(freshest.token.studentIdNorm)

        #if os(iOS)
        if previousActiveStudentIdNorm != freshest.token.studentIdNorm {
            _ = SharedSessionStateManager.shared.publishState(
                hasAnyAccount: true,
                activeStudentIdNorm: freshest.token.studentIdNorm
            )
            print("[TokenManager] Active account changed from \(previousActiveStudentIdNorm ?? 0) to \(freshest.token.studentIdNorm), published to SharedSessionState")
        }
        #endif

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current

        print("[TokenManager] Token sources found: \(candidates.map { "\($0.source): \($0.token.studentIdNorm) @ \(formatter.string(from: $0.token.expiryDate))" }.joined(separator: ", "))")
        print("[TokenManager] Using selected token from \(freshest.source) (expiry: \(formatter.string(from: freshest.token.expiryDate)))")

        if keychainToken == nil ||
            keychainToken!.studentIdNorm != freshest.token.studentIdNorm ||
            freshest.token.isNewer(than: keychainToken!) {
            print("[TokenManager] Syncing fresher token to keychain")
            try? saveTokenToKeychain(freshest.token)
        }
        if fileToken == nil ||
            fileToken!.studentIdNorm != freshest.token.studentIdNorm ||
            freshest.token.isNewer(than: fileToken!) {
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

        SharedSessionStateManager.shared.publishState(hasAnyAccount: false, activeStudentIdNorm: nil)

        if let previousToken = loadToken() {
            RefreshLeaseManager.shared.clearLeases(studentIdNorm: previousToken.studentIdNorm)
        } else {
            RefreshLeaseManager.shared.clearAllLeases()
        }
        deleteTokenFromKeychain()
        SharedKeychainManager.shared.deleteToken()
        UserDefaults.standard.removeObject(forKey: activeStudentIdNormKey)

        guard let filePath = getTokenFilePath() else { return }
        try? FileManager.default.removeItem(at: filePath)
    }

    // MARK: - Save Token
    func saveToken(
        _ token: WatchToken,
        syncToSharedKeychain: Bool = false,
        forceAccountSwitch: Bool = false
    ) throws {
        let currentToken = loadToken()
        if let currentToken {
            if forceAccountSwitch && !token.isSameAccount(as: currentToken) {
                print("[TokenManager] Forcing token save for explicit account switch (\(currentToken.studentIdNorm) -> \(token.studentIdNorm))")
            } else if !token.isNewer(than: currentToken) {
                print("[TokenManager] Ignoring stale or same token save attempt")
                return
            }
        }

        if forceAccountSwitch,
           let currentToken,
           !token.isSameAccount(as: currentToken) {
            RefreshLeaseManager.shared.clearLeases(studentIdNorm: currentToken.studentIdNorm)
        }

        print("[TokenManager] Saving token locally (Keychain + file)")
        setActiveStudentIdNorm(token.studentIdNorm)

        try saveTokenToKeychain(token)

        if syncToSharedKeychain {
            SharedKeychainManager.shared.saveToken(token, forceAccountSwitch: forceAccountSwitch)
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

        let proactiveThreshold = token.expiryDate.addingTimeInterval(-proactiveRefreshLeadTime)
        return Date() >= proactiveThreshold
    }

    func refreshTokenProactively() async {
        guard loadToken() != nil else {
            print("[TokenManager] No token available for proactive refresh")
            return
        }

        guard shouldRefreshProactively() else {
            print("[TokenManager] Token is not close to expiry, no proactive refresh needed")
            return
        }

        let now = Date()
        if let lastAttempt = lastProactiveRefreshAttemptAt,
           now.timeIntervalSince(lastAttempt) < minimumProactiveRefreshInterval {
            print("[TokenManager] Proactive refresh skipped due to cooldown")
            return
        }
        lastProactiveRefreshAttemptAt = now

        print("[TokenManager] Proactively refreshing token...")
        do {
            guard let token = loadToken() else {
                print("[TokenManager] Token disappeared before proactive refresh")
                return
            }
            _ = try await refreshTokenInternal(token)
            clearLastRecoveryFailure()
            print("[TokenManager] Proactive token refresh succeeded")
        } catch {
            if let tokenError = error as? TokenError {
                lastRecoveryFailure = tokenError
            } else {
                lastRecoveryFailure = .networkError
            }
            print("[TokenManager] Proactive token refresh failed: \(error)")
        }
    }

    // MARK: - Central Token Recovery
    func recoverToken() async -> WatchToken? {
        clearLastRecoveryFailure()

        if let validToken = loadToken(), !isTokenExpired() {
            print("[TokenManager] Existing token is valid, skipping recovery flow")
            clearLastRecoveryFailure()
            return validToken
        }

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

        if let sharedToken = await probeSharedKeychainTokenWithTimeout() {
            let now = Date()
            if let preferredStudentIdNorm = getActiveStudentIdNorm(),
               sharedToken.studentIdNorm != preferredStudentIdNorm,
               localTokenFromKeychainAndFile(preferredStudentIdNorm: preferredStudentIdNorm) != nil {
                print("[TokenManager] Shared Keychain probe token belongs to inactive account, skipping direct apply")
            } else if sharedToken.expiryDate > now.addingTimeInterval(60) {
                print("[TokenManager] Shared Keychain probe found valid token, applying without recovery")
                do {
                    try saveToken(sharedToken, syncToSharedKeychain: false)
                    clearLastRecoveryFailure()
                    return sharedToken
                } catch {
                    print("[TokenManager] Failed to apply shared Keychain probe token: \(error)")
                }
            } else {
                print("[TokenManager] Shared Keychain probe token exists but access is expired, continuing with refresh path")
            }
        } else {
            print("[TokenManager] Shared Keychain probe timed out or no token available, continuing with refresh path")
        }

        print("[TokenManager] Step 1: Trying local token refresh...")
        if let token = loadToken() {
            if token.expiryDate > Date().addingTimeInterval(60) {
                print("[TokenManager] Step 1 SUCCESS: Local token already valid")
                clearLastRecoveryFailure()
                return token
            }
            do {
                let refreshedToken = try await refreshTokenInternal(token)
                print("[TokenManager] Step 1 SUCCESS: Local refresh succeeded")
                clearLastRecoveryFailure()
                return refreshedToken
            } catch {
                print("[TokenManager] Step 1 FAILED: Local refresh failed: \(error)")
                if let tokenError = error as? TokenError {
                    lastRecoveryFailure = tokenError
                    if tokenError == .networkError {
                        print("[TokenManager] Step 1 detected network error, aborting recovery flow")
                        return nil
                    }
                }
            }
        } else {
            print("[TokenManager] Step 1 SKIPPED: No local token found")
        }

        print("[TokenManager] Step 2: Checking Keychain and WatchConnectivity...")
        if let recoveredToken = await tryRecoverFromKeychainAndWatch() {
            if recoveredToken.expiryDate > Date().addingTimeInterval(60) {
                print("[TokenManager] Step 2 SUCCESS: Keychain/Watch token is already valid")
                try? saveToken(recoveredToken, syncToSharedKeychain: false)
                clearLastRecoveryFailure()
                return recoveredToken
            } else {
                do {
                    let refreshedToken = try await refreshTokenInternal(recoveredToken)
                    print("[TokenManager] Step 2 SUCCESS: Keychain/Watch token refresh succeeded")
                    clearLastRecoveryFailure()
                    return refreshedToken
                } catch {
                    print("[TokenManager] Step 2 FAILED: Keychain/Watch token refresh failed: \(error)")
                    if let tokenError = error as? TokenError {
                        lastRecoveryFailure = tokenError
                        if tokenError == .networkError {
                            print("[TokenManager] Step 2 detected network error, aborting recovery flow")
                            return nil
                        }
                    }
                }
            }
        } else {
            print("[TokenManager] Step 2 SKIPPED: No token from Keychain/Watch")
        }

        print("[TokenManager] Step 3: Trying shared Keychain recovery with retries...")
        let retryDelays: [TimeInterval] = [0, 5, 10, 5, 10]
        var sharedKeychainHasToken = false

        for (attempt, delay) in retryDelays.enumerated() {
            if delay > 0 {
                if !sharedKeychainHasToken && attempt > 0 {
                    print("[TokenManager] Step 3: Skipping retries - shared Keychain has no token")
                    break
                }
                print("[TokenManager] Step 3: Waiting \(Int(delay))s before attempt \(attempt + 1)...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            print("[TokenManager] Step 3: Shared Keychain attempt \(attempt + 1)/\(retryDelays.count)...")

            if let sharedToken = SharedKeychainManager.shared.loadToken() {
                if let preferredStudentIdNorm = getActiveStudentIdNorm(),
                   sharedToken.studentIdNorm != preferredStudentIdNorm {
                    if localTokenFromKeychainAndFile(
                        preferredStudentIdNorm: preferredStudentIdNorm
                    ) != nil {
                        print("[TokenManager] Step 3: Ignoring shared Keychain token for inactive account (\(sharedToken.studentIdNorm)), active is \(preferredStudentIdNorm)")
                        continue
                    }
                    print("[TokenManager] Step 3: Active account token missing locally, considering different-account shared Keychain token")
                }
                sharedKeychainHasToken = true
                if sharedToken.expiryDate > Date() {
                    print("[TokenManager] Step 3 SUCCESS: Found valid shared Keychain token, applying without immediate refresh")
                    try? saveToken(sharedToken, syncToSharedKeychain: false)
                    clearLastRecoveryFailure()
                    return sharedToken
                } else {
                    print("[TokenManager] Step 3: Shared Keychain token is expired, trying refresh anyway...")
                    do {
                        let refreshedToken = try await refreshTokenInternal(sharedToken)
                        print("[TokenManager] Step 3 SUCCESS: Expired shared Keychain token refresh succeeded on attempt \(attempt + 1)")
                        clearLastRecoveryFailure()
                        return refreshedToken
                    } catch {
                        print("[TokenManager] Step 3: Expired shared Keychain token refresh failed on attempt \(attempt + 1): \(error)")
                        if let tokenError = error as? TokenError {
                            lastRecoveryFailure = tokenError
                            if tokenError == .networkError {
                                print("[TokenManager] Step 3 detected network error, aborting retries")
                                return nil
                            }
                        }
                    }
                }
            } else {
                print("[TokenManager] Step 3: No token in shared Keychain on attempt \(attempt + 1)")
                if attempt == 0 {
                    sharedKeychainHasToken = false
                }
            }
        }

        print("[TokenManager] All recovery attempts failed")
        if lastRecoveryFailure == nil {
            lastRecoveryFailure = .noToken
        }
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

        if let preferredStudentIdNorm = getActiveStudentIdNorm() {
            let filtered = candidates.filter { $0.token.studentIdNorm == preferredStudentIdNorm }
            if !filtered.isEmpty {
                candidates = filtered
            } else {
                print("[TokenManager] No recovery candidate for active account \(preferredStudentIdNorm)")
                return nil
            }
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

        let now = Date()
        if let lastPhoneRecoveryRequestAt,
           now.timeIntervalSince(lastPhoneRecoveryRequestAt) < 5 {
            print("[TokenManager] Skipping iPhone recovery request due to cooldown")
            return nil
        }
        lastPhoneRecoveryRequestAt = now

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
        #if os(watchOS)
        return try await withWatchRefreshLease(studentIdNorm: token.studentIdNorm) {
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

            try saveToken(newToken, syncToSharedKeychain: true)
            WatchConnectivityManager.shared.sendTokenToiPhoneInBackground()
            return newToken
        }
        #else
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

        try saveToken(newToken, syncToSharedKeychain: true)
        return newToken
        #endif
    }

    // MARK: - Refresh Token
    func refreshToken() async throws -> WatchToken {
        guard let currentToken = loadToken() else {
            throw TokenError.noToken
        }

        #if os(watchOS)
        return try await withWatchRefreshLease(studentIdNorm: currentToken.studentIdNorm) {
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

            try saveToken(newToken, syncToSharedKeychain: true)
            WatchConnectivityManager.shared.sendTokenToiPhoneInBackground()
            return newToken
        }
        #else
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

        try saveToken(newToken, syncToSharedKeychain: true)
        return newToken
        #endif
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
        request.timeoutInterval = refreshRequestTimeout

        let formParameters: [String: String] = [
            "institute_code": instituteCode,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
            "client_id": clientID
        ]

        request.httpBody = encodeFormData(formParameters).data(using: .utf8)

        do {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = refreshRequestTimeout
            configuration.timeoutIntervalForResource = refreshResourceTimeout
            let session = URLSession(configuration: configuration)
            let (data, response) = try await session.data(for: request)

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
