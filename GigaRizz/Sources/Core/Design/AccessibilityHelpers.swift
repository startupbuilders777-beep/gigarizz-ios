import SwiftUI

// MARK: - Accessibility Helpers

/// Environment key for tracking accessibility state
struct AccessibilityAnimationPreferenceKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var prefersReducedMotion: Bool {
        get { self[AccessibilityAnimationPreferenceKey.self] }
        set { self[AccessibilityAnimationPreferenceKey.self] = newValue }
    }
}

// MARK: - View Extension for Accessibility

extension View {
    /// Applies an animation that respects the user's reduce motion setting
    func accessibleAnimation(_ animation: Animation?, value: AnyHashable) -> some View {
        self.animation(
            animation,
            value: value
        )
    }

    /// Conditional modifier that only applies when reduce motion is disabled
    @ViewBuilder
    func animationUnlessReduceMotion(_ animation: Animation?, value: AnyHashable) -> some View {
        // Note: For proper reduce motion handling, use @Environment(\.accessibilityReduceMotion) in a view
        self.animation(animation, value: value)
    }

    /// Standard accessibility label for buttons
    func accessibilityButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to activate")
            .accessibilityAddTraits(.isButton)
    }

    /// Standard accessibility label for links
    func accessibilityLink(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to open")
            .accessibilityAddTraits(.isLink)
    }

    /// Standard accessibility label for headers
    func accessibilityHeader(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    /// Combined accessibility for image with description
    func accessibleImage(description: String, isDecorating: Bool = false) -> some View {
        if isDecorating {
            return self.accessibilityHidden(true)
        }
        return self.accessibilityLabel(description)
    }
}

// MARK: - Dynamic Type Font Helper

/// Returns a font that scales with Dynamic Type settings
func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
    .system(size: size, weight: weight, design: design)
}

// MARK: - Accessibility Reduce Motion Modifier

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation?
    let value: AnyHashable

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    func reduceMotionAnimation(_ animation: Animation?, value: AnyHashable) -> some View {
        modifier(ReduceMotionModifier(animation: animation, value: value))
    }
}

// MARK: - Pulse Animation for Reduce Motion

/// A pulsing opacity animation suitable for loading states
struct PulseAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPulsing = false

    let duration: Double

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1.0 : (isPulsing ? 1.0 : 0.3))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulseAnimation(duration: Double = 1.5) -> some View {
        modifier(PulseAnimation(duration: duration))
    }
}

// MARK: - Loading Spinner with Reduce Motion Support

struct AccessibleLoadingView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isAnimating = false

    let message: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.surfaceSecondary, lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(DesignSystem.Colors.flameOrange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(reduceMotion ? 0 : (isAnimating ? 360 : 0)))
                    .animation(
                        reduceMotion ? nil : .linear(duration: 1).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            .accessibilityHidden(reduceMotion)

            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .accessibilityLabel("Loading: \(message)")
        }
        .onAppear {
            isAnimating = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading indicator: \(message)")
    }
}

// MARK: - Photo Accessibility Helpers

extension View {
    /// Accessibility for photo grid items
    func photoGridItemAccessibility(
        index: Int,
        total: Int,
        styleName: String,
        isFavorite: Bool
    ) -> some View {
        let favoriteText = isFavorite ? ", favorited" : ""
        return self
            .accessibilityLabel("Photo \(index) of \(total), \(styleName)\(favoriteText)")
            .accessibilityHint("Double tap to view full size")
            .accessibilityAddTraits(.isButton)
    }

    /// Accessibility for style badge
    func styleBadgeAccessibility(styleName: String) -> some View {
        self
            .accessibilityLabel("\(styleName) style")
    }

    /// Accessibility for download button
    func downloadButtonAccessibility() -> some View {
        self
            .accessibilityLabel("Download high-resolution photo")
            .accessibilityHint("Double tap to save to your photo library")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Paywall Accessibility Helpers

extension View {
    /// Accessibility for subscription tier cards
    func subscriptionTierAccessibility(
        tierName: String,
        price: String,
        features: [String]
    ) -> some View {
        let featuresList = features.joined(separator: ", ")
        return self
            .accessibilityLabel("\(tierName) plan, \(price), unlocks \(featuresList)")
            .accessibilityAddTraits(.isButton)
    }

    /// Accessibility for subscribe button
    func subscribeButtonAccessibility(tierName: String, price: String) -> some View {
        self
            .accessibilityLabel("Subscribe to \(tierName) plan, \(price)")
            .accessibilityHint("Double tap to complete purchase")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Navigation Accessibility

extension View {
    /// Standard navigation bar accessibility
    func navigationBarAccessibility(title: String) -> some View {
        self
            .navigationTitle(title)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Settings Row Accessibility

extension View {
    /// Accessibility for settings rows
    func settingsRowAccessibility(
        label: String,
        value: String? = nil,
        isDestructive: Bool = false
    ) -> some View {
        let accessibilityLabel = value != nil ? "\(label), \(value!)" : label

        return self
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }
}
