import Foundation
import Security

/// Manages the synced Keychain storage for cross-device token sharing via iCloud Keychain.
class SharedKeychainManager {
    static let shared = SharedKeychainManager()

    private let accessGroupSuffix = "app.firka.shared"
    private lazy var accessGroup: String = resolveAccessGroup()
    private let service = "app.firka.shared.token"
    private let account = "syncedToken"

    #if os(iOS)
    private let deviceName = "iPhone"
    #elseif os(watchOS)
    private let deviceName = "Watch"
    #endif

    private var changeObserver: ((WatchToken) -> Void)?

    private init() {}

    var resolvedAccessGroup: String {
        accessGroup
    }

    private func resolveAccessGroup() -> String {
        let probeService = "\(service).probe"
        let probeAccount = "probe"
        let probeValue = Data("probe".utf8)

        let cleanupQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: probeService,
            kSecAttrAccount as String: probeAccount,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(cleanupQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: probeService,
            kSecAttrAccount as String: probeAccount,
            kSecValueData as String: probeValue,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess || addStatus == errSecDuplicateItem {
            let readQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: probeService,
                kSecAttrAccount as String: probeAccount,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                kSecReturnAttributes as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var result: AnyObject?
            let readStatus = SecItemCopyMatching(readQuery as CFDictionary, &result)
            SecItemDelete(cleanupQuery as CFDictionary)

            if readStatus == errSecSuccess,
               let attributes = result as? [String: Any],
               let resolvedGroup = attributes[kSecAttrAccessGroup as String] as? String,
               !resolvedGroup.isEmpty {
                print("[SharedKeychain] Resolved access group: \(resolvedGroup)")
                return resolvedGroup
            }
        }

        print("[SharedKeychain] Failed to resolve access group dynamically, using suffix fallback")
        return accessGroupSuffix
    }

    // MARK: - Save Token (Synced)
    @discardableResult
    func saveToken(_ token: WatchToken, forceAccountSwitch: Bool = false) -> Bool {
        if let existingToken = loadToken() {
            if existingToken.isSameAccount(as: token) {
                if !token.isNewer(than: existingToken) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss"
                    formatter.timeZone = TimeZone.current
                    print("[SharedKeychain] Ignoring stale token save from \(deviceName), existing expiry: \(formatter.string(from: existingToken.expiryDate)), incoming: \(formatter.string(from: token.expiryDate))")
                    return false
                }
            } else {
                if !forceAccountSwitch {
                    let incomingUpdatedAt = token.effectiveUpdatedAtMs ?? 0
                    let existingUpdatedAt = existingToken.effectiveUpdatedAtMs ?? 0
                    if incomingUpdatedAt > 0 &&
                        existingUpdatedAt > 0 &&
                        incomingUpdatedAt <= existingUpdatedAt {
                        print("[SharedKeychain] Ignoring cross-account stale token save from \(deviceName)")
                        return false
                    }
                }
            }
        }

        print("[SharedKeychain] Saving token to synced Keychain from \(deviceName)")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(token)

            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: accessGroup,
                kSecAttrSynchronizable as String: kCFBooleanTrue!
            ]
            SecItemDelete(deleteQuery as CFDictionary)

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: accessGroup,
                kSecAttrSynchronizable as String: kCFBooleanTrue!,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]

            let status = SecItemAdd(addQuery as CFDictionary, nil)

            if status == errSecSuccess {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                formatter.timeZone = TimeZone.current
                print("[SharedKeychain] Token saved successfully to synced Keychain, expiry: \(formatter.string(from: token.expiryDate))")
                return true
            } else {
                print("[SharedKeychain] Failed to save token to synced Keychain: \(status)")
                return false
            }
        } catch {
            print("[SharedKeychain] Failed to encode token: \(error)")
            return false
        }
    }

    // MARK: - Load Token (Synced)
    func loadToken() -> WatchToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                print("[SharedKeychain] Failed to load token from synced Keychain: \(status)")
            }
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let token = try decoder.decode(WatchToken.self, from: data)

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            formatter.timeZone = TimeZone.current
            print("[SharedKeychain] Token loaded from synced Keychain, expiry: \(formatter.string(from: token.expiryDate))")

            return token
        } catch {
            print("[SharedKeychain] Failed to decode token from synced Keychain: \(error)")
            return nil
        }
    }

    // MARK: - Delete Token (Synced)
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kCFBooleanTrue!
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            print("[SharedKeychain] Token deleted from synced Keychain")
        } else {
            print("[SharedKeychain] Failed to delete token from synced Keychain: \(status)")
        }
    }

    // MARK: - Observer (for compatibility with old iCloudTokenManager interface)
    func observeChanges(_ observer: @escaping (WatchToken) -> Void) {
        self.changeObserver = observer
    }

    func notifyObservers(with token: WatchToken) {
        changeObserver?(token)
    }

    // MARK: - Migration from KV Store
    func migrateFromKVStoreAndClear() -> WatchToken? {
        let iCloudStore = NSUbiquitousKeyValueStore.default

        iCloudStore.synchronize()

        guard let accessToken = iCloudStore.string(forKey: "firka_access_token"),
              let refreshToken = iCloudStore.string(forKey: "firka_refresh_token"),
              let idToken = iCloudStore.string(forKey: "firka_id_token"),
              let iss = iCloudStore.string(forKey: "firka_iss"),
              let studentId = iCloudStore.string(forKey: "firka_student_id") else {
            print("[SharedKeychain] No token found in KV Store to migrate")
            clearKVStore()
            return nil
        }

        let studentIdNorm = iCloudStore.longLong(forKey: "firka_student_id_norm")
        let expiryTimestamp = iCloudStore.double(forKey: "firka_expiry_date")
        let tokenVersionRaw = iCloudStore.longLong(forKey: "firka_token_version")
        let updatedAtMsRaw = iCloudStore.longLong(forKey: "firka_updated_at_ms")

        guard expiryTimestamp > 0 else {
            print("[SharedKeychain] Invalid expiry date in KV Store")
            clearKVStore()
            return nil
        }

        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)

        let token = WatchToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken,
            iss: iss,
            studentId: studentId,
            studentIdNorm: studentIdNorm,
            expiryDate: expiryDate,
            tokenVersion: tokenVersionRaw > 0 ? tokenVersionRaw : nil,
            updatedAtMs: updatedAtMsRaw > 0 ? updatedAtMsRaw : nil
        )

        print("[SharedKeychain] Migrated token from KV Store, expiry: \(expiryDate)")

        clearKVStore()

        return token
    }

    func clearKVStore() {
        let iCloudStore = NSUbiquitousKeyValueStore.default

        let keysToRemove = [
            "firka_access_token",
            "firka_refresh_token",
            "firka_id_token",
            "firka_iss",
            "firka_student_id",
            "firka_student_id_norm",
            "firka_expiry_date",
            "firka_token_version",
            "firka_updated_at_ms",
            "firka_last_updated_device",
            "firka_last_update_timestamp"
        ]

        for key in keysToRemove {
            iCloudStore.removeObject(forKey: key)
        }

        iCloudStore.synchronize()
        print("[SharedKeychain] Cleared old KV Store data")
    }
}

