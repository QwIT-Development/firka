import SwiftUI

struct TimetableView: View {
    let dataStore: DataStore

    @State private var selectedDay: Int = 0
    @State private var weekOffset: Int = 0

    private var dayLabels: [String] {
        [
            "day_mon".localized,
            "day_tue".localized,
            "day_wed".localized,
            "day_thu".localized,
            "day_fri".localized
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                daySelector

                Divider()
                    .padding(.vertical, 4)

                lessonsContent
            }
            .onAppear {
                updateWeekAndDay()
            }
        }
    }

    private func updateWeekAndDay() {
        let calendar = Calendar.current
        let now = Date()

        if shouldShowNextWeek() {
            weekOffset = 1
            selectedDay = findFirstSchoolDay(weekOffset: 1)
            return
        }

        weekOffset = 0
        let weekday = calendar.component(.weekday, from: now)
        let todayIndex = weekday - 2

        if todayIndex < 0 || todayIndex > 4 {
            selectedDay = findFirstSchoolDay(weekOffset: 0)
            return
        }

        if areTodayLessonsDone(dayIndex: todayIndex) {
            if let nextDay = findNextSchoolDay(after: todayIndex) {
                selectedDay = nextDay
            } else {
                selectedDay = todayIndex
            }
        } else {
            selectedDay = todayIndex
        }
    }

    private func areTodayLessonsDone(dayIndex: Int) -> Bool {
        let todayLessons = lessonsForDay(dayIndex)
        guard !todayLessons.isEmpty else { return true }

        let now = Date()
        let lastLesson = todayLessons.sorted { $0.end > $1.end }.first
        return lastLesson.map { now > $0.end } ?? true
    }

    private func findNextSchoolDay(after dayIndex: Int) -> Int? {
        for day in (dayIndex + 1)...4 {
            if !lessonsForDay(day).isEmpty {
                return day
            }
        }
        return nil
    }

    private func findFirstSchoolDay(weekOffset: Int) -> Int {
        let oldOffset = self.weekOffset
        for day in 0...4 {
            let lessons = lessonsForDayWithOffset(day, weekOffset: weekOffset)
            if !lessons.isEmpty {
                return day
            }
        }
        return 0
    }

    private func lessonsForDayWithOffset(_ day: Int, weekOffset: Int) -> [WidgetLesson] {
        guard let data = dataStore.data else { return [] }

        let allLessons: [WidgetLesson]
        if let all = data.timetable.allLessons, !all.isEmpty {
            allLessons = all
        } else {
            return []
        }

        let targetDateStr = getDateStringForDayWithOffset(day, weekOffset: weekOffset)
        return allLessons.filter { $0.date == targetDateStr }
    }

    private func getDateStringForDayWithOffset(_ day: Int, weekOffset: Int) -> String {
        let calendar = Calendar.current
        let now = Date()

        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday == 1) ? -6 : (2 - weekday)

        guard let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: now) else {
            return ""
        }

        let totalDaysToAdd = day + (weekOffset * 7)
        guard let targetDate = calendar.date(byAdding: .day, value: totalDaysToAdd, to: monday) else {
            return ""
        }

        return formatDate(targetDate)
    }

    private func shouldShowNextWeek() -> Bool {
        guard let allLessons = dataStore.data?.timetable.allLessons, !allLessons.isEmpty else {
            return false
        }

        let now = Date()
        let calendar = Calendar.current

        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday == 1) ? -6 : (2 - weekday)
        guard let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: now),
              let friday = calendar.date(byAdding: .day, value: 4, to: monday) else {
            return false
        }
        let fridayString = formatDate(friday)
        let mondayString = formatDate(monday)

        let currentWeekLessons = allLessons.filter { lesson in
            lesson.date >= mondayString && lesson.date <= fridayString
        }

        guard !currentWeekLessons.isEmpty else {
            return false
        }

        let lastLesson = currentWeekLessons
            .sorted { $0.date > $1.date || ($0.date == $1.date && $0.end > $1.end) }
            .first

        guard let last = lastLesson else {
            return false
        }

        return now > last.end
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { day in
                Button(action: { selectedDay = day }) {
                    Text(dayLabels[day])
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .foregroundColor(selectedDay == day ? .white : .primary)
                        .background(selectedDay == day ? Color.blue : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isToday(day) && selectedDay != day ? Color.blue : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func isToday(_ day: Int) -> Bool {
        guard weekOffset == 0 else { return false }
        let weekday = Calendar.current.component(.weekday, from: Date())
        return day == weekday - 2
    }

    // MARK: - Lessons Content

    @ViewBuilder
    private var lessonsContent: some View {
        let lessons = lessonsForDay(selectedDay)

        if lessons.isEmpty {
            freeDayView
        } else {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(lessons) { lesson in
                        NavigationLink {
                            LessonDetailView(lesson: lesson)
                        } label: {
                            lessonRow(lesson)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }

    private func lessonsForDay(_ day: Int) -> [WidgetLesson] {
        guard let data = dataStore.data else { return [] }

        let allLessons: [WidgetLesson]
        if let all = data.timetable.allLessons, !all.isEmpty {
            allLessons = all
        } else {
            var combined: [WidgetLesson] = []
            combined.append(contentsOf: data.timetable.today)
            combined.append(contentsOf: data.timetable.tomorrow)
            if let nextSchoolDay = data.timetable.nextSchoolDay {
                combined.append(contentsOf: nextSchoolDay)
            }
            allLessons = combined
        }

        let targetDateStr = getDateStringForDay(day)

        let uniqueDates = Set(allLessons.map { $0.date }).sorted()
        print("[Watch] lessonsForDay: day=\(day), weekOffset=\(weekOffset), targetDate=\(targetDateStr), lessons=\(allLessons.count)")
        print("[Watch] Unique dates in lessons: \(uniqueDates)")

        if let first = allLessons.first {
            let cal = Calendar.current
            let comp = cal.dateComponents([.year, .month, .day, .hour, .minute], from: first.start)
            print("[Watch] First lesson: date=\(first.date), start=\(comp.year!)-\(comp.month!)-\(comp.day!) \(comp.hour!):\(comp.minute!)")
        }

        let filtered = allLessons.filter { $0.date == targetDateStr }
        print("[Watch] Filtered lessons: \(filtered.count) for \(targetDateStr)")

        return filtered.sorted { ($0.lessonNumber ?? 0) < ($1.lessonNumber ?? 0) }
    }

    private func getDateStringForDay(_ day: Int) -> String {
        let calendar = Calendar.current
        let now = Date()

        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday == 1) ? -6 : (2 - weekday)

        guard let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: now) else {
            return ""
        }

        let totalDaysToAdd = day + (weekOffset * 7)
        guard let targetDate = calendar.date(byAdding: .day, value: totalDaysToAdd, to: monday) else {
            return ""
        }

        return formatDate(targetDate)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d",
                      components.year ?? 0,
                      components.month ?? 0,
                      components.day ?? 0)
    }

    private var freeDayView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)

            Text("free_day".localized)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Lesson Row

    @ViewBuilder
    private func lessonRow(_ lesson: WidgetLesson) -> some View {
        FirkaCard(isHighlighted: lesson.isCurrentlyActive) {
            HStack(alignment: .top, spacing: 8) {
                if let number = lesson.lessonNumber {
                    Text("\(number).")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .frame(width: 24, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        HStack(spacing: 4) {
                            Text(lesson.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            if let statusIcon = lessonStatusIconName(for: lesson) {
                                Image(systemName: statusIcon)
                                    .font(.caption2)
                                    .foregroundColor(lessonStatusColor(for: lesson))
                            }
                        }

                        Spacer()

                        Text(lesson.start, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        if let teacher = lesson.teacher {
                            Text(teacher)
                                .lineLimit(1)
                        }
                        if let room = lesson.roomName {
                            Text("•")
                            Text(room)
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private func lessonStatusIconName(for lesson: WidgetLesson) -> String? {
        if lesson.isCancelled {
            return "xmark.circle.fill"
        }
        if lesson.isSubstitution {
            return "exclamationmark.circle.fill"
        }
        return nil
    }

    private func lessonStatusColor(for lesson: WidgetLesson) -> Color {
        lesson.isCancelled ? .red : .yellow
    }
}

#if DEBUG
struct TimetableView_Previews: PreviewProvider {
    static var previews: some View {
        TimetableView(dataStore: DataStore.shared)
    }
}
#endif
