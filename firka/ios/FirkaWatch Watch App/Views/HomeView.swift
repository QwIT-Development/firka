import SwiftUI
internal import Combine

struct HomeView: View {
    let dataStore: DataStore
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let breakInfo = dataStore.data?.timetable.currentBreak {
                    breakView(breakInfo)
                } else if !dataStore.hasToken && dataStore.data == nil {
                    noTokenView
                } else if let current = currentLesson {
                    currentLessonView(current)
                } else if let next = nextLesson {
                    if isBreakBetweenLessons {
                        breakBetweenView(next)
                    } else {
                        beforeSchoolView(next)
                    }
                } else {
                    noMoreLessonsView
                }

                refreshButton

                if dataStore.lastUpdated != nil {
                    lastUpdatedView
                }
            }
            .padding()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    // MARK: - Refresh Button

    @State private var refreshStatus: RefreshStatus = .idle

    enum RefreshStatus {
        case idle, loading, success, failure
    }

    private var refreshButton: some View {
        Button(action: {
            Task {
                refreshStatus = .loading
                await dataStore.refreshAll()
                if dataStore.error == nil && dataStore.data != nil {
                    refreshStatus = .success
                } else {
                    refreshStatus = .failure
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                refreshStatus = .idle
            }
        }) {
            HStack(spacing: 6) {
                switch refreshStatus {
                case .idle:
                    Image(systemName: "arrow.clockwise")
                case .loading:
                    ProgressView()
                        .scaleEffect(0.8)
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .failure:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                Text(refreshStatusText)
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
        .disabled(refreshStatus == .loading)
        .padding(.top, 8)
    }

    private var refreshStatusText: String {
        switch refreshStatus {
        case .idle: return "refresh".localized
        case .loading: return "refreshing".localized
        case .success: return "refresh_success".localized
        case .failure:
            if let error = dataStore.error {
                switch error {
                case "api_error": return "error_api".localized
                case "network": return "error_network".localized
                case "token_expired", "no_token": return "reauth_required".localized
                default: return "refresh_failed".localized
                }
            }
            return "refresh_failed".localized
        }
    }

    // MARK: - Computed Properties

    private var now: Date { currentTime }

    private var todayLessons: [WidgetLesson] {
        let todayStr = formatDateForHomeView(currentTime)

        if let allLessons = dataStore.data?.timetable.allLessons, !allLessons.isEmpty {
            return allLessons
                .filter { $0.date == todayStr }
                .sorted { $0.start < $1.start }
        }

        return dataStore.data?.timetable.today ?? []
    }

    private var currentLesson: WidgetLesson? {
        todayLessons.first { currentTime >= $0.start && currentTime <= $0.end }
    }

    private var nextLesson: WidgetLesson? {
        todayLessons
            .filter { $0.start > currentTime }
            .sorted { $0.start < $1.start }
            .first
    }

    private var previousLesson: WidgetLesson? {
        todayLessons
            .filter { $0.end < currentTime }
            .sorted { $0.end > $1.end }
            .first
    }

    private var isBreakBetweenLessons: Bool {
        guard let prev = previousLesson, let next = nextLesson else { return false }
        return currentTime > prev.end && currentTime < next.start
    }

    // MARK: - Current Lesson View (with CountdownRing)

    @ViewBuilder
    private func currentLessonView(_ lesson: WidgetLesson) -> some View {
        VStack(spacing: 10) {
            Text("current_lesson".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            let totalMinutes = Int(lesson.end.timeIntervalSince(lesson.start) / 60)
            let remaining = max(0, Int(lesson.end.timeIntervalSince(now) / 60))

            HStack(spacing: 10) {
                CountdownRing(
                    totalMinutes: totalMinutes,
                    remainingMinutes: remaining,
                    label: "minutes".localized,
                    size: 56,
                    lineWidth: 6,
                    displayOffset: 1
                )
                .id("lesson-\(lesson.start.timeIntervalSince1970)")
                FirkaCard(isHighlighted: true) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            if let room = lesson.roomName {
                                Label(room, systemImage: "door.right.hand.closed")
                            }
                            Text(lesson.timeString)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Next lesson preview
            if let next = nextLesson {
                Text("next".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                FirkaCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(next.displayName)
                                .font(.subheadline)
                            if let room = next.roomName {
                                Text(room)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text(next.start, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Break Between Lessons (with CountdownRing)

    @ViewBuilder
    private func breakBetweenView(_ next: WidgetLesson) -> some View {
        VStack(spacing: 10) {
            Text("break".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            let remaining = max(0, Int(next.start.timeIntervalSince(now) / 60))

            HStack(spacing: 10) {
                CountdownRing(
                    totalMinutes: 15,
                    remainingMinutes: remaining,
                    label: "minutes".localized,
                    size: 56,
                    lineWidth: 6,
                    displayOffset: 1
                )
                .id("break-\(next.start.timeIntervalSince1970)")

                FirkaCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("next_lesson".localized(next.displayName))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            if let room = next.roomName {
                                Label(room, systemImage: "door.right.hand.closed")
                            }
                            Text(next.start, style: .time)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Before School View

    @ViewBuilder
    private func beforeSchoolView(_ first: WidgetLesson) -> some View {
        VStack(spacing: 12) {
            Text("first_lesson".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            FirkaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(first.displayName)
                        .font(.headline)

                    HStack {
                        if let room = first.roomName {
                            Label(room, systemImage: "door.right.hand.closed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(relativeTimeString(to: first.start))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            if !todayLessons.isEmpty {
                Text("today_lessons_count".localized(todayLessons.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - No More Lessons View

    private var noMoreLessonsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)

            Text("no_more_lessons".localized)
                .font(.headline)

            if let (nextLesson, dayLabel) = nextSchoolDayFirstLesson {
                Text(dayLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                FirkaCard {
                    HStack {
                        Text(nextLesson.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text(nextLesson.start, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var nextSchoolDayFirstLesson: (lesson: WidgetLesson, label: String)? {
        guard let allLessons = dataStore.data?.timetable.allLessons, !allLessons.isEmpty else {
            if let tomorrow = dataStore.data?.timetable.tomorrow.first {
                return (tomorrow, "tomorrow_first_lesson".localized)
            }
            return nil
        }

        let calendar = Calendar.current
        let now = currentTime
        let todayStr = formatDateForHomeView(now)

        let futureLessons = allLessons.filter { $0.date > todayStr }
            .sorted { $0.date < $1.date || ($0.date == $1.date && $0.start < $1.start) }

        guard let firstFuture = futureLessons.first else {
            return nil
        }

        let label = labelForDate(firstFuture.date, relativeTo: now)

        return (firstFuture, label)
    }

    private func formatDateForHomeView(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d",
                      components.year ?? 0,
                      components.month ?? 0,
                      components.day ?? 0)
    }

    private func labelForDate(_ dateStr: String, relativeTo: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        guard let targetDate = formatter.date(from: dateStr) else {
            return "next_school_day".localized
        }

        let today = calendar.startOfDay(for: relativeTo)
        let target = calendar.startOfDay(for: targetDate)

        let daysDiff = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        switch daysDiff {
        case 1:
            return "tomorrow_first_lesson".localized
        case 2...6:
            let dayFormatter = DateFormatter()
            let langCode = WatchL10n.shared.currentLanguage.rawValue
            dayFormatter.locale = Locale(identifier: langCode)
            dayFormatter.dateFormat = "EEEE"
            let dayName = dayFormatter.string(from: targetDate).capitalized
            return "day_first_lesson".localized(dayName)
        default:
            return "next_school_day".localized
        }
    }

    // MARK: - Break/Vacation View

    @ViewBuilder
    private func breakView(_ breakInfo: BreakInfo) -> some View {
        VStack(spacing: 12) {
            let icon = SeasonalIconHelper.iconName(for: breakInfo.nameKey, season: nil)
            let color = SeasonalIconHelper.iconColor(for: breakInfo.nameKey, season: nil)

            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(color)

            Text(breakInfo.name)
                .font(.headline)
        }
    }

    // MARK: - No Token View

    private var noTokenView: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.right.inward")
                .font(.system(size: 44))
                .foregroundColor(.blue)

            Text("pair_with_iphone".localized)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("open_firka_on_iphone".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Last Updated View

    private var lastUpdatedView: some View {
        HStack(spacing: 4) {
            if dataStore.isStale {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
            }
            if let text = dataStore.timeSinceUpdate {
                Text("updated".localized(text))
            }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .padding(.top, 8)
    }

    // MARK: - Relative Time Helper

    private func relativeTimeString(to date: Date) -> String {
        let now = currentTime
        let interval = date.timeIntervalSince(now)

        guard interval > 0 else {
            return "time_now".localized
        }

        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "time_hours_minutes".localized(hours, minutes)
        } else if hours > 0 {
            return "time_hours".localized(hours)
        } else {
            return "time_minutes_only".localized(minutes)
        }
    }
}
