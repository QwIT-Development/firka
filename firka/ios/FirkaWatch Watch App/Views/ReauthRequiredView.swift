import SwiftUI
import WatchConnectivity

struct ReauthRequiredView: View {
    @State private var isSyncing = false
    @State private var syncStatus: SyncStatus = .idle
    var onTokenReceived: (() -> Void)?

    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed
        case phoneNotReachable
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: statusIcon)
                    .font(.system(size: 44))
                    .foregroundColor(statusColor)
                    .symbolEffect(.pulse, isActive: syncStatus == .syncing)

                Text("reauth_required".localized)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("reauth_description".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if let statusMessage = statusMessage {
                    Text(statusMessage)
                        .font(.caption2)
                        .foregroundColor(statusMessageColor)
                        .multilineTextAlignment(.center)
                }

                Button(action: syncWithiPhone) {
                    HStack {
                        if syncStatus == .syncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("sync_button".localized)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(syncStatus == .success ? .green : .blue)
                .disabled(syncStatus == .syncing)
            }
            .padding()
        }
    }

    private var statusIcon: String {
        switch syncStatus {
        case .idle:
            return "exclamationmark.arrow.circlepath"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .phoneNotReachable:
            return "iphone.slash"
        }
    }

    private var statusColor: Color {
        switch syncStatus {
        case .idle:
            return .orange
        case .syncing:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        case .phoneNotReachable:
            return .gray
        }
    }

    private var statusMessage: String? {
        switch syncStatus {
        case .idle:
            return nil
        case .syncing:
            return "syncing".localized
        case .success:
            return "sync_success".localized
        case .failed:
            return "sync_failed".localized
        case .phoneNotReachable:
            return "phone_not_reachable".localized
        }
    }

    private var statusMessageColor: Color {
        switch syncStatus {
        case .success:
            return .green
        case .failed, .phoneNotReachable:
            return .red
        default:
            return .secondary
        }
    }

    private func syncWithiPhone() {
        guard WCSession.default.activationState == .activated else {
            syncStatus = .failed
            return
        }

        guard WCSession.default.isReachable else {
            syncStatus = .phoneNotReachable
            return
        }

        syncStatus = .syncing

        WCSession.default.sendMessage(
            ["action": "requestToken"],
            replyHandler: { response in
                DispatchQueue.main.async {
                    if let authDict = response["auth"] as? [String: Any] {
                        print("[Watch] Token received from iPhone via reauth sync")
                        self.processAuthData(authDict)

                        if !TokenManager.shared.isTokenExpired() {
                            self.syncStatus = .success

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.onTokenReceived?()
                            }
                        } else {
                            print("[Watch] Received token is already expired - iPhone needs reauth")
                            self.syncStatus = .failed
                        }
                    } else if let error = response["error"] as? String {
                        print("[Watch] iPhone returned error: \(error)")

                        if error == "needsReauth" || error == "no_token" {
                            self.sendWatchTokenToiPhone()
                        } else {
                            self.syncStatus = .failed
                        }
                    } else {
                        print("[Watch] No token in response - iPhone may need reauth")
                        self.syncStatus = .failed
                    }
                }
            },
            errorHandler: { error in
                DispatchQueue.main.async {
                    print("[Watch] Reauth sync failed: \(error.localizedDescription)")
                    self.syncStatus = .failed
                }
            }
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if self.syncStatus == .syncing {
                self.syncStatus = .failed
            }
        }
    }

    private func sendWatchTokenToiPhone() {
        guard TokenManager.shared.loadToken() != nil else {
            print("[Watch] No token to send to iPhone")
            syncStatus = .failed
            return
        }

        if TokenManager.shared.isTokenExpired() {
            print("[Watch] Watch token is expired - attempting to refresh with retries...")
            Task {
                do {
                    _ = try await KretaAPIClient.shared.getValidToken()
                    print("[Watch] Token refresh succeeded! Now sending to iPhone...")
                    await MainActor.run {
                        self.sendRefreshedTokenToiPhone()
                    }
                } catch {
                    print("[Watch] Token refresh failed after all retries: \(error)")
                    await MainActor.run {
                        self.syncStatus = .failed
                    }
                }
            }
            return
        }

        sendRefreshedTokenToiPhone()
    }

    private func sendRefreshedTokenToiPhone() {
        guard let token = TokenManager.shared.loadToken() else {
            print("[Watch] No token after refresh")
            syncStatus = .failed
            return
        }

        print("[Watch] Sending Watch token to iPhone...")

        let tokenData: [String: Any] = [
            "studentId": token.studentId,
            "studentIdNorm": token.studentIdNorm,
            "iss": token.iss,
            "idToken": token.idToken,
            "accessToken": token.accessToken,
            "refreshToken": token.refreshToken,
            "expiryDate": Int64(token.expiryDate.timeIntervalSince1970 * 1000)
        ]

        WCSession.default.sendMessage(
            ["action": "receiveTokenFromWatch", "token": tokenData],
            replyHandler: { response in
                DispatchQueue.main.async {
                    if let success = response["success"] as? Bool, success {
                        print("[Watch] iPhone accepted our token!")
                        self.syncStatus = .success

                        DataStore.shared.clearError()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.onTokenReceived?()
                        }
                    } else if let error = response["error"] as? String {
                        print("[Watch] iPhone rejected our token: \(error)")
                        self.syncStatus = .failed
                    } else {
                        self.syncStatus = .failed
                    }
                }
            },
            errorHandler: { error in
                DispatchQueue.main.async {
                    print("[Watch] Failed to send token to iPhone: \(error)")
                    self.syncStatus = .failed
                }
            }
        )
    }

    private func processAuthData(_ authDict: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: authDict)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let timestamp = try container.decode(Int64.self)
                return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
            }

            let token = try decoder.decode(WatchToken.self, from: jsonData)
            try TokenManager.shared.saveToken(token)

            DataStore.shared.checkTokenState()
            DataStore.shared.clearError()

            print("[Watch] Token saved via reauth sync")
        } catch {
            print("[Watch] Failed to process auth data: \(error)")
        }
    }
}

#Preview {
    ReauthRequiredView()
}
