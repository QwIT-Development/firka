import SwiftUI

struct WidgetColors: Codable {
    let background: Int
    let textPrimary: Int
    let textSecondary: Int
    let textTertiary: Int
    let card: Int
    let accent: Int
    let grade5: Int
    let grade4: Int
    let grade3: Int
    let grade2: Int
    let grade1: Int

    func color(from argb: Int) -> Color {
        let alpha = Double((argb >> 24) & 0xFF) / 255.0
        let red = Double((argb >> 16) & 0xFF) / 255.0
        let green = Double((argb >> 8) & 0xFF) / 255.0
        let blue = Double(argb & 0xFF) / 255.0
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    var backgroundColor: Color { color(from: background) }
    var textPrimaryColor: Color { color(from: textPrimary) }
    var textSecondaryColor: Color { color(from: textSecondary) }
    var textTertiaryColor: Color { color(from: textTertiary) }
    var cardColor: Color { color(from: card) }
    var accentColor: Color { color(from: accent) }
}
