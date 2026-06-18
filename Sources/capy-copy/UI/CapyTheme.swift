import SwiftUI
import AppKit

/// User-selectable app themes.
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case liquidGlass = "liquidGlass"
    case terminal = "terminal"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .liquidGlass:
            return NSLocalizedString("theme.liquidGlass", bundle: .module, comment: "")
        case .terminal:
            return NSLocalizedString("theme.terminal", bundle: .module, comment: "")
        }
    }
}

/// Theme-aware styling for Capy Copy.
struct ThemeDefinition {
    let name: AppTheme

    // MARK: - Backgrounds

    var windowBackground: Color {
        switch name {
        case .liquidGlass:
            return Color.clear
        case .terminal:
            return Color(hex: "#0d0d0d")
        }
    }

    var windowMaterial: NSVisualEffectView.Material {
        switch name {
        case .liquidGlass:
            return .popover
        case .terminal:
            return .contentBackground
        }
    }

    var cardBackgroundColor: Color {
        switch name {
        case .liquidGlass:
            return Color(nsColor: .controlBackgroundColor).opacity(0.55)
        case .terminal:
            return Color(hex: "#141414")
        }
    }

    var cardBackgroundMaterial: NSVisualEffectView.Material? {
        switch name {
        case .liquidGlass:
            return .popover
        default:
            return nil
        }
    }

    var searchBackgroundColor: Color {
        switch name {
        case .liquidGlass:
            return Color(nsColor: .textBackgroundColor).opacity(0.7)
        case .terminal:
            return Color(hex: "#1a1a1a")
        }
    }

    // MARK: - Text

    var primaryTextColor: Color {
        switch name {
        case .liquidGlass:
            return Color(nsColor: .labelColor)
        case .terminal:
            return Color(hex: "#e6e6e6")
        }
    }

    var secondaryTextColor: Color {
        switch name {
        case .liquidGlass:
            return Color(nsColor: .secondaryLabelColor)
        case .terminal:
            return Color(hex: "#8a9a8a")
        }
    }

    var tertiaryTextColor: Color {
        switch name {
        case .liquidGlass:
            return Color(nsColor: .tertiaryLabelColor)
        case .terminal:
            return Color(hex: "#5a6a5a")
        }
    }

    // MARK: - Accents

    var accentColor: Color {
        switch name {
        case .liquidGlass:
            return Color(nsColor: .controlAccentColor)
        case .terminal:
            return Color(hex: "#33ff00")
        }
    }

    var dividerColor: Color {
        switch name {
        case .liquidGlass:
            return Color(nsColor: .separatorColor)
        case .terminal:
            return Color(hex: "#2a2a2a")
        }
    }

    // MARK: - Fonts

    var bodyFont: Font {
        switch name {
        case .liquidGlass:
            return .system(size: 15, weight: .regular)
        case .terminal:
            return Font.custom("Iosevka", size: 15)
                .monospaced()
        }
    }

    var captionFont: Font {
        switch name {
        case .liquidGlass:
            return .system(size: 13, weight: .medium)
        case .terminal:
            return Font.custom("Iosevka", size: 13)
                .monospaced()
        }
    }

    var headlineFont: Font {
        switch name {
        case .liquidGlass:
            return .system(size: 17, weight: .semibold)
        case .terminal:
            return Font.custom("Iosevka", size: 17)
                .monospaced()
        }
    }

    // MARK: - Shapes

    var panelCornerRadius: CGFloat {
        switch name {
        case .liquidGlass:
            return 24
        case .terminal:
            return 8
        }
    }

    var cardCornerRadius: CGFloat {
        switch name {
        case .liquidGlass:
            return 16
        case .terminal:
            return 6
        }
    }

    var buttonCornerRadius: CGFloat {
        switch name {
        case .liquidGlass:
            return 8
        case .terminal:
            return 4
        }
    }

    var tabButtonCornerRadius: CGFloat {
        switch name {
        case .liquidGlass:
            return 14
        case .terminal:
            return 6
        }
    }

    var searchCornerRadius: CGFloat {
        switch name {
        case .liquidGlass:
            return 18
        case .terminal:
            return 6
        }
    }

    var shadowColor: Color {
        switch name {
        case .liquidGlass:
            return Color.black.opacity(0.35)
        case .terminal:
            return Color.black.opacity(0.5)
        }
    }

    var shadowRadius: CGFloat {
        switch name {
        case .liquidGlass:
            return 40
        case .terminal:
            return 12
        }
    }

    var borderColor: Color {
        switch name {
        case .liquidGlass:
            return Color.white.opacity(0.12)
        case .terminal:
            return Color(hex: "#2a2a2a")
        }
    }

    var borderWidth: CGFloat {
        switch name {
        case .liquidGlass:
            return 0.5
        case .terminal:
            return 1
        }
    }
}

extension AppTheme {
    var definition: ThemeDefinition {
        ThemeDefinition(name: self)
    }
}

extension SwiftUI.Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let alpha: UInt64
        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch cleaned.count {
        case 3:
            alpha = 255
            red = (int >> 8) * 17
            green = (int >> 4 & 0xF) * 17
            blue = (int & 0xF) * 17
        case 6:
            alpha = 255
            red = int >> 16
            green = int >> 8 & 0xFF
            blue = int & 0xFF
        case 8:
            alpha = int >> 24
            red = int >> 16 & 0xFF
            green = int >> 8 & 0xFF
            blue = int & 0xFF
        default:
            alpha = 255
            red = 0
            green = 0
            blue = 0
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
