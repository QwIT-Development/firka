import SwiftUI

struct SettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval: Int = 15
    @State private var l10n = WatchL10n.shared

    var body: some View {
        List {
            Section("language".localized) {
                Toggle("sync_with_iphone".localized, isOn: Binding(
                    get: { l10n.syncWithiPhone },
                    set: { l10n.syncWithiPhone = $0 }
                ))

                if !l10n.syncWithiPhone {
                    Picker("language".localized, selection: Binding(
                        get: { l10n.currentLanguage },
                        set: { l10n.setLanguage($0) }
                    )) {
                        ForEach(WatchLanguage.allCases, id: \.self) { lang in
                            HStack {
                                Text(lang.flag)
                                Text(lang.displayName)
                            }
                            .tag(lang)
                        }
                    }
                }
            }

            Section("refresh".localized) {
                Picker("refresh_interval".localized, selection: $refreshInterval) {
                    Text("15_minutes".localized).tag(15)
                    Text("30_minutes".localized).tag(30)
                    Text("1_hour".localized).tag(60)
                }
            }

            Section {
                Button("clear_cache".localized) {
                    clearCache()
                }

                Button("logout".localized, role: .destructive) {
                    logout()
                }
            }

            Section {
                HStack {
                    Text("version".localized)
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("settings".localized)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func clearCache() {
        DataStore.shared.clearCache()
    }

    private func logout() {
        TokenManager.shared.deleteToken()
        DataStore.shared.clearAll()
    }
}