enum RefreshLeaseOwner: String {
    case iphone
    case watch

    var peer: RefreshLeaseOwner {
        switch self {
        case .iphone:
            return .watch
        case .watch:
            return .iphone
        }
    }
}

struct SharedSessionStateRecord: Codable {
    let stateVersion: Int64
    let hasAnyAccount: Bool
    let activeStudentIdNorm: Int64?
    let updatedAtMs: Int64
    let sourceDevice: String
}

struct SharedLanguageStateRecord: Codable {
    let stateVersion: Int64
    let languageCode: String
    let updatedAtMs: Int64
    let expiresAtMs: Int64
    let sourceDevice: String
}

class SharedLanguageStateManager {
    static let shared = SharedLanguageStateManager()

    private let service = "app.firka.shared.language_state"
    private let account = "language_state"
    private let accessGroup: String
    private let maxTtlMs: Int64 = 7 * 24 * 60 * 60 * 1000

    #if os(iOS)
    private let sourceDevice = "iphone"
    #elseif os(watchOS)
    private let sourceDevice = "watch"
    #endif

    private init() {
        accessGroup = SharedKeychainManager.shared.resolvedAccessGroup
    }

    private func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func encode(_ state: SharedLanguageStateRecord) -> Data? {
        try? JSONEncoder().encode(state)
    }

    private func decode(_ data: Data) -> SharedLanguageStateRecord? {
        try? JSONDecoder().decode(SharedLanguageStateRecord.self, from: data)
    }

