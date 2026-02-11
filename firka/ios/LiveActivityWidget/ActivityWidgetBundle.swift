import WidgetKit
import SwiftUI

@main
struct TimetableWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 18.0, *) {
            TimetableLiveActivity()
        }

        if #available(iOS 16.2, *),
           !ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 18, minorVersion: 0, patchVersion: 0)
           ) {
            TimetableLiveActivityLegacy()
        }
    }
}
