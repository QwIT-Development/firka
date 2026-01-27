import Foundation
import SwiftUI

extension SubjectAverage {
    var averageColor: Color {
        switch average {
        case 4.5...: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }

    var formattedAverage: String {
        String(format: "%.2f", average)
    }
}