    private func keychainQueryBase() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup
        ]
    }

    private func loadStateFromKeychain() -> SharedLanguageStateRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return decode(data)
    }

    private func storeStateInKeychain(_ state: SharedLanguageStateRecord) {
        guard let data = encode(state) else {
            print("[SharedLanguageState] Failed to encode state for keychain")
            return
        }

        var deleteQuery = keychainQueryBase()
        deleteQuery[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        SecItemDelete(deleteQuery as CFDictionary)

        var addQuery = keychainQueryBase()
        addQuery[kSecAttrSynchronizable as String] = kCFBooleanTrue!
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            print("[SharedLanguageState] Failed to publish state to keychain: \(status)")
        }
    }

    private func clearKeychainState() {
        var query = keychainQueryBase()
        query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        SecItemDelete(query as CFDictionary)
    }

    private func isExpired(_ state: SharedLanguageStateRecord, now: Int64) -> Bool {
        state.expiresAtMs <= now
    }

    func loadState() -> SharedLanguageStateRecord? {
        let now = nowMs()
        guard let keychainState = loadStateFromKeychain() else {
            return nil
        }
        if isExpired(keychainState, now: now) {
            clearKeychainState()
            return nil
        }
        return keychainState
    }

    @discardableResult
    func publishState(
        languageCode: String,
        ttlMs: Int64 = 24 * 60 * 60 * 1000
    ) -> SharedLanguageStateRecord {
        let now = nowMs()
        let previousVersion = loadStateFromKeychain()?.stateVersion ?? 0
        let nextVersion = max(now, previousVersion + 1)
        let effectiveTtl = max(min(ttlMs, maxTtlMs), 60_000)
        let state = SharedLanguageStateRecord(
            stateVersion: nextVersion,
            languageCode: languageCode,
            updatedAtMs: now,
            expiresAtMs: now + effectiveTtl,
            sourceDevice: sourceDevice
        )

        storeStateInKeychain(state)

        return state
    }

    func clearState() {
        clearKeychainState()
    }
}

class SharedSessionStateManager {
    static let shared = SharedSessionStateManager()

    private let service = "app.firka.shared.session_state"
    private let account = "session_state"
    private let accessGroup: String

    #if os(iOS)
    private let sourceDevice = "iphone"
    #elseif os(watchOS)
    private let sourceDevice = "watch"
    #endif

    private init() {
        accessGroup = SharedKeychainManager.shared.resolvedAccessGroup
    }

    private func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func encode(_ state: SharedSessionStateRecord) -> Data? {
        try? JSONEncoder().encode(state)
    }

    private func decode(_ data: Data) -> SharedSessionStateRecord? {
        try? JSONDecoder().decode(SharedSessionStateRecord.self, from: data)
    }

    func loadState() -> SharedSessionStateRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return decode(data)
    }

    @discardableResult
    func publishState(
        hasAnyAccount: Bool,
        activeStudentIdNorm: Int64?
    ) -> SharedSessionStateRecord {
        let now = nowMs()
        let previousVersion = loadState()?.stateVersion ?? 0
        let nextVersion = max(now, previousVersion + 1)
        let state = SharedSessionStateRecord(
            stateVersion: nextVersion,
            hasAnyAccount: hasAnyAccount,
            activeStudentIdNorm: hasAnyAccount ? activeStudentIdNorm : nil,
            updatedAtMs: now,
            sourceDevice: sourceDevice
        )

        if let data = encode(state) {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: accessGroup,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
            ]
            SecItemDelete(deleteQuery as CFDictionary)

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: accessGroup,
                kSecAttrSynchronizable as String: kCFBooleanTrue!,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                kSecValueData as String: data
            ]
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            if status != errSecSuccess {
                print("[SharedSessionState] Failed to publish state: \(status)")
            }
        } else {
            print("[SharedSessionState] Failed to encode state")
        }

        return state
    }

    func clearState() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct RefreshLeaseRecord: Codable {
    let owner: String
    let studentIdNorm: Int64
    let operationId: String
    let startedAtMs: Int64
    let expiresAtMs: Int64
}

struct RefreshLeaseWaitResult {
    let ready: Bool
    let status: String
    let waitedMs: Int64
    let peerOperationId: String?
    let leaseChanged: Bool

    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "ready": ready,
            "status": status,
            "waitedMs": waitedMs,
            "leaseChanged": leaseChanged
        ]
        if let peerOperationId {
            dict["peerOperationId"] = peerOperationId
        }
        return dict
    }
}

class RefreshLeaseManager {
    static let shared = RefreshLeaseManager()

    private let service = "app.firka.shared.refresh_lease"
    private let accountPrefix = "lease"
    private let accessGroup: String

    private init() {
        accessGroup = SharedKeychainManager.shared.resolvedAccessGroup
    }

    private func keyAccount(
        owner: RefreshLeaseOwner,
        studentIdNorm: Int64
    ) -> String {
        "\(accountPrefix)_\(owner.rawValue)_\(studentIdNorm)"
    }

    private func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func encode(_ lease: RefreshLeaseRecord) -> Data? {
        try? JSONEncoder().encode(lease)
    }

    private func decode(_ data: Data) -> RefreshLeaseRecord? {
        try? JSONDecoder().decode(RefreshLeaseRecord.self, from: data)
    }

