import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.2, *)
struct TimetableLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimetableActivityAttributes.self) { context in
            // Lock screen/banner UI
            TimetableLiveActivityView(context: context)
                .activityBackgroundTint(Color(red: 0.1, green: 0.15, blue: 0.1))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            let mode = context.state.mode ?? (context.state.isBreak ? "break" : "lesson")

            if mode == "end" {
                return DynamicIsland {
                    // Expanded UI for 'end' state
                    DynamicIslandExpandedRegion(.leading) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        EmptyView()
                    }
                    DynamicIslandExpandedRegion(.center) {
                        Text(context.state.lessonName)
                            .lineLimit(1)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        Text("A mai órarended véget ért.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                } compactLeading: {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                } compactTrailing: {
                    Text("Vége")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                } minimal: {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                }
            } else {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                
                return DynamicIsland {
                    // Expanded UI
                    DynamicIslandExpandedRegion(.leading) {
                        let season = context.state.season ?? ""
                        HStack(alignment: .center, spacing: 4) {
                            if mode == "beforeSchool" {
                                Image(systemName: SeasonalIconHelper.iconName(for: mode, season: season))
                                    .font(.system(size: 18))
                                    .foregroundColor(SeasonalIconHelper.iconColor(for: mode))
                            } else if !SeasonalIconHelper.isSeasonalMode(mode) && !context.state.isBreak {
                                if let lessonNumber = context.state.lessonNumber {
                                    Text("\(lessonNumber).")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    EmptyView()
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    DynamicIslandExpandedRegion(.trailing) {
                        let beforeSchoolTime = mode == "beforeSchool" ? {
                            let adjustedDate = context.state.endTime
                            return timeFormatter.string(from: adjustedDate)
                        }() : nil
                        
                        if SeasonalIconHelper.isSeasonalMode(mode) {
                            EmptyView()
                        } else if mode == "beforeSchool", let timeString = beforeSchoolTime {
                            Text("Kezdés: \(timeString)")
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
                                Text("Hamarosan suli")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("Első órád:")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        Text(context.state.lessonName)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    if let roomName = context.state.roomName {
                                        HStack(spacing: 4) {
                                            Text("Terem:")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                            Text(roomName)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    if let teacherName = context.state.teacherName {
                                        HStack(spacing: 4) {
                                            Text("Tanár:")
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
                                    // Global holidays: show message prominently
                                    HStack(alignment: .center, spacing: 6) {
                                        Image(systemName: SeasonalIconHelper.iconName(for: mode, season: season))
                                            .font(.system(size: 18))
                                            .foregroundColor(SeasonalIconHelper.iconColor(for: mode))
                                        Text(context.state.message ?? "Szünet")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                    }
                                } else {
                                    // Seasonal breaks: show holiday title
                                    HStack(alignment: .center, spacing: 6) {
                                        Image(systemName: SeasonalIconHelper.iconName(for: mode, season: season))
                                            .font(.system(size: 18))
                                            .foregroundColor(SeasonalIconHelper.iconColor(for: mode))
                                        Text(SeasonalIconHelper.holidayTitle(for: season))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                }
                            } else if context.state.isBreak {
                                Text("Szünet")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if let nextLessonName = context.state.nextLessonName {
                                    HStack(spacing: 4) {
                                        Text("Következő:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Text(nextLessonName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                if let nextRoomName = context.state.nextRoomName {
                                    Text("Terem: \(nextRoomName)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text(context.state.lessonName)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                if let lessonTheme = context.state.lessonTheme, !lessonTheme.isEmpty {
                                    Text(lessonTheme)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                                
                                HStack(spacing: 8) {
                                    if let roomName = context.state.roomName {
                                        Label(roomName, systemImage: "door.left.hand.closed")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    if context.state.isSubstitution ?? false {
                                        Label("Helyettesítés", systemImage: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 12))
                                            .foregroundColor(.orange)
                                    }
                                    
                                    if context.state.isCancelled ?? false {
                                        Label("Elmaradt", systemImage: "xmark.circle")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    
                    DynamicIslandExpandedRegion(.bottom) {
                        HStack {
                            Spacer()
                            if mode == "xmas" || mode == "newYearDay" {
                                EmptyView()
                            } else if mode == "beforeSchool" {
                                if context.state.endTime > context.state.currentTime {
                                    Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.green)
                                        .multilineTextAlignment(.center)
                                        .monospacedDigit()
                                } else {
                                    Text(context.state.formattedEndTime)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.green)
                                        .multilineTextAlignment(.center)
                                        .monospacedDigit()
                                }
                            } else if mode == "seasonalBreak" {
                                Text(context.state.seasonalRemainingText)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            } else {
                                Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            }
                            Spacer()
                        }
                    }
                } compactLeading: {
                    let season = context.state.season ?? ""
                    let iconName: String = {
                        if SeasonalIconHelper.isSeasonalMode(mode) || mode == "beforeSchool" {
                            return SeasonalIconHelper.iconName(for: mode, season: season)
                        } else {
                            return context.state.isBreak ? "cup.and.saucer.fill" : "book.fill"
                        }
                    }()
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode))
                } compactTrailing: {
                    if SeasonalIconHelper.isSeasonalMode(mode) {
                        // Show timer for New Year's Eve countdown and seasonal breaks
                        if mode == "newYearEve" || mode == "seasonalBreak" {
                             Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.green)
                                .monospacedDigit()
                                .frame(width: 50)
                        } else {
                            // No timer for xmas and newYearDay
                            Text("")
                                .frame(width: 50)
                        }
                    } else {
                        Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                } minimal: {
                    let season = context.state.season ?? ""
                    let iconName: String = {
                        if SeasonalIconHelper.isSeasonalMode(mode) || mode == "beforeSchool" {
                            return SeasonalIconHelper.iconName(for: mode, season: season)
                        } else {
                            return context.state.isBreak ? "cup.and.saucer.fill" : "book.fill"
                        }
                    }()
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode))
                }
            }
        }
    }
}

// MARK: - Lock Screen View
@available(iOS 16.2, *)
struct TimetableLiveActivityView: View {
    let context: ActivityViewContext<TimetableActivityAttributes>

    var body: some View {
        let mode = context.state.mode ?? (context.state.isBreak ? "break" : "lesson")
        
        if mode == "end" {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    Text(context.state.lessonName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                Text("A mai órarended véget ért.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        } else {
            VStack(spacing: 12) {
                let season = context.state.season ?? ""
                let screenTimeFormatter = DateFormatter()
                let _ = { screenTimeFormatter.dateFormat = "HH:mm" }()
                
                let beforeSchoolTime = mode == "beforeSchool" ? {
                    let adjustedDate = context.state.endTime
                    return screenTimeFormatter.string(from: adjustedDate)
                }() : nil
                let iconName: String = {
                    if SeasonalIconHelper.isSeasonalMode(mode) || mode == "beforeSchool" {
                        return SeasonalIconHelper.iconName(for: mode, season: season)
                    } else {
                        return context.state.isBreak ? "cup.and.saucer.fill" : "book.fill"
                    }
                }()
                
                // Header
                HStack {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(SeasonalIconHelper.iconColor(for: mode))

                    VStack(alignment: .leading, spacing: 2) {
                        if mode == "beforeSchool" {
                            Text("Hamarosan suli")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        } else if SeasonalIconHelper.isSeasonalMode(mode) {
                            // Check if it's a special holiday with a prominent message
                            if mode == "xmas" || mode == "newYearEve" || mode == "newYearDay" {
                                // Global holidays: show message prominently
                                Text(context.state.message ?? context.state.lessonName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            } else {
                                // Seasonal breaks: show holiday title
                                Text(SeasonalIconHelper.holidayTitle(for: context.state.season))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        } else if context.state.isBreak {
                            Text("Szünet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            if let nextLessonName = context.state.nextLessonName {
                                Text("Következő: \(nextLessonName)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        } else {
                            if let lessonNumber = context.state.lessonNumber {
                                Text("\(lessonNumber). óra")
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
                            Text("Kezdés: \(timeString)")
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
                                Text("Kezdés: \(context.state.formattedNextStartTime)")
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
                            Text("Első órád:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(context.state.lessonName)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        
                        if let roomName = context.state.roomName {
                            HStack(spacing: 4) {
                                Text("Terem:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text(roomName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if let teacherName = context.state.teacherName {
                            HStack(spacing: 4) {
                                Text("Tanár:")
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
                        if let lessonTheme = context.state.lessonTheme, !lessonTheme.isEmpty {
                            HStack {
                                Text("Téma:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text(lessonTheme)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }

                        if context.state.isSubstitution ?? false {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12))
                                Text("Helyettesítés")
                                    .font(.system(size: 12, weight: .semibold))
                                if let substituteTeacher = context.state.substituteTeacher {
                                    Text("(\(substituteTeacher))")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(.orange)
                        }

                        if context.state.isCancelled ?? false {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 12))
                                Text("Elmaradt óra")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let nextRoomName = context.state.nextRoomName {
                    HStack {
                        Image(systemName: "door.left.hand.closed")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("Következő terem: \(nextRoomName)")
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
                            Text("Első óra kezdése")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            
                            if context.state.endTime > context.state.currentTime {
                                Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            } else {
                                Text(context.state.formattedEndTime)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                    .monospacedDigit()
                            }
                        } else if mode3 == "seasonalBreak" {
                            Text("Szünetből hátralévő idő")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            Text(context.state.seasonalDisplayValue)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .monospacedDigit()
                        } else {
                            let labelText: String = {
                                if mode3 == "newYearEve" {
                                    return "Új év"
                                } else if mode3 == "beforeSchool" {
                                    return "Első óra kezdése"
                                } else if context.state.isBreak {
                                    return "Szünet vége"
                                } else {
                                    return "Óra vége"
                                }
                            }()
                            Text(labelText)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            Text(timerInterval: context.state.currentTime...context.state.endTime, countsDown: true)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .monospacedDigit()
                        }
                    }
                    Spacer()
                }
            }
            .padding(16)
        }
    }
}