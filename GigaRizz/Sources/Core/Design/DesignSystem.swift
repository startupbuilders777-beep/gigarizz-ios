import SwiftUI

// MARK: - Design System

enum DesignSystem {
    // MARK: - Colors

    enum Colors {
        static let flameOrange = Color(hex: "FF6B35")
        static let deepNight = Color(hex: "1A1A2E")
        static let background = Color(hex: "0D0D14")
        static let goldAccent = Color(hex: "FFE66D")
        static let surface = Color(hex: "1A1A2E")
        static let surfaceSecondary = Color(hex: "252540")
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "A0A0B0")
        static let success = Color(hex: "00C853")
        static let warning = Color(hex: "FFB300")
        static let error = Color(hex: "FF3D71")
        static let tinder = Color(hex: "FE3C44")
        static let hinge = Color(hex: "B4A48A")
        static let bumble = Color(hex: "FFE800")
        static let overlay = Color.black.opacity(0.5)
        static let divider = Color.white.opacity(0.08)
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
        static let headline = Font.system(size: 24, weight: .bold, design: .default)
        static let title = Font.system(size: 20, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .medium, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let button = Font.system(size: 17, weight: .semibold, design: .default)
        static let smallButton = Font.system(size: 14, weight: .medium, design: .default)
        static let scoreDisplay = Font.system(size: 48, weight: .bold, design: .default)
        static let scoreLarge = Font.system(size: 72, weight: .bold, design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        static let micro: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let card: CGFloat = 20
        static let button: CGFloat = 14
        static let chip: CGFloat = 8
    }

    // MARK: - Shadows

    enum Shadow {
        static let card = ShadowStyle(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        static let elevated = ShadowStyle(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    }

    // MARK: - Animation

    enum Animation {
        static let cardSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let quickSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.2)
        static let smoothSpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
    }

    // MARK: - Haptics

    @MainActor
    enum Haptics {
        static func light() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare(); generator.impactOccurred()
        }
        static func medium() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare(); generator.impactOccurred()
        }
        static func heavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare(); generator.impactOccurred()
        }
        static func success() {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare(); generator.notificationOccurred(.success)
        }
        static func warning() {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare(); generator.notificationOccurred(.warning)
        }
        static func error() {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare(); generator.notificationOccurred(.error)
        }
    }
}

struct ShadowStyle {
    let color: Color; let radius: CGFloat; let x: CGFloat; let y: CGFloat
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension View {
    func cardShadow() -> some View {
        shadow(color: DesignSystem.Shadow.card.color, radius: DesignSystem.Shadow.card.radius,
               x: DesignSystem.Shadow.card.x, y: DesignSystem.Shadow.card.y)
    }
    func elevatedShadow() -> some View {
        shadow(color: DesignSystem.Shadow.elevated.color, radius: DesignSystem.Shadow.elevated.radius,
               x: DesignSystem.Shadow.elevated.x, y: DesignSystem.Shadow.elevated.y)
    }
}
