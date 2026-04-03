import SwiftUI
import UIKit

// MARK: - Haptic Manager
/// Centralized haptic feedback system for GigaRizz.
/// Uses cached generators for performance and respects reduce-motion accessibility.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private var lightGenerator: UIImpactFeedbackGenerator?
    private var mediumGenerator: UIImpactFeedbackGenerator?
    private var heavyGenerator: UIImpactFeedbackGenerator?
    private var softGenerator: UIImpactFeedbackGenerator?
    private var rigidGenerator: UIImpactFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?

    private init() {
        prepareAll()
    }

    /// Pre-warms all haptic generators for low-latency feedback.
    func prepareAll() {
        lightGenerator = UIImpactFeedbackGenerator(style: .light)
        mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        softGenerator = UIImpactFeedbackGenerator(style: .soft)
        rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
        notificationGenerator = UINotificationFeedbackGenerator()
        selectionGenerator = UISelectionFeedbackGenerator()

        lightGenerator?.prepare()
        mediumGenerator?.prepare()
        heavyGenerator?.prepare()
        softGenerator?.prepare()
        rigidGenerator?.prepare()
        notificationGenerator?.prepare()
        selectionGenerator?.prepare()
    }

    // MARK: - Impact

    /// Light tap — selection, button press, toggle
    func impactLight() {
        guard !isReduceMotionEnabled else { return }
        lightGenerator?.impactOccurred()
        lightGenerator?.prepare()
    }

    /// Medium snap — card swipe, tab switch, picker change
    func impactMedium() {
        guard !isReduceMotionEnabled else { return }
        mediumGenerator?.impactOccurred()
        mediumGenerator?.prepare()
    }

    /// Heavy thud — destructive confirm, major action commit
    func impactHeavy() {
        guard !isReduceMotionEnabled else { return }
        heavyGenerator?.impactOccurred()
        heavyGenerator?.prepare()
    }

    /// Soft spring — gentle bounce for pull-to-refresh, slider snap
    func impactSoft() {
        guard !isReduceMotionEnabled else { return }
        softGenerator?.impactOccurred()
        softGenerator?.prepare()
    }

    /// Rigid snap — precise mechanical feedback for dials, wheels
    func impactRigid() {
        guard !isReduceMotionEnabled else { return }
        rigidGenerator?.impactOccurred()
        rigidGenerator?.prepare()
    }

    /// Variable intensity impact — 0.0 to 1.0
    func impact(intensity: CGFloat) {
        guard !isReduceMotionEnabled else { return }
        let clamped = max(0, min(1, intensity))
        lightGenerator?.impactOccurred(intensity: clamped)
        lightGenerator?.prepare()
    }

    // MARK: - Notification

    /// Success — photo generated, action completed, subscription activated
    func notificationSuccess() {
        guard !isReduceMotionEnabled else { return }
        notificationGenerator?.notificationOccurred(.success)
        notificationGenerator?.prepare()
    }

    /// Warning — photo limit reached, free tier restriction, streak at risk
    func notificationWarning() {
        guard !isReduceMotionEnabled else { return }
        notificationGenerator?.notificationOccurred(.warning)
        notificationGenerator?.prepare()
    }

    /// Error — generation failed, network error, purchase failed
    func notificationError() {
        guard !isReduceMotionEnabled else { return }
        notificationGenerator?.notificationOccurred(.error)
        notificationGenerator?.prepare()
    }

    // MARK: - Selection

    /// Selection change — scrolling through photo styles, picker, carousel
    func selectionChanged() {
        guard !isReduceMotionEnabled else { return }
        selectionGenerator?.selectionChanged()
        selectionGenerator?.prepare()
    }

    // MARK: - Accessibility

    private var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}

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
        static let card = ShadowStyle(color: .black.opacity(0.2), radius: 8, offsetX: 0, offsetY: 4)
        static let elevated = ShadowStyle(color: .black.opacity(0.3), radius: 16, offsetX: 0, offsetY: 8)
    }

    // MARK: - Animation

    enum Animation {
        static let cardSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let quickSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.2)
        static let smoothSpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
    }

    // MARK: - Haptics

    /// Delegates to the centralized HapticManager.
    /// Call site remains unchanged — all existing DesignSystem.Haptics.* calls work as-is.
    @MainActor
    enum Haptics {
        /// Light tap — button press, toggle, selection
        static func light() { HapticManager.shared.impactLight() }

        /// Medium snap — card swipe, tab switch, picker change
        static func medium() { HapticManager.shared.impactMedium() }

        /// Heavy thud — destructive confirm, major action commit
        static func heavy() { HapticManager.shared.impactHeavy() }

        /// Soft spring — gentle bounce for pull-to-refresh, slider snap
        static func soft() { HapticManager.shared.impactSoft() }

        /// Rigid snap — precise mechanical feedback for dials, wheels
        static func rigid() { HapticManager.shared.impactRigid() }

        /// Success — photo generated, action completed, subscription activated
        static func success() { HapticManager.shared.notificationSuccess() }

        /// Warning — photo limit reached, free tier restriction, streak at risk
        static func warning() { HapticManager.shared.notificationWarning() }

        /// Error — generation failed, network error, purchase failed
        static func error() { HapticManager.shared.notificationError() }

        /// Selection change — scrolling through photo styles, picker, carousel
        static func selection() { HapticManager.shared.selectionChanged() }

        /// Variable intensity impact — intensity from 0.0 to 1.0
        static func impact(intensity: CGFloat) { HapticManager.shared.impact(intensity: intensity) }
    }
}

struct ShadowStyle {
    let color: Color; let radius: CGFloat; let offsetX: CGFloat; let offsetY: CGFloat
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3:  (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: Double(alpha) / 255)
    }
}

extension View {
    func cardShadow() -> some View {
        shadow(color: DesignSystem.Shadow.card.color, radius: DesignSystem.Shadow.card.radius,
               x: DesignSystem.Shadow.card.offsetX, y: DesignSystem.Shadow.card.offsetY)
    }
    func elevatedShadow() -> some View {
        shadow(color: DesignSystem.Shadow.elevated.color, radius: DesignSystem.Shadow.elevated.radius,
               x: DesignSystem.Shadow.elevated.offsetX, y: DesignSystem.Shadow.elevated.offsetY)
    }
}
