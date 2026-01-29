import WidgetKit
import SwiftUI

@main
struct HomeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        TimetableWidget()
        GradesWidget()
        AveragesWidget()

        // Lock Screen Widgets (circular & rectangular)
        TimetableLockScreenWidget()
        GradesLockScreenWidget()
        AveragesLockScreenWidget()

        // Inline Widgets (above the clock)
        TimetableInlineWidget()
        GradesInlineWidget()
        AveragesInlineWidget()

        // Control Widgets (iOS 18+ Control Center & Lock Screen buttons)
        if #available(iOS 18.0, *) {
            HomeControl()
            GradesControl()
            TimetableControl()
        }
    }
}
