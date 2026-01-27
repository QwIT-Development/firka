import WidgetKit
import SwiftUI

@main
struct HomeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TimetableWidget()
        GradesWidget()
        AveragesWidget()
    }
}
