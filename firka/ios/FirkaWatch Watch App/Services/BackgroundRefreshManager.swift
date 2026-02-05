import Foundation
import WatchKit
import WidgetKit

class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()

    private init() {}

    func scheduleNextRefresh() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let isWeekday = weekday >= 2 && weekday <= 6

        let interval: TimeInterval
        if isWeekday && hour >= 6 && hour <= 16 {
            interval = 15 * 60 // 15 minutes during school hours
        } else {
            interval = 60 * 60 // 1 hour outside school hours
        }

        let preferredDate = now.addingTimeInterval(interval)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: preferredDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("[BackgroundRefresh] Schedule error: \(error)")
            }
        }
    }

    func handleBackgroundRefresh() async {
        await DataStore.shared.refreshAll()

        WidgetCenter.shared.reloadAllTimelines()

        scheduleNextRefresh()
    }
}
