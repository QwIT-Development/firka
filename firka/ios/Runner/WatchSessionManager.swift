import Foundation
import WatchConnectivity
import Flutter

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    private var flutterChannel: FlutterMethodChannel?
    private var isFlutterWatchSyncReady = false
    private var pendingAuthPayloads: [[String: Any]] = []
    private var pendingICloudRecoveryNotification = false

    override private init() {
        super.init()
    }

    func setup(with messenger: FlutterBinaryMessenger) {
        flutterChannel = FlutterMethodChannel(
            name: "app.firka/watch_sync",
            binaryMessenger: messenger
        )

        flutterChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "sendTokenToWatch":
                self?.handleSendTokenToWatch(arguments: call.arguments, result: result)
            case "sendWidgetDataToWatch":
                self?.handleSendWidgetDataToWatch(arguments: call.arguments, result: result)
            case "sendLanguageToWatch":
                self?.handleSendLanguageToWatch(arguments: call.arguments, result: result)
            case "notifyReauthRequired":
                self?.handleNotifyReauthRequired(result: result)
            case "requestTokenFromWatch":
                self?.handleRequestTokenFromWatch(result: result)
            case "checkiCloudToken":
                self?.handleCheckiCloudToken(result: result)
            case "saveTokeToniCloud":
                self?.handleSaveTokenToiCloud(arguments: call.arguments, result: result)
            case "isWatchAppInstalled":
                self?.handleIsWatchAppInstalled(result: result)
            case "clearICloudToken":
                self?.handleClearICloudToken(result: result)
            case "sendLogoutToWatch":
                self?.handleSendLogoutToWatch(result: result)
            case "watchSyncReady":
                self?.handleWatchSyncReady(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("[WatchSessionManager] WCSession activated")
        } else {
            print("[WatchSessionManager] WCSession not supported on this device")
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTokenRecoveredFromiCloud),
            name: Notification.Name("TokenRecoveredFromiCloud"),
            object: nil
        )
    }

    @objc private func handleTokenRecoveredFromiCloud() {
        print("[WatchSessionManager] Token recovered from iCloud, notifying Flutter to clear reauth flag")
        DispatchQueue.main.async {
            self.notifyTokenRecoveredToFlutter()
        }
    }

    private func parseInt64(_ value: Any?) -> Int64? {
        if let value = value as? Int64 {
            return value
        }
        if let value = value as? Int {
            return Int64(value)
        }
        if let value = value as? Double {
            return Int64(value)
        }
        if let value = value as? String, let parsed = Int64(value) {
            return parsed
        }
        return nil
    }

    private func tokenPayload(from token: WatchToken) -> [String: Any] {
        var tokenData: [String: Any] = [
            "studentId": token.studentId,
            "studentIdNorm": token.studentIdNorm,
            "iss": token.iss,
            "idToken": token.idToken,
            "accessToken": token.accessToken,
            "refreshToken": token.refreshToken,
            "expiryDate": Int64(token.expiryDate.timeIntervalSince1970 * 1000)
        ]
        if let tokenVersion = token.effectiveTokenVersion {
            tokenData["tokenVersion"] = tokenVersion
        }
        if let updatedAtMs = token.effectiveUpdatedAtMs {
            tokenData["updatedAtMs"] = updatedAtMs
        }
        return tokenData
    }

    private func isTokenUsable(_ token: WatchToken, skewSeconds: TimeInterval = 60) -> Bool {
        token.expiryDate > Date().addingTimeInterval(skewSeconds)
    }

    private func fallbackTokenFromiCloud() -> [String: Any]? {
        guard let token = iCloudTokenManager.shared.loadToken() else {
            return nil
        }
        guard isTokenUsable(token, skewSeconds: 0) else {
            print("[WatchSessionManager] iCloud fallback token is expired, skipping fallback")
            return nil
        }
        return tokenPayload(from: token)
    }

    private func sameTokenPayload(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        return parseInt64(lhs["studentIdNorm"]) == parseInt64(rhs["studentIdNorm"]) &&
               parseInt64(lhs["expiryDate"]) == parseInt64(rhs["expiryDate"]) &&
               parseInt64(lhs["tokenVersion"]) == parseInt64(rhs["tokenVersion"]) &&
               parseInt64(lhs["updatedAtMs"]) == parseInt64(rhs["updatedAtMs"]) &&
               (lhs["refreshToken"] as? String) == (rhs["refreshToken"] as? String)
    }

    private func tokenPayloadIsUsable(_ tokenData: [String: Any], skewMs: Int64 = 0) -> Bool {
        guard let expiryMs = parseInt64(tokenData["expiryDate"]) else {
            return false
        }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        return expiryMs > (nowMs + skewMs)
    }

    private func enqueuePendingAuth(_ authData: [String: Any]) {
        if pendingAuthPayloads.contains(where: { sameTokenPayload($0, authData) }) {
            return
        }
        pendingAuthPayloads.append(authData)
        print("[WatchSessionManager] Queued pending token from Watch until Flutter sync is ready")
    }

    private func forwardTokenToFlutter(_ authData: [String: Any]) {
        guard isFlutterWatchSyncReady else {
            enqueuePendingAuth(authData)
            return
        }
        flutterChannel?.invokeMethod("onTokenFromWatch", arguments: authData)
    }

    private func notifyTokenRecoveredToFlutter() {
        guard isFlutterWatchSyncReady else {
            pendingICloudRecoveryNotification = true
            print("[WatchSessionManager] Queued iCloud recovery notification until Flutter sync is ready")
            return
        }
        flutterChannel?.invokeMethod("onTokenRecoveredFromiCloud", arguments: nil)
    }

    private func flushPendingEvents() {
        guard isFlutterWatchSyncReady else {
            return
        }
        if !pendingAuthPayloads.isEmpty {
            print("[WatchSessionManager] Flushing \(pendingAuthPayloads.count) queued token event(s) to Flutter")
        }
        for authData in pendingAuthPayloads {
            flutterChannel?.invokeMethod("onTokenFromWatch", arguments: authData)
        }
        pendingAuthPayloads.removeAll()

        if pendingICloudRecoveryNotification {
            pendingICloudRecoveryNotification = false
            flutterChannel?.invokeMethod("onTokenRecoveredFromiCloud", arguments: nil)
        }
    }

    private func handleWatchSyncReady(result: @escaping FlutterResult) {
        isFlutterWatchSyncReady = true
        print("[WatchSessionManager] Flutter WatchSync marked as ready")
        flushPendingEvents()
        result(nil)
    }

    private func handleSendTokenToWatch(arguments: Any?, result: @escaping FlutterResult) {
        guard let authData = arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a dictionary", details: nil))
            return
        }

        guard WCSession.default.activationState == .activated else {
            result(FlutterError(code: "SESSION_NOT_ACTIVE", message: "WCSession is not activated", details: nil))
            return
        }

        do {
            WCSession.default.transferUserInfo([
                "id": "token_update",
                "auth": authData
            ])
            result(nil)
            print("[WatchSessionManager] Token sent to Watch")
        } catch {
            result(FlutterError(code: "TRANSFER_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func handleSendWidgetDataToWatch(arguments: Any?, result: @escaping FlutterResult) {
        guard let jsonString = arguments as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a JSON string", details: nil))
            return
        }

        guard WCSession.default.activationState == .activated else {
            result(FlutterError(code: "SESSION_NOT_ACTIVE", message: "WCSession is not activated", details: nil))
            return
        }

        do {
            try WCSession.default.updateApplicationContext(["widget_data": jsonString])
            result(nil)
            print("[WatchSessionManager] Widget data sent to Watch")
        } catch {
            result(FlutterError(code: "UPDATE_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func handleSendLanguageToWatch(arguments: Any?, result: @escaping FlutterResult) {
        guard let languageCode = arguments as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Language code must be a string", details: nil))
            return
        }

        guard WCSession.default.activationState == .activated else {
            result(FlutterError(code: "SESSION_NOT_ACTIVE", message: "WCSession is not activated", details: nil))
            return
        }

        WCSession.default.transferUserInfo([
            "id": "language_update",
            "language": languageCode
        ])
        result(nil)
        print("[WatchSessionManager] Language '\(languageCode)' sent to Watch")
    }

    private func handleNotifyReauthRequired(result: @escaping FlutterResult) {
        guard WCSession.default.activationState == .activated else {
            result(FlutterError(code: "SESSION_NOT_ACTIVE", message: "WCSession is not activated", details: nil))
            return
        }

        WCSession.default.transferUserInfo([
            "id": "reauth_required"
        ])
        result(nil)
        print("[WatchSessionManager] Reauth notification sent to Watch")
    }

    private func handleRequestTokenFromWatch(result: @escaping FlutterResult) {
        guard WCSession.default.activationState == .activated else {
            result(["error": "session_not_active"])
            return
        }

        guard WCSession.default.isReachable else {
            result(["error": "watch_not_reachable"])
            return
        }

        print("[WatchSessionManager] Requesting token from Watch...")

        WCSession.default.sendMessage(
            ["action": "getToken"],
            replyHandler: { response in
                if let tokenData = response["token"] as? [String: Any] {
                    print("[WatchSessionManager] Received token from Watch")
                    result(tokenData)
                } else if let error = response["error"] as? String {
                    print("[WatchSessionManager] Watch returned error: \(error)")
                    result(["error": error])
                } else {
                    result(["error": "no_token"])
                }
            },
            errorHandler: { error in
                print("[WatchSessionManager] Failed to request token from Watch: \(error)")
                result(["error": error.localizedDescription])
            }
        )
    }

    private func handleCheckiCloudToken(result: @escaping FlutterResult) {
        print("[WatchSessionManager] Checking iCloud for token...")

        guard let token = iCloudTokenManager.shared.loadToken() else {
            print("[WatchSessionManager] No token in iCloud")
            result(["error": "no_token"])
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        print("[WatchSessionManager] Found iCloud token, expiry: \(formatter.string(from: token.expiryDate))")

        result(tokenPayload(from: token))
    }

    private func handleSaveTokenToiCloud(arguments: Any?, result: @escaping FlutterResult) {
        guard let tokenData = arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a dictionary", details: nil))
            return
        }

        guard let accessToken = tokenData["accessToken"] as? String,
              let refreshToken = tokenData["refreshToken"] as? String,
              let idToken = tokenData["idToken"] as? String,
              let iss = tokenData["iss"] as? String,
              let studentId = tokenData["studentId"] as? String,
              let expiryMs = parseInt64(tokenData["expiryDate"]) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required token fields", details: nil))
            return
        }

        let studentIdNorm = parseInt64(tokenData["studentIdNorm"]) ?? 0
        let expiryDate = Date(timeIntervalSince1970: Double(expiryMs) / 1000.0)
        let tokenVersion = parseInt64(tokenData["tokenVersion"]) ?? WatchToken.extractIatMillis(from: idToken)
        let updatedAtMs = parseInt64(tokenData["updatedAtMs"]) ?? Int64(Date().timeIntervalSince1970 * 1000)

        let token = WatchToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken,
            iss: iss,
            studentId: studentId,
            studentIdNorm: studentIdNorm,
            expiryDate: expiryDate,
            tokenVersion: tokenVersion,
            updatedAtMs: updatedAtMs
        )

        iCloudTokenManager.shared.saveToken(token, deviceName: "iPhone")

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        print("[WatchSessionManager] Token saved to iCloud, expiry: \(formatter.string(from: expiryDate))")

        result(nil)
    }

    private func handleIsWatchAppInstalled(result: @escaping FlutterResult) {
        guard WCSession.isSupported() else {
            result(false)
            return
        }

        let session = WCSession.default
        let installed = session.isPaired && session.isWatchAppInstalled
        result(installed)
    }

    private func handleClearICloudToken(result: @escaping FlutterResult) {
        iCloudTokenManager.shared.deleteToken()
        result(nil)
    }

    private func handleSendLogoutToWatch(result: @escaping FlutterResult) {
        guard WCSession.default.activationState == .activated else {
            result(nil)
            return
        }

        guard WCSession.default.isWatchAppInstalled else {
            result(nil)
            return
        }

        do {
            try WCSession.default.updateApplicationContext(["force_logout": true])
        } catch {
            print("[WatchSessionManager] Failed to update applicationContext for logout: \(error)")
        }

        WCSession.default.transferUserInfo([
            "id": "force_logout"
        ])
        print("[WatchSessionManager] Force logout sent to Watch")
        result(nil)
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error = error {
                print("[WatchSessionManager] Activation error: \(error.localizedDescription)")
            } else {
                print("[WatchSessionManager] Session activated with state: \(activationState.rawValue)")

                if activationState == .activated {
                    let context = session.receivedApplicationContext
                    if let authData = context["auth"] as? [String: Any] {
                        print("[WatchSessionManager] Found pending auth in applicationContext")
                        self.forwardTokenToFlutter(authData)
                    }
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("[WatchSessionManager] Received applicationContext from Watch")
        DispatchQueue.main.async {
            if let authData = applicationContext["auth"] as? [String: Any] {
                print("[WatchSessionManager] Processing auth from applicationContext")
                self.forwardTokenToFlutter(authData)
            }
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        print("[WatchSessionManager] Received message from Watch: \(message)")

        guard let action = message["action"] as? String else {
            replyHandler(["error": "No action specified"])
            return
        }

        switch action {
        case "requestToken":
            if !self.isFlutterWatchSyncReady {
                if let tokenData = self.fallbackTokenFromiCloud() {
                    print("[WatchSessionManager] Flutter not ready, returning iCloud token to Watch")
                    replyHandler(["auth": tokenData])
                } else {
                    print("[WatchSessionManager] Flutter not ready and no iCloud token available")
                    replyHandler(["error": "no_token"])
                }
                return
            }
            DispatchQueue.main.async {
                self.flutterChannel?.invokeMethod("getTokenForWatch", arguments: nil) { result in
                    if let tokenData = result as? [String: Any] {
                        if let error = tokenData["error"] as? String {
                            if error == "needsReauth" {
                                print("[WatchSessionManager] Flutter reported needsReauth, not using iCloud fallback")
                                replyHandler(["error": error])
                            } else if let fallbackToken = self.fallbackTokenFromiCloud() {
                                print("[WatchSessionManager] Flutter returned error (\(error)), falling back to iCloud token")
                                replyHandler(["auth": fallbackToken])
                            } else {
                                print("[WatchSessionManager] Flutter returned error: \(error)")
                                replyHandler(["error": error])
                            }
                        } else {
                            guard self.tokenPayloadIsUsable(tokenData) else {
                                print("[WatchSessionManager] Flutter token is expired, refusing to send to Watch")
                                replyHandler(["error": "needsReauth"])
                                return
                            }
                            print("[WatchSessionManager] Sending token to Watch")
                            replyHandler(["auth": tokenData])
                        }
                    } else {
                        if let fallbackToken = self.fallbackTokenFromiCloud() {
                            print("[WatchSessionManager] No Flutter token available, falling back to iCloud token")
                            replyHandler(["auth": fallbackToken])
                        } else {
                            print("[WatchSessionManager] No token available from Flutter")
                            replyHandler(["error": "no_token"])
                        }
                    }
                }
            }

        case "requestLanguage":
            DispatchQueue.main.async {
                self.flutterChannel?.invokeMethod("getLanguageForWatch", arguments: nil) { result in
                    if let languageCode = result as? String {
                        print("[WatchSessionManager] Sending language to Watch: \(languageCode)")
                        replyHandler(["language": languageCode])
                    } else {
                        print("[WatchSessionManager] No language from Flutter, defaulting to hu")
                        replyHandler(["language": "hu"])
                    }
                }
            }

        case "receiveTokenFromWatch":
            guard let tokenData = message["token"] as? [String: Any] else {
                replyHandler(["error": "no_token_data"])
                return
            }

            if !self.isFlutterWatchSyncReady {
                print("[WatchSessionManager] Flutter not ready, queueing token from Watch")
                DispatchQueue.main.async {
                    self.enqueuePendingAuth(tokenData)
                }
                replyHandler(["success": true])
                return
            }

            print("[WatchSessionManager] Receiving token from Watch")
            DispatchQueue.main.async {
                self.flutterChannel?.invokeMethod("onTokenFromWatch", arguments: tokenData) { result in
                    if let success = result as? Bool, success {
                        print("[WatchSessionManager] Flutter accepted Watch token")
                        replyHandler(["success": true])
                    } else if let resultDict = result as? [String: Any],
                              let success = resultDict["success"] as? Bool, success {
                        print("[WatchSessionManager] Flutter accepted Watch token")
                        replyHandler(["success": true])
                    } else {
                        print("[WatchSessionManager] Flutter rejected Watch token")
                        replyHandler(["error": "rejected"])
                    }
                }
            }

        default:
            replyHandler(["error": "Unknown action: \(action)"])
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[WatchSessionManager] Session did become inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("[WatchSessionManager] Session did deactivate, reactivating...")
        if WCSession.isSupported() {
            WCSession.default.activate()
        }
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String : Any] = [:]
    ) {
        DispatchQueue.main.async {
            guard let messageId = userInfo["id"] as? String else {
                return
            }

            if messageId == "token_update_from_watch" {
                if let authData = userInfo["auth"] as? [String: Any] {
                    self.forwardTokenToFlutter(authData)
                    print("[WatchSessionManager] Token received from Watch")
                }
            }
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            if session.isWatchAppInstalled {
                self.flutterChannel?.invokeMethod("watchAppInstalled", arguments: nil)
                print("[WatchSessionManager] Watch app installed detected")
            } else {
                print("[WatchSessionManager] Watch app not installed")
            }
        }
    }
}
