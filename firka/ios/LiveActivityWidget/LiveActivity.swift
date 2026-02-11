import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 18.0, *)
struct TimetableLiveActivity: Widget {
    var body: some WidgetConfiguration {
        TimetableLiveActivityLegacy.activityConfiguration
            .supplementalActivityFamilies([.small])
    }
}

@available(iOS 16.2, *)
struct TimetableLiveActivityLegacy: Widget {
    var body: some WidgetConfiguration {
        Self.activityConfiguration
    }

    static var activityConfiguration: ActivityConfiguration<TimetableActivityAttributes> {
        ActivityConfiguration(for: TimetableActivityAttributes.self) { context in
            // Lock screen/banner UI
            TimetableLiveActivityAdaptiveView(context: context)
                .activityBackgroundTint(Color(red: 0.1, green: 0.15, blue: 0.1))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            let mode = context.state.mode ?? (context.state.isBreak ? "break" : "lesson")
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            return DynamicIsland {
                    // Expanded UI
                    DynamicIslandExpandedRegion(.leading) {
                        EmptyView()
                    }
                    
                    DynamicIslandExpandedRegion(.trailing) {
                        let beforeSchoolTime = mode == "beforeSchool" ? {
                            let adjustedDate = context.state.endTime
                            return timeFormatter.string(from: adjustedDate)
                        }() : nil
                        
                        if SeasonalIconHelper.isSeasonalMode(mode) {
                            EmptyView()
                        } else if mode == "beforeSchool", let timeString = beforeSchoolTime {
                            Text("\(context.state.labels?.startTimeLabel ?? "Kezdés:") \(timeString)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        } else {
                            Text(context.state.formattedStartTime + " - " + context.state.formattedEndTime)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    DynamicIslandExpandedRegion(.center) {
                        let season = context.state.season ?? ""
                        VStack(spacing: 4) {
                            if mode == "beforeSchool" {
                                HStack(alignment: .center, spacing: 6) {
                                    Image(systemName: SeasonalIconHelper.iconName(for: mode, season: season, lessonIcon: context.state.lessonIcon))
                                        .font(.system(size: 18))
                                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                                    Text(context.state.labels?.title ?? "Hamarosan suli")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(context.state.labels?.firstLessonLabel ?? "Első órád:")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        Text(context.state.lessonName)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                    }

                                    if let roomName = context.state.roomName {
                                        HStack(spacing: 4) {
                                            Text(context.state.labels?.roomLabel ?? "Terem:")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                            Text(roomName)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    if let teacherName = context.state.teacherName {
                                        HStack(spacing: 4) {
                                            Text(context.state.labels?.teacherLabel ?? "Tanár:")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                            Text(teacherName)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            } else if SeasonalIconHelper.isSeasonalMode(mode) {
                                if mode == "xmas" || mode == "newYearEve" || mode == "newYearDay" {
                                    HStack(alignment: .center, spacing: 6) {
                                        Image(systemName: SeasonalIconHelper.iconName(for: mode, season: season))
                                            .font(.system(size: 18))
                                            .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                                        Text(context.state.message ?? "Szünet")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                    }
                                } else {
                                    HStack(alignment: .center, spacing: 6) {
                                        Image(systemName: SeasonalIconHelper.iconName(for: mode, season: season))
                                            .font(.system(size: 18))
                                            .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                                        Text(context.state.labels?.title ?? context.state.lessonName)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                }
                            } else if context.state.isBreak {
                                HStack(alignment: .center, spacing: 6) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                                    Text(context.state.labels?.title ?? "Szünet")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                if let nextLessonName = context.state.nextLessonName {
                                    HStack(spacing: 4) {
                                        Text(context.state.labels?.nextLabel ?? "Következő:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Text(nextLessonName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }

                                if let nextRoomName = context.state.nextRoomName {
                                    Text("\(context.state.labels?.roomLabel ?? "Terem:") \(nextRoomName)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            } else {
                                HStack(alignment: .center, spacing: 6) {
                                    if let lessonNumber = context.state.lessonNumber {
                                        Text("\(lessonNumber).")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    Text(context.state.lessonName)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }

                                if !(context.state.isCancelled ?? false) {
                                    if let lessonTheme = context.state.lessonTheme, !lessonTheme.isEmpty {
                                        Text(lessonTheme)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }

                                HStack(spacing: 8) {
                                    if let roomName = context.state.roomName {
                                        Label(roomName, systemImage: "door.left.hand.closed")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }

                                    if context.state.isSubstitution ?? false {
                                        Label(context.state.labels?.substitutionText ?? "Helyettesítés", systemImage: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 12))
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                    
                    DynamicIslandExpandedRegion(.bottom) {
                        let season = context.state.season ?? ""
                        VStack(spacing: 4) {
                            HStack {
                                Spacer()
                                if mode == "xmas" || mode == "newYearDay" {
                                EmptyView()
                            } else if mode == "beforeSchool" {
                                if context.state.endTime > context.state.currentTime {
                                    Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                                        .multilineTextAlignment(.center)
                                        .monospacedDigit()
                                } else {
                                    Text(context.state.formattedEndTime)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                                        .multilineTextAlignment(.center)
                                        .monospacedDigit()
                                }
                            } else if mode == "seasonalBreak" {
                                Text(context.state.seasonalRemainingText)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            } else if context.state.isCancelled ?? false {
                                Text(context.state.labels?.cancelledText ?? "Elmaradt")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            }
                                Spacer()
                            }

                            // Token expiration warning (only for specific modes)
                            let mode3 = context.state.mode ?? (context.state.isBreak ? "break" : "lesson")
                            let showWarningModes = ["newYearEve", "lesson", "break", "seasonalBreak"]
                            if let warning = context.state.tokenExpirationWarning, !warning.isEmpty, showWarningModes.contains(mode3) {
                                let isExpired = context.state.tokenExpired ?? false
                                let warningColor: Color = isExpired ? .red : .orange
                                let warningIcon = isExpired ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill"

                                HStack(spacing: 3) {
                                    Image(systemName: warningIcon)
                                        .font(.system(size: 8))
                                        .foregroundColor(warningColor)
                                    Text(warning)
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(warningColor)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                            }
                        }
                    }
                } compactLeading: {
                    let season = context.state.season ?? ""
                    let iconName: String = {
                        if SeasonalIconHelper.isSeasonalMode(mode) || mode == "beforeSchool" {
                            return SeasonalIconHelper.iconName(for: mode, season: season, lessonIcon: context.state.lessonIcon)
                        } else {
                            return context.state.isBreak ? "cup.and.saucer.fill" : (context.state.lessonIcon ?? "book.fill")
                        }
                    }()
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                } compactTrailing: {
                    let season = context.state.season ?? ""
                    if mode == "xmas" || mode == "newYearDay" {
                        Text("")
                            .frame(width: 50)
                    } else if context.state.isCancelled ?? false {
                        Text("❌")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 50)
                    } else if let compactText = context.state.compactTimerText {
                        Text(compactText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                            .frame(width: 50)
                    } else {
                        Text("")
                            .frame(width: 50)
                    }
                } minimal: {
                    let season = context.state.season ?? ""
                    let iconName: String = {
                        if SeasonalIconHelper.isSeasonalMode(mode) || mode == "beforeSchool" {
                            return SeasonalIconHelper.iconName(for: mode, season: season, lessonIcon: context.state.lessonIcon)
                        } else {
                            return context.state.isBreak ? "cup.and.saucer.fill" : (context.state.lessonIcon ?? "book.fill")
                        }
                    }()
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                }
            }
        }
    }

@available(iOS 16.2, *)
struct TimetableLiveActivityAdaptiveView: View {
    let context: ActivityViewContext<TimetableActivityAttributes>

    var body: some View {
        if #available(iOS 18.0, *) {
            TimetableLiveActivityFamilyView(context: context)
        } else {
            TimetableLiveActivityView(context: context)
        }
    }
}

@available(iOS 18.0, *)
struct TimetableLiveActivityFamilyView: View {
    @Environment(\.activityFamily) private var activityFamily
    let context: ActivityViewContext<TimetableActivityAttributes>

    var body: some View {
        switch activityFamily {
        case .small:
            SmallActivityView(context: context)
        case .medium:
            TimetableLiveActivityView(context: context)
        @unknown default:
            TimetableLiveActivityView(context: context)
        }
    }
}

// MARK: - Lock Screen View
@available(iOS 16.2, *)
struct TimetableLiveActivityView: View {
    let context: ActivityViewContext<TimetableActivityAttributes>

    var body: some View {
        let mode = context.state.mode ?? (context.state.isBreak ? "break" : "lesson")
            VStack(spacing: 12) {
                let season = context.state.season ?? ""
                let screenTimeFormatter = DateFormatter()
                let _ = { screenTimeFormatter.dateFormat = "HH:mm" }()
                
                let beforeSchoolTime: String? = mode == "beforeSchool" ? {
                    let adjustedDate = context.state.endTime
                    return screenTimeFormatter.string(from: adjustedDate)
                }() : nil
                let iconName: String = {
                    if SeasonalIconHelper.isSeasonalMode(mode) || mode == "beforeSchool" {
                        return SeasonalIconHelper.iconName(for: mode, season: season, lessonIcon: context.state.lessonIcon)
                    } else {
                        return context.state.isBreak ? "cup.and.saucer.fill" : (context.state.lessonIcon ?? "book.fill")
                    }
                }()

                // Header
                HStack {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))

                    VStack(alignment: .leading, spacing: 2) {
                        if mode == "beforeSchool" {
                            Text(context.state.labels?.title ?? "Hamarosan suli")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        } else if SeasonalIconHelper.isSeasonalMode(mode) {
                            if mode == "xmas" || mode == "newYearEve" || mode == "newYearDay" {
                                Text(context.state.message ?? context.state.lessonName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            } else {
                                Text(context.state.labels?.title ?? context.state.lessonName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        } else if context.state.isBreak {
                            Text(context.state.labels?.title ?? "Szünet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            if let nextLessonName = context.state.nextLessonName {
                                Text("\(context.state.labels?.nextLabel ?? "Következő:") \(nextLessonName)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        } else {
                            if let lessonNumber = context.state.lessonNumber {
                                Text("\(lessonNumber)\(context.state.labels?.lessonNumberLabel ?? ". óra")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            Text(context.state.lessonName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if SeasonalIconHelper.isSeasonalMode(mode) {
                            EmptyView()
                        } else if mode == "beforeSchool", let timeString = beforeSchoolTime {
                            Text("\(context.state.labels?.startTimeLabel ?? "Kezdés:") \(timeString)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            Text(context.state.formattedStartTime + " - " + context.state.formattedEndTime)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }

                        if SeasonalIconHelper.isSeasonalMode(mode) {
                            EmptyView()
                        } else if mode == "beforeSchool" {
                            EmptyView()
                        } else if context.state.isBreak {
                            if let _ = context.state.nextStartTime {
                                Text("\(context.state.labels?.startTimeLabel ?? "Kezdés:") \(context.state.formattedNextStartTime)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            } else {
                                EmptyView()
                            }
                        } else {
                            if let roomName = context.state.roomName {
                                HStack(spacing: 4) {
                                    Image(systemName: "door.left.hand.closed")
                                        .font(.system(size: 10))
                                    Text(roomName)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.gray)
                            } else {
                                EmptyView()
                            }
                        }
                    }
                }

                // Content
                let mode2 = context.state.mode ?? (context.state.isBreak ? "break" : "lesson")
                if mode2 == "beforeSchool" {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(context.state.labels?.firstLessonLabel ?? "Első órád:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(context.state.lessonName)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }

                        if let roomName = context.state.roomName {
                            HStack(spacing: 4) {
                                Text(context.state.labels?.roomLabel ?? "Terem:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text(roomName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }

                        if let teacherName = context.state.teacherName {
                            HStack(spacing: 4) {
                                Text(context.state.labels?.teacherLabel ?? "Tanár:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text(teacherName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if SeasonalIconHelper.isSeasonalMode(mode2) {
                    EmptyView()
                } else if !context.state.isBreak {
                    VStack(alignment: .leading, spacing: 4) {
                        if !(context.state.isCancelled ?? false) {
                            if let lessonTheme = context.state.lessonTheme, !lessonTheme.isEmpty {
                                HStack {
                                    Text(context.state.labels?.themeLabel ?? "Téma:")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.gray)
                                    Text(lessonTheme)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                            }
                        }

                        if context.state.isSubstitution ?? false {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12))
                                Text(context.state.labels?.substitutionText ?? "Helyettesítés")
                                    .font(.system(size: 12, weight: .semibold))
                                if let substituteTeacher = context.state.substituteTeacher {
                                    Text("(\(substituteTeacher))")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let nextRoomName = context.state.nextRoomName {
                    HStack {
                        Image(systemName: "door.left.hand.closed")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("\(context.state.labels?.nextRoomLabel ?? "Következő terem:") \(nextRoomName)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Countdown Timer
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        let mode3 = context.state.mode ?? (context.state.isBreak ? "break" : "lesson")
                        if mode3 == "xmas" || mode3 == "newYearDay" {
                            EmptyView()
                        } else if mode3 == "beforeSchool" {
                            Text(context.state.labels?.timerLabel ?? "Első óra kezdése")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)

                            if context.state.endTime > context.state.currentTime {
                                Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(SeasonalIconHelper.iconColor(for: mode3, season: season))
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            } else {
                                Text(context.state.formattedEndTime)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(SeasonalIconHelper.iconColor(for: mode3, season: season))
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            }
                        } else if mode3 == "seasonalBreak" {
                            Text(context.state.labels?.remainingLabel ?? "Szünetből hátralévő idő")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            Text(context.state.seasonalDisplayValue)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(SeasonalIconHelper.iconColor(for: mode3, season: season))
                                .multilineTextAlignment(.center)
                                .monospacedDigit()
                        } else {
                            if context.state.isCancelled ?? false {
                                Text(context.state.labels?.cancelledText ?? "Elmaradt")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            } else {
                                let labelText: String = {
                                    if mode3 == "newYearEve" {
                                        return context.state.labels?.timerLabel ?? "Új év"
                                    } else if mode3 == "beforeSchool" {
                                        return context.state.labels?.timerLabel ?? "Első óra kezdése"
                                    } else if context.state.isBreak {
                                        return context.state.labels?.timerLabel ?? "Szünet vége"
                                    } else {
                                        return context.state.labels?.timerLabel ?? "Óra vége"
                                    }
                                }()
                                Text(labelText)
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(SeasonalIconHelper.iconColor(for: mode3, season: season))
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            }
                        }
                    }
                    Spacer()
                }

                // Token expiration warning (only for specific modes)
                let showWarningModes = ["newYearEve", "lesson", "break", "seasonalBreak"]
                if let warning = context.state.tokenExpirationWarning, !warning.isEmpty, showWarningModes.contains(mode) {
                    let isExpired = context.state.tokenExpired ?? false
                    let warningColor: Color = isExpired ? .red : .orange
                    let warningIcon = isExpired ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill"

                    HStack(spacing: 4) {
                        Image(systemName: warningIcon)
                            .font(.system(size: 10))
                            .foregroundColor(warningColor)
                        Text(warning)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(warningColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(16)
        }
}

@available(iOS 18.0, *)
struct SmallActivityView: View {
    let context: ActivityViewContext<TimetableActivityAttributes>

    private var mode: String {
        context.state.mode ?? (context.state.isBreak ? "break" : "lesson")
    }

    private var season: String {
        context.state.season ?? ""
    }

    private var titleText: String {
        switch mode {
        case "beforeSchool":
            return firstNonEmpty([
                trimmedOrNil(context.state.labels?.title),
                trimmedOrNil(context.state.lessonName),
                trimmedOrNil(context.state.message),
            ]) ?? ""
        case "xmas", "newYearEve", "newYearDay":
            return firstNonEmpty([
                trimmedOrNil(context.state.message),
                trimmedOrNil(context.state.lessonName),
                trimmedOrNil(context.state.labels?.title),
            ]) ?? ""
        case "seasonalBreak":
            return firstNonEmpty([
                trimmedOrNil(context.state.labels?.title),
                trimmedOrNil(context.state.lessonName),
                trimmedOrNil(context.state.message),
            ]) ?? ""
        case "break":
            return firstNonEmpty([
                trimmedOrNil(context.state.labels?.title),
                trimmedOrNil(context.state.message),
            ]) ?? ""
        default:
            return firstNonEmpty([
                trimmedOrNil(context.state.lessonName),
                trimmedOrNil(context.state.labels?.title),
                trimmedOrNil(context.state.message),
            ]) ?? ""
        }
    }

    private var iconName: String {
        if SeasonalIconHelper.isSeasonalMode(mode) || mode == "beforeSchool" {
            return SeasonalIconHelper.iconName(for: mode, season: season, lessonIcon: context.state.lessonIcon)
        }

        return context.state.isBreak ? "cup.and.saucer.fill" : (context.state.lessonIcon ?? "book.fill")
    }

    private var warningState: (text: String, color: Color, icon: String)? {
        let showWarningModes = ["newYearEve", "lesson", "break", "seasonalBreak"]
        guard showWarningModes.contains(mode),
              let warningText = trimmedOrNil(context.state.tokenExpirationWarning) else {
            return nil
        }

        let isExpired = context.state.tokenExpired ?? false
        return (
            text: warningText,
            color: isExpired ? .red : .orange,
            icon: isExpired ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill"
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))

                if mode == "lesson", let lessonNumber = context.state.lessonNumber {
                    Text("\(lessonNumber). \(titleText)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .truncationMode(.tail)
                } else {
                    Text(titleText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 0)
            }

            detailsSection

            Spacer(minLength: 0)

            timerSection

            if let warningState = warningState {
                HStack(spacing: 3) {
                    Image(systemName: warningState.icon)
                        .font(.system(size: 8))
                        .foregroundColor(warningState.color)

                    Text(warningState.text)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(warningState.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .truncationMode(.tail)
                }
                .padding(.top, 1)
            }
        }
        .padding(10)
    }

    @ViewBuilder
    private var detailsSection: some View {
        switch mode {
        case "beforeSchool":
            labeledDetailLine(
                label: context.state.labels?.firstLessonLabel,
                value: context.state.lessonName,
                color: .white,
                weight: .semibold
            )
            labeledDetailLine(
                label: context.state.labels?.teacherLabel,
                value: context.state.teacherName,
                color: .white,
                weight: .semibold
            )
            labeledDetailLine(
                label: context.state.labels?.roomLabel,
                value: context.state.roomName,
                color: .white,
                weight: .semibold
            )

        case "lesson":
            if context.state.isSubstitution ?? false {
                if let substitution = trimmedOrNil(context.state.labels?.substitutionText) {
                    if let substituteTeacher = trimmedOrNil(context.state.substituteTeacher) {
                        detailLine("\(substitution) (\(substituteTeacher))", color: .orange)
                    } else {
                        detailLine(substitution, color: .orange)
                    }
                }
            }

        case "break":
            labeledDetailLine(
                label: context.state.labels?.nextLabel,
                value: context.state.nextLessonName,
                color: .white,
                weight: .semibold
            )
            labeledDetailLine(
                label: context.state.labels?.roomLabel,
                value: context.state.nextRoomName,
                color: .white,
                weight: .semibold
            )

        case "seasonalBreak":
            if let remainingLabel = trimmedOrNil(context.state.labels?.remainingLabel) {
                detailLine(remainingLabel)
            }

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var timerSection: some View {
        switch mode {
        case "xmas", "newYearDay":
            EmptyView()

        case "seasonalBreak":
            if let remainingLabel = trimmedOrNil(context.state.labels?.remainingLabel) {
                timerLabelLine(remainingLabel)
            }
            timerValueText(context.state.seasonalDisplayValue)

        case "newYearEve", "beforeSchool":
            if let timerLabel = trimmedOrNil(context.state.labels?.timerLabel) {
                if mode == "beforeSchool" {
                    timerLabelLine(timerLabel, color: .white, weight: .semibold)
                } else {
                    timerLabelLine(timerLabel)
                }
            }
            countdownValueView()

        case "lesson", "break", "loading":
            if context.state.isCancelled ?? false {
                if let cancelled = trimmedOrNil(context.state.labels?.cancelledText) {
                    timerValueText(cancelled, color: .red)
                }
            } else {
                if let timerLabel = trimmedOrNil(context.state.labels?.timerLabel) {
                    if mode == "lesson" || mode == "break" {
                        timerLabelLine(timerLabel, color: .white, weight: .semibold)
                    } else {
                        timerLabelLine(timerLabel)
                    }
                }
                countdownValueView()
            }

        default:
            countdownValueView()
        }
    }

    @ViewBuilder
    private func labeledDetailLine(
        label: String?,
        value: String?,
        color: Color = .gray,
        weight: Font.Weight = .regular
    ) -> some View {
        if let text = joinedLabelValue(label: label, value: value) {
            detailLine(text, color: color, weight: weight)
        }
    }

    @ViewBuilder
    private func countdownValueView() -> some View {
        if context.state.endTime > context.state.currentTime {
            Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(SeasonalIconHelper.iconColor(for: mode, season: season))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            timerValueText(context.state.formattedEndTime)
        }
    }

    private func detailLine(
        _ text: String,
        color: Color = .gray,
        weight: Font.Weight = .regular
    ) -> some View {
        Text(text)
            .font(.system(size: 9, weight: weight))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timerLabelLine(
        _ text: String,
        color: Color = .gray,
        weight: Font.Weight = .regular
    ) -> some View {
        Text(text)
            .font(.system(size: 8, weight: weight))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timerValueText(_ text: String, color: Color? = nil) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(color ?? SeasonalIconHelper.iconColor(for: mode, season: season))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func joinedLabelValue(label: String?, value: String?) -> String? {
        guard let value = trimmedOrNil(value) else { return nil }

        if let label = trimmedOrNil(label) {
            return "\(label) \(value)"
        }

        return value
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        for value in values {
            if let value = value, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func trimmedOrNil(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