    func loadLease(
        owner: RefreshLeaseOwner,
        studentIdNorm: Int64
    ) -> RefreshLeaseRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyAccount(owner: owner, studentIdNorm: studentIdNorm),
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return decode(data)
    }

    @discardableResult
    func acquireLease(
        owner: RefreshLeaseOwner,
        studentIdNorm: Int64,
        ttlMs: Int64,
        operationId: String = UUID().uuidString
    ) -> RefreshLeaseRecord {
        let now = nowMs()
        let clampedTtl = max(ttlMs, 5_000)
        let lease = RefreshLeaseRecord(
            owner: owner.rawValue,
            studentIdNorm: studentIdNorm,
            operationId: operationId,
            startedAtMs: now,
            expiresAtMs: now + clampedTtl
        )

        if let data = encode(lease) {
            let account = keyAccount(owner: owner, studentIdNorm: studentIdNorm)
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: accessGroup,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
            ]
            SecItemDelete(deleteQuery as CFDictionary)

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: accessGroup,
                kSecAttrSynchronizable as String: kCFBooleanTrue!,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                kSecValueData as String: data
            ]
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            if status != errSecSuccess {
                print("[RefreshLease] Failed to acquire lease for \(owner.rawValue): \(status)")
            }
        } else {
            print("[RefreshLease] Failed to encode lease for \(owner.rawValue)")
        }

        return lease
    }

    func releaseLease(
        owner: RefreshLeaseOwner,
        studentIdNorm: Int64,
        operationId: String? = nil
    ) {
        if let operationId,
           let current = loadLease(owner: owner, studentIdNorm: studentIdNorm),
           current.operationId != operationId {
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyAccount(owner: owner, studentIdNorm: studentIdNorm),
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(query as CFDictionary)
    }

    func clearLeases(studentIdNorm: Int64) {
        releaseLease(owner: .iphone, studentIdNorm: studentIdNorm, operationId: nil)
        releaseLease(owner: .watch, studentIdNorm: studentIdNorm, operationId: nil)
    }

    func clearAllLeases() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status != errSecSuccess {
            return
        }

        guard let items = result as? [[String: Any]] else {
            return
        }

        for item in items {
            guard let account = item[kSecAttrAccount as String] as? String else {
                continue
            }
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: accessGroup,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
            ]
            SecItemDelete(deleteQuery as CFDictionary)
        }
    }

    func waitForPeerLeaseRelease(
        owner: RefreshLeaseOwner,
        studentIdNorm: Int64,
        maxWaitMs: Int64,
        pollIntervalMs: Int64
    ) async -> RefreshLeaseWaitResult {
        let startedAt = nowMs()
        var deadline = startedAt + max(maxWaitMs, 1_000)
        var lastFingerprint: String?
        var leaseChanged = false

        while nowMs() < deadline {
            let now = nowMs()
            guard let peer = loadLease(owner: owner.peer, studentIdNorm: studentIdNorm) else {
                return RefreshLeaseWaitResult(
                    ready: true,
                    status: leaseChanged ? "peer_lease_changed" : "peer_lease_missing",
                    waitedMs: now - startedAt,
                    peerOperationId: nil,
                    leaseChanged: leaseChanged
                )
            }

            if peer.expiresAtMs <= now {
                releaseLease(
                    owner: owner.peer,
                    studentIdNorm: studentIdNorm,
                    operationId: peer.operationId
                )
                return RefreshLeaseWaitResult(
                    ready: true,
                    status: "peer_lease_expired",
                    waitedMs: now - startedAt,
                    peerOperationId: peer.operationId,
                    leaseChanged: leaseChanged
                )
            }

            let fingerprint = "\(peer.operationId)|\(peer.startedAtMs)|\(peer.expiresAtMs)"
            if let previousFingerprint = lastFingerprint, previousFingerprint != fingerprint {
                leaseChanged = true
                deadline = min(deadline, peer.expiresAtMs + 5_000)
                lastFingerprint = fingerprint
                continue
            }

            lastFingerprint = fingerprint
            deadline = min(deadline, peer.expiresAtMs + 5_000)
            let sleepMs = max(min(pollIntervalMs, 1_000), 50)
            try? await Task.sleep(nanoseconds: UInt64(sleepMs) * 1_000_000)
        }

        let waited = max(nowMs() - startedAt, 0)
        let peerOperation = loadLease(owner: owner.peer, studentIdNorm: studentIdNorm)?.operationId
        return RefreshLeaseWaitResult(
            ready: false,
            status: "timed_out",
            waitedMs: waited,
            peerOperationId: peerOperation,
            leaseChanged: leaseChanged
        )
    }
}
