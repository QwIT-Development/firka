import SwiftUI
import WidgetKit

enum WidgetStyleType: String, Codable, CaseIterable {
    case liquidGlass = "liquid_glass"
    case appTheme = "app_theme"

    var displayName: String {
        switch self {
        case .liquidGlass: return "Liquid Glass"
        case .appTheme: return "App Theme"
        }
    }
}

struct WidgetBackground: View {
    let style: WidgetStyleType
    let colors: WidgetColors?

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch style {
        case .liquidGlass:
            if #available(iOS 26.0, *) {
                Color.clear
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
        case .appTheme:
            if let colors = colors {
                Rectangle()
                    .fill(colors.backgroundColor)
            } else {
                Rectangle()
                    .fill(Color(.systemBackground))
            }
        }
    }
}

struct WidgetTextStyle: ViewModifier {
    let style: WidgetStyleType
    let colors: WidgetColors?
    let isPrimary: Bool

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetRenderingMode) var renderingMode

    func body(content: Content) -> some View {
        switch style {
        case .liquidGlass:
            if renderingMode == .accented {
                content
            } else {
                content.foregroundStyle(isPrimary ?
                    (colorScheme == .dark ? .white : .black) :
                    (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)))
            }
        case .appTheme:
            if let colors = colors {
                content.foregroundStyle(isPrimary ? colors.textPrimaryColor : colors.textSecondaryColor)
            } else {
                content.foregroundStyle(isPrimary ? .primary : .secondary)
            }
        }
    }
}

extension View {
    func widgetTextStyle(_ style: WidgetStyleType, colors: WidgetColors?, isPrimary: Bool = true) -> some View {
        modifier(WidgetTextStyle(style: style, colors: colors, isPrimary: isPrimary))
    }
}

struct GlowEffect: ViewModifier {
    let isActive: Bool
    let color: Color

    func body(content: Content) -> some View {
        if isActive {
            content
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        } else {
            content
        }
    }
}

extension View {
    func currentLessonGlow(isActive: Bool, color: Color = .green) -> some View {
        modifier(GlowEffect(isActive: isActive, color: color))
    }
}
