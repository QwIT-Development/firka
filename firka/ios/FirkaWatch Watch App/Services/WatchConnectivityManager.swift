import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
    }

    func activate() {
        print("[Watch] WatchConnectivityManager.activate() called")
        if WCSession.isSupported() {
            print("[Watch] WCSession is supported, activating...")
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            print("[Watch] WCSession is NOT supported!")
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print("[Watch] Session activation completed with state: \(activationState.rawValue)")
        if let error = error {
            print("[Watch] Activation error: \(error.localizedDescription)")
        }
        DispatchQueue.main.async {
            if activationState == .activated {
                let context = session.receivedApplicationContext
                if !context.isEmpty {
                    self.processApplicationContext(context)
                }
            }
        }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        print("[Watch] didReceiveApplicationContext called")
        DispatchQueue.main.async {
            self.processApplicationContext(applicationContext)
        }
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        print("[Watch] didReceiveUserInfo called")
        DispatchQueue.main.async {
            self.processUserInfo(userInfo)
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        print("[Watch] didReceiveMessage called: \(message)")

        guard let action = message["action"] as? String else {
            replyHandler(["error": "no_action"])
            return
        }

        switch action {
        case "getToken":
            handleGetTokenRequest(replyHandler: replyHandler)
        default:
            replyHandler(["error": "unknown_action"])
        }
    }

    private func handleGetTokenRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        guard TokenManager.shared.loadToken() != nil else {
            print("[Watch] No token to send to iPhone")
            replyHandler(["error": "no_token"])
            return
        }

        if TokenManager.shared.isTokenExpired() {
            print("[Watch] Token expired, attempting refresh before sending to iPhone...")
            Task {
                do {
                    let freshToken = try await KretaAPIClient.shared.getValidToken()
                    print("[Watch] Token refresh succeeded, sending fresh token to iPhone")

                    let tokenData: [String: Any] = [
                        "studentId": freshToken.studentId,
                        "studentIdNorm": freshToken.studentIdNorm,
                        "iss": freshToken.iss,
                        "idToken": freshToken.idToken,
                        "accessToken": freshToken.accessToken,
                        "refreshToken": freshToken.refreshToken,
                        "expiryDate": Int64(freshToken.expiryDate.timeIntervalSince1970 * 1000)
                    ]

                    replyHandler(["token": tokenData])
                } catch {
                    print("[Watch] Token refresh failed after all retries: \(error)")
                    replyHandler(["error": "refresh_failed"])
                }
            }
            return
        }

        guard let token = TokenManager.shared.loadToken() else {
            replyHandler(["error": "no_token"])
            return
        }

        let tokenData: [String: Any] = [
            "studentId": token.studentId,
            "studentIdNorm": token.studentIdNorm,
            "iss": token.iss,
            "idToken": token.idToken,
            "accessToken": token.accessToken,
            "refreshToken": token.refreshToken,
            "expiryDate": Int64(token.expiryDate.timeIntervalSince1970 * 1000)
        ]

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        print("[Watch] Sending token to iPhone, expiry: \(formatter.string(from: token.expiryDate))")
        replyHandler(["token": tokenData])
    }

    func requestTokenFromPhone() {
        guard WCSession.default.activationState == .activated else {
            print("[Watch] Cannot request token: session not activated")
            return
        }

        guard WCSession.default.isReachable else {
            print("[Watch] Cannot request token: iPhone not reachable")
            return
        }

        print("[Watch] Requesting token from iPhone...")

        WCSession.default.sendMessage(
            ["action": "requestToken"],
            replyHandler: { response in
                print("[Watch] Received response from iPhone")
                DispatchQueue.main.async {
                    if let authDict = response["auth"] as? [String: Any] {
                        print("[Watch] Token received from iPhone")
                        self.processAuthData(authDict)
                    } else if let error = response["error"] as? String {
                        print("[Watch] Token request error: \(error)")
                    }
                }
            },
            errorHandler: { error in
                print("[Watch] Token request failed: \(error.localizedDescription)")
            }
        )
    }

    private func processApplicationContext(_ context: [String: Any]) {
        if let authDict = context["auth"] as? [String: Any] {
            print("[Watch] Received auth from iPhone")
            processAuthData(authDict)
        }

        if let language = context["language"] as? String {
            print("[Watch] Received language from iPhone: \(language)")
            WatchL10n.shared.updateFromiPhone(languageCode: language)
        }
    }

    private func processUserInfo(_ userInfo: [String: Any]) {
        if let messageId = userInfo["id"] as? String {
            switch messageId {
            case "token_update":
                if let authDict = userInfo["auth"] as? [String: Any] {
                    print("[Watch] Received token_update via userInfo")
                    processAuthData(authDict)
                }
            case "language_update":
                if let language = userInfo["language"] as? String {
                    print("[Watch] Received language_update via userInfo: \(language)")
                    WatchL10n.shared.updateFromiPhone(languageCode: language)
                }
            case "reauth_required":
                print("[Watch] Received reauth_required notification from iPhone")
                DataStore.shared.setReauthRequired()
            default:
                break
            }
        }
    }

    func sendTokenToiPhoneInBackground() {
        guard WCSession.default.activationState == .activated else {
            print("[Watch] Cannot send token: session not activated")
            return
        }

        guard let token = TokenManager.shared.loadToken() else {
            print("[Watch] No token to send to iPhone")
            return
        }

        let tokenData: [String: Any] = [
            "studentId": token.studentId,
            "studentIdNorm": token.studentIdNorm,
            "iss": token.iss,
            "idToken": token.idToken,
            "accessToken": token.accessToken,
            "refreshToken": token.refreshToken,
            "expiryDate": Int64(token.expiryDate.timeIntervalSince1970 * 1000)
        ]

        do {
            try WCSession.default.updateApplicationContext(["auth": tokenData])
            print("[Watch] Token sent via applicationContext")
        } catch {
            print("[Watch] Failed to update applicationContext: \(error)")
        }

        WCSession.default.transferUserInfo([
            "id": "token_update_from_watch",
            "auth": tokenData
        ])

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        print("[Watch] Token sent to iPhone (background), expiry: \(formatter.string(from: token.expiryDate))")
    }

    func requestLanguageFromPhone() {
        guard WCSession.default.activationState == .activated else {
            print("[Watch] Cannot request language: session not activated")
            return
        }

        guard WCSession.default.isReachable else {
            print("[Watch] Cannot request language: iPhone not reachable")
            return
        }

        print("[Watch] Requesting language from iPhone...")

        WCSession.default.sendMessage(
            ["action": "requestLanguage"],
            replyHandler: { response in
                print("[Watch] Received language response from iPhone")
                DispatchQueue.main.async {
                    if let language = response["language"] as? String {
                        print("[Watch] Language received from iPhone: \(language)")
                        WatchL10n.shared.updateFromiPhone(languageCode: language)
                    }
                }
            },
            errorHandler: { error in
                print("[Watch] Language request failed: \(error.localizedDescription)")
            }
        )
    }

    private func processAuthData(_ authDict: [String: Any]) {
        print("[Watch] processAuthData called")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: authDict)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let timestamp = try container.decode(Int64.self)
                return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
            }

            let token = try decoder.decode(WatchToken.self, from: jsonData)
            print("[Watch] Token decoded, saving...")

            try TokenManager.shared.saveToken(token)
            print("[Watch] Token saved successfully")

            DataStore.shared.checkTokenState()

            Task {
                await DataStore.shared.refreshAll()
                print("[Watch] Data refresh completed")
            }
        } catch {
            print("[Watch] Failed to process auth data: \(error)")
        }
    }
}
