import SwiftUI
import WatchConnectivity

struct ContentView: View {
    var dataStore = DataStore.shared
    @State private var selectedTab = 0
    @State private var isRequestingToken = false

    var body: some View {
        Group {
            if dataStore.isRecoveringToken {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("recovering_token".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            else if dataStore.needsReauth && dataStore.hasToken {
                ReauthRequiredView(onTokenReceived: {
                    dataStore.resetRecoveryState()
                    dataStore.checkTokenState()
                    Task {
                        await dataStore.refreshAll()
                    }
                })
            } else if !dataStore.hasToken && dataStore.data == nil {
                if isRequestingToken {
                    ProgressView("connecting".localized)
                } else {
                    PairingView(onRequestToken: requestToken)
                }
            } else {
                mainContent
            }
        }
        .task {
            dataStore.checkTokenState()
            dataStore.loadFromCache()
            if dataStore.hasToken {
                await dataStore.refreshTokenProactively()

                await dataStore.refreshAll()

                if (dataStore.error == "token_expired" || dataStore.error == "no_token") && !dataStore.recoveryAttempted {
                    let recovered = await dataStore.attemptTokenRecovery()
                    if recovered {
                        await dataStore.refreshAll()
                    }
                }
            } else {
                requestToken()
            }
        }
    }

    private func requestToken() {
        guard !isRequestingToken else { return }
        guard WCSession.default.activationState == .activated else {
            print("[Watch] Cannot request token: session not activated")
            return
        }
        guard WCSession.default.isReachable else {
            print("[Watch] Cannot request token: iPhone not reachable")
            return
        }

        print("[Watch] Requesting token from iPhone...")
        isRequestingToken = true
        WatchConnectivityManager.shared.requestTokenFromPhone()

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.isRequestingToken = false
        }
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            HomeView(dataStore: dataStore)
                .tag(0)

            TimetableView(dataStore: dataStore)
                .tag(1)

            GradesView(dataStore: dataStore)
                .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tag(3)
        }
        .tabViewStyle(.verticalPage)
    }
}

struct PairingView: View {
    var onRequestToken: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.and.arrow.right.inward")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("pair_with_iphone".localized)
                .font(.headline)

            Text("open_firka_on_iphone".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if WCSession.default.isReachable {
                Button("sync_button".localized) {
                    onRequestToken?()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
