import AppIntents

@available(iOS 16.0, *)
struct FirkaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetNextLessonIntent(),
            phrases: [
                "Next lesson \(.applicationName)",
                "What is my next lesson \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("shortcut_short_next_lesson", defaultValue: "Next lesson"),
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: GetClosestLessonIntent(),
            phrases: [
                "Closest lesson \(.applicationName)",
                "When is my next lesson \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("shortcut_short_closest_lesson", defaultValue: "Closest lesson"),
            systemImageName: "forward"
        )
        AppShortcut(
            intent: GetTodayTimetableIntent(),
            phrases: [
                "Today's timetable \(.applicationName)",
                "What lessons do I have today \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("shortcut_short_today_timetable", defaultValue: "Today's timetable"),
            systemImageName: "clock"
        )
        AppShortcut(
            intent: GetClosestTimetableIntent(),
            phrases: [
                "Closest timetable \(.applicationName)",
                "When are my next lessons \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("shortcut_short_closest_timetable", defaultValue: "Closest timetable"),
            systemImageName: "forward.fill"
        )
        AppShortcut(
            intent: GetOverallAverageIntent(),
            phrases: [
                "My average \(.applicationName)",
                "What is my average \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("shortcut_short_overall_average", defaultValue: "My average"),
            systemImageName: "chart.bar"
        )
    }
}
