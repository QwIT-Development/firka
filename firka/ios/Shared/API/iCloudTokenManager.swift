import Foundation

class iCloudTokenManager {
    static let shared = iCloudTokenManager()

    private let iCloudStore = NSUbiquitousKeyValueStore.default

    private let kAccessToken = "firka_access_token"
    private let kRefreshToken = "firka_refresh_token"
    private let kIdToken = "firka_id_token"
    private let kIss = "firka_iss"
    private let kStudentId = "firka_student_id"
    private let kStudentIdNorm = "firka_student_id_norm"
    private let kExpiryDate = "firka_expiry_date"
    private let kTokenVersion = "firka_token_version"
    private let kUpdatedAtMs = "firka_updated_at_ms"
    private let kLastUpdatedDevice = "firka_last_updated_device"
    private let kLastUpdateTimestamp = "firka_last_update_timestamp"

    private var changeObserver: ((WatchToken) -> Void)?
    private var isAvailable = false

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )

        isAvailable = iCloudStore.synchronize()
        if isAvailable {
            print("[iCloud] iCloud KeyValue Store available and synced")
        } else {
            print("[iCloud] iCloud not available (not signed in or disabled) - using local storage only")
        }
    }

    func saveToken(_ token: WatchToken, deviceName: String) {
        guard isAvailable else {
            return
        }

        if let existingToken = loadToken() {
            if existingToken.isSameAccount(as: token) {
                if !token.isNewer(than: existingToken) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss"
                    formatter.timeZone = TimeZone.current
                    print("[iCloud] Ignoring stale token save from \(deviceName), existing expiry: \(formatter.string(from: existingToken.expiryDate)), incoming: \(formatter.string(from: token.expiryDate))")
                    return
                }
            } else {
                let incomingUpdatedAt = token.effectiveUpdatedAtMs ?? 0
                let existingUpdatedAt = existingToken.effectiveUpdatedAtMs ?? 0
                if incomingUpdatedAt > 0 &&
                    existingUpdatedAt > 0 &&
                    incomingUpdatedAt <= existingUpdatedAt {
                    print("[iCloud] Ignoring cross-account stale token save from \(deviceName)")
                    return
                }
            }
        }

        print("[iCloud] Saving token to iCloud from \(deviceName)")

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let updatedAtMs = token.effectiveUpdatedAtMs ?? nowMs
        let tokenVersion = token.effectiveTokenVersion

        iCloudStore.set(token.accessToken, forKey: kAccessToken)
        iCloudStore.set(token.refreshToken, forKey: kRefreshToken)
        iCloudStore.set(token.idToken, forKey: kIdToken)
        iCloudStore.set(token.iss, forKey: kIss)
        iCloudStore.set(token.studentId, forKey: kStudentId)
        iCloudStore.set(token.studentIdNorm, forKey: kStudentIdNorm)
        iCloudStore.set(token.expiryDate.timeIntervalSince1970, forKey: kExpiryDate)
        if let tokenVersion {
            iCloudStore.set(tokenVersion, forKey: kTokenVersion)
        } else {
            iCloudStore.removeObject(forKey: kTokenVersion)
        }
        iCloudStore.set(updatedAtMs, forKey: kUpdatedAtMs)
        iCloudStore.set(deviceName, forKey: kLastUpdatedDevice)
        iCloudStore.set(Double(updatedAtMs) / 1000.0, forKey: kLastUpdateTimestamp)

        let success = iCloudStore.synchronize()
        if success {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            formatter.timeZone = TimeZone.current
            print("[iCloud] Token saved successfully, expiry: \(formatter.string(from: token.expiryDate))")
        } else {
            print("[iCloud] Failed to synchronize token to iCloud")
        }
    }

    func loadToken() -> WatchToken? {
        guard isAvailable else {
            return nil
        }

        iCloudStore.synchronize()

        guard let accessToken = iCloudStore.string(forKey: kAccessToken),
              let refreshToken = iCloudStore.string(forKey: kRefreshToken),
              let idToken = iCloudStore.string(forKey: kIdToken),
              let iss = iCloudStore.string(forKey: kIss),
              let studentId = iCloudStore.string(forKey: kStudentId) else {
            print("[iCloud] No token found in iCloud")
            return nil
        }

        let studentIdNorm = iCloudStore.longLong(forKey: kStudentIdNorm)
        let expiryTimestamp = iCloudStore.double(forKey: kExpiryDate)
        let tokenVersionRaw = iCloudStore.longLong(forKey: kTokenVersion)
        let updatedAtMsRaw = iCloudStore.longLong(forKey: kUpdatedAtMs)
        let fallbackUpdatedAt = Int64(iCloudStore.double(forKey: kLastUpdateTimestamp) * 1000.0)
        let lastDevice = iCloudStore.string(forKey: kLastUpdatedDevice) ?? "unknown"

        guard expiryTimestamp > 0 else {
            print("[iCloud] Invalid expiry date in iCloud")
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
            updatedAtMs: updatedAtMsRaw > 0 ? updatedAtMsRaw : (fallbackUpdatedAt > 0 ? fallbackUpdatedAt : nil)
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        print("[iCloud] Token loaded from iCloud (last updated by: \(lastDevice)), expiry: \(formatter.string(from: expiryDate))")

        return token
    }

    func deleteToken() {
        guard isAvailable else {
            return
        }

        print("[iCloud] Deleting token from iCloud")

        iCloudStore.removeObject(forKey: kAccessToken)
        iCloudStore.removeObject(forKey: kRefreshToken)
        iCloudStore.removeObject(forKey: kIdToken)
        iCloudStore.removeObject(forKey: kIss)
        iCloudStore.removeObject(forKey: kStudentId)
        iCloudStore.removeObject(forKey: kStudentIdNorm)
        iCloudStore.removeObject(forKey: kExpiryDate)
        iCloudStore.removeObject(forKey: kTokenVersion)
        iCloudStore.removeObject(forKey: kUpdatedAtMs)
        iCloudStore.removeObject(forKey: kLastUpdatedDevice)
        iCloudStore.removeObject(forKey: kLastUpdateTimestamp)

        iCloudStore.synchronize()
    }

    func observeChanges(_ observer: @escaping (WatchToken) -> Void) {
        self.changeObserver = observer
    }

    @objc private func iCloudStoreDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        if changeReason == NSUbiquitousKeyValueStoreServerChange ||
           changeReason == NSUbiquitousKeyValueStoreInitialSyncChange {

            print("[iCloud] Token changed externally in iCloud")

            if let token = loadToken() {
                let lastDevice = iCloudStore.string(forKey: kLastUpdatedDevice) ?? "unknown"
                print("[iCloud] Received updated token from: \(lastDevice)")
                changeObserver?(token)
            }
        }
    }

    func getLastUpdatedDevice() -> String? {
        guard isAvailable else {
            return nil
        }
        iCloudStore.synchronize()
        return iCloudStore.string(forKey: kLastUpdatedDevice)
    }

    func getLastUpdateTimestamp() -> Date? {
        guard isAvailable else {
            return nil
        }
        iCloudStore.synchronize()
        let timestamp = iCloudStore.double(forKey: kLastUpdateTimestamp)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
}
