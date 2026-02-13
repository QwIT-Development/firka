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
