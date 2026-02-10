import Foundation
import WatchKit
import WidgetKit

class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()

    private init() {}

    func scheduleNextRefresh() {
        let interval = calculateOptimalRefreshInterval()

        let preferredDate = Date().addingTimeInterval(interval)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: preferredDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("[BackgroundRefresh] Schedule error: \(error)")
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                print("[BackgroundRefresh] Next refresh scheduled at: \(formatter.string(from: preferredDate)) (\(Int(interval/60)) min)")
            }
        }
    }

    private func calculateOptimalRefreshInterval() -> TimeInterval {
        let userRefreshMinutes = UserDefaults.standard.integer(forKey: "refreshInterval")
        let now = Date()
        let calendar = Calendar.current

        let todayLessons = getTodayLessons()

        guard !todayLessons.isEmpty else {
            return getDefaultInterval(userSetting: userRefreshMinutes, now: now, calendar: calendar)
        }

        let sortedLessons = todayLessons.sorted { $0.start < $1.start }

        guard let firstLesson = sortedLessons.first,
              let lastLesson = sortedLessons.last else {
            return getDefaultInterval(userSetting: userRefreshMinutes, now: now, calendar: calendar)
        }

        let firstStart = firstLesson.start
        let lastEnd = lastLesson.end

        let schoolStartBuffer = firstStart.addingTimeInterval(-30 * 60)

        if now < schoolStartBuffer {
            let intervalUntilWakeUp = schoolStartBuffer.timeIntervalSince(now)
            let interval = max(intervalUntilWakeUp, 15 * 60)
            print("[BackgroundRefresh] Before school - next refresh in \(Int(interval/60)) min (30 min before first lesson)")
            return min(interval, 60 * 60) // Max 1 hour
        }

        if now >= schoolStartBuffer && now <= lastEnd {
            let interval = TimeInterval((userRefreshMinutes > 0 ? userRefreshMinutes : 15) * 60)
            print("[BackgroundRefresh] During school - using \(Int(interval/60)) min interval")
            return interval
        }

        let tomorrowLessons = getTomorrowLessons()
        if !tomorrowLessons.isEmpty,
           let tomorrowFirst = tomorrowLessons.sorted(by: { $0.start < $1.start }).first {

            let tomorrowStartBuffer = tomorrowFirst.start.addingTimeInterval(-30 * 60)
            let timeUntilTomorrowWakeUp = tomorrowStartBuffer.timeIntervalSince(now)

            if timeUntilTomorrowWakeUp > 2 * 60 * 60 {
                print("[BackgroundRefresh] After school - 1 hour interval (tomorrow's first lesson in \(Int(timeUntilTomorrowWakeUp/60)) min)")
                return 60 * 60
            } else {
                print("[BackgroundRefresh] After school, tomorrow soon - 30 min interval")
                return 30 * 60
            }
        }

        print("[BackgroundRefresh] After school, no tomorrow lessons - 1 hour interval")
        return 60 * 60
    }

    private func getDefaultInterval(userSetting: Int, now: Date, calendar: Calendar) -> TimeInterval {
        if userSetting > 0 {
            print("[BackgroundRefresh] No timetable - using user setting: \(userSetting) min")
            return TimeInterval(userSetting * 60)
        }

        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let isWeekday = weekday >= 2 && weekday <= 6

        if isWeekday && hour >= 6 && hour <= 16 {
            print("[BackgroundRefresh] No timetable - weekday school hours: 15 min")
            return 15 * 60
        } else {
            print("[BackgroundRefresh] No timetable - off hours: 1 hour")
            return 60 * 60
        }
    }

    private func getTodayLessons() -> [WidgetLesson] {
        guard let data = DataStore.shared.data else { return [] }
        return data.timetable.today
    }

    private func getTomorrowLessons() -> [WidgetLesson] {
        guard let data = DataStore.shared.data else { return [] }
        return data.timetable.tomorrow
    }

    func handleBackgroundRefresh() async {
        await DataStore.shared.refreshAllWithRecovery()

        WidgetCenter.shared.reloadAllTimelines()

        scheduleNextRefresh()
    }
}
