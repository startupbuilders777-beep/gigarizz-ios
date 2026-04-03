import SwiftUI

// MARK: - Scaled Typography (Dynamic Type Scalable)

/// Returns a scaled version of the design system typography
enum ScaledTypography {
    /// Large title that scales with Dynamic Type
    static let largeTitle = Font.largeTitle.weight(.bold)

    /// Headline that scales with Dynamic Type
    static let headline = Font.headline.weight(.bold)

    /// Title that scales with Dynamic Type
    static let title = Font.title2.weight(.semibold)

    /// Body that scales with Dynamic Type
    static let body = Font.body

    /// Callout that scales with Dynamic Type
    static let callout = Font.callout.weight(.medium)

    /// Subheadline that scales with Dynamic Type
    static let subheadline = Font.subheadline

    /// Footnote that scales with Dynamic Type
    static let footnote = Font.footnote

    /// Caption that scales with Dynamic Type
    static let caption = Font.caption.weight(.medium)

    /// Button text that scales with Dynamic Type
    static let button = Font.body.weight(.semibold)

    /// Small button text that scales with Dynamic Type
    static let smallButton = Font.subheadline.weight(.medium)
}

// MARK: - Design System

enum DesignSystem {
    // MARK: - Colors

    enum Colors {
        /// Flame Orange — warm, confident, flirty. Primary brand color.
        static let flameOrange = Color(hex: "FF6B35")

        /// Deep Night — premium dark UI background.
        static let deepNight = Color(hex: "1A1A2E")

        /// Near Black — primary background.
        static let background = Color(hex: "0D0D14")

        /// Gold Star — achievement, premium rewards accent.
        static let goldAccent = Color(hex: "FFE66D")

        /// Surface — elevated card backgrounds.
        static let surface = Color(hex: "1A1A2E")

        /// Secondary surface — slightly elevated.
        static let surfaceSecondary = Color(hex: "252540")

        /// Primary text — white on dark.
        static let textPrimary = Color.white

        /// Secondary text — muted on dark.
        static let textSecondary = Color(hex: "A0A0B0")

        /// Rizz Green — new matches, success states.
        static let success = Color(hex: "00C853")

        /// Caution Gold — warning states.
        static let warning = Color(hex: "FFB300")

        /// Alert Red — error, destructive states.
        static let error = Color(hex: "FF3D71")

        /// Tinder red accent.
        static let tinder = Color(hex: "FE3C44")

        /// Hinge beige accent.
        static let hinge = Color(hex: "B4A48A")

        /// Bumble yellow accent.
        static let bumble = Color(hex: "FFE800")

        /// Overlay — semi-transparent black for dimming.
        static let overlay = Color.black.opacity(0.5)

        /// Divider line color.
        static let divider = Color.white.opacity(0.08)
    }

    // MARK: - Typography (Dynamic Type Scalable)

    enum Typography {
        /// Large headline — scales with Dynamic Type.
        static let largeTitle = ScaledTypography.largeTitle

        /// Headline — scales with Dynamic Type.
        static let headline = ScaledTypography.headline

        /// Title — scales with Dynamic Type.
        static let title = ScaledTypography.title

        /// Body — scales with Dynamic Type.
        static let body = ScaledTypography.body

        /// Callout — scales with Dynamic Type.
        static let callout = ScaledTypography.callout

        /// Subheadline — scales with Dynamic Type.
        static let subheadline = ScaledTypography.subheadline

        /// Footnote — scales with Dynamic Type.
        static let footnote = ScaledTypography.footnote

        /// Caption — scales with Dynamic Type.
        static let caption = ScaledTypography.caption

        /// Button text — scales with Dynamic Type.
        static let button = ScaledTypography.button

        /// Small button text — scales with Dynamic Type.
        static let smallButton = ScaledTypography.smallButton

        /// Score display — SF Pro Display Bold 48pt for Rizz Score.
        static let scoreDisplay = Font.system(size: 48, weight: .bold, design: .default)

        /// Large score — SF Pro Display Bold 72pt.
        static let scoreLarge = Font.system(size: 72, weight: .bold, design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        /// 4pt micro spacing.
        static let micro: CGFloat = 4
        /// 8pt extra small.
        static let xs: CGFloat = 8
        /// 12pt small.
        static let small: CGFloat = 12
        /// 16pt medium.
        static let medium: CGFloat = 16
        /// 24pt large.
        static let large: CGFloat = 24
        /// 32pt extra large.
        static let xl: CGFloat = 32
        /// 48pt extra extra large.
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
        static let card = ShadowStyle(color: .black.opacity(0.2), radius: 8, shadowX: 0, shadowY: 4)
        static let elevated = ShadowStyle(color: .black.opacity(0.3), radius: 16, shadowX: 0, shadowY: 8)
    }

    // MARK: - Animation (Reduce Motion Aware)

    enum Animation {
        static let cardSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let quickSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.2)
        static let smoothSpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)

        /// Returns the animation, or nil if reduce motion is enabled
        static func adaptiveAnimation(reduceMotion: Bool) -> SwiftUI.Animation? {
            reduceMotion ? nil : cardSpring
        }
    }

    // MARK: - Haptics

    /// Haptic feedback namespace — delegates to centralized HapticManager.
    /// Use HapticManager.shared or HapticManager static methods directly for full functionality.
    enum Haptics {
        /// Light haptic for subtle button taps.
        static func light() {
            HapticManager.light()
        }

        /// Medium haptic for card swipes and snaps.
        static func medium() {
            HapticManager.medium()
        }

        /// Heavy haptic for significant actions.
        static func heavy() {
            HapticManager.heavy()
        }

        /// Success notification for completed actions.
        static func success() {
            HapticManager.success()
        }

        /// Warning notification for cautionary states.
        static func warning() {
            HapticManager.warning()
        }

        /// Error notification for failed operations.
        static func error() {
            HapticManager.error()
        }

        /// Soft haptic for gentle interactions.
        static func soft() {
            HapticManager.soft()
        }

        /// Selection haptic for pickers and segment controls.
        static func selection() {
            HapticManager.selection()
        }
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3:
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
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

// MARK: - View Extension for Shadows

extension View {
    func cardShadow() -> some View {
        shadow(
            color: DesignSystem.Shadow.card.color,
            radius: DesignSystem.Shadow.card.radius,
            x: DesignSystem.Shadow.card.shadowX,
            y: DesignSystem.Shadow.card.shadowY
        )
    }

    func elevatedShadow() -> some View {
        shadow(
            color: DesignSystem.Shadow.elevated.color,
            radius: DesignSystem.Shadow.elevated.radius,
            x: DesignSystem.Shadow.elevated.shadowX,
            y: DesignSystem.Shadow.elevated.shadowY
        )
    }
}
