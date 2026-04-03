import SwiftUI

// MARK: - GRButton

/// Reusable button component with primary, secondary, and outline styles.
struct GRButton: View {
    enum Style {
        case primary, secondary, outline
    }

    let title: String
    var icon: String?
    var style: Style = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var accessibilityHint: String?
    let action: () -> Void

    var body: some View {
        Button(action: action, label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(DesignSystem.Typography.button)
                    }
                    Text(title)
                        .font(DesignSystem.Typography.button)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(textColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            .overlay {
                if style == .outline {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .strokeBorder(DesignSystem.Colors.flameOrange, lineWidth: 1.5)
                }
            }
        })
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
        .buttonStyle(HapticButtonStyle(hapticStyle: .light))
        .allowsHitTesting(!isDisabled && !isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint ?? "Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: DesignSystem.Colors.flameOrange
        case .secondary: DesignSystem.Colors.surfaceSecondary
        case .outline: .clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: .white
        case .secondary: DesignSystem.Colors.textPrimary
        case .outline: DesignSystem.Colors.flameOrange
        }
    }
}

// MARK: - GRCard

/// Elevated card container with design system styling.
struct GRCard<Content: View>: View {
    var padding: CGFloat = DesignSystem.Spacing.medium
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .cardShadow()
    }
}

// MARK: - ShimmerView

/// Animated loading skeleton placeholder.
struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    DesignSystem.Colors.surfaceSecondary.opacity(0.4),
                    DesignSystem.Colors.surfaceSecondary.opacity(0.8),
                    DesignSystem.Colors.surfaceSecondary.opacity(0.4)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
            .mask(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            )
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - EmptyStateView

/// Configurable empty state with icon, messaging, and optional CTA.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var ctaTitle: String?
    var ctaAction: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.flameOrange,
                            DesignSystem.Colors.goldAccent
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let ctaTitle, let ctaAction {
                GRButton(
                    title: ctaTitle,
                    icon: "arrow.right",
                    action: ctaAction
                )
                .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - RankBadge

/// Visual rank indicator for favorites (#1, #2, #3...).
struct RankBadge: View {
    let rank: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.flameOrange)
                .frame(width: 24, height: 24)

            Text("\(rank)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .overlay(
            Circle()
                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.flameOrange.opacity(0.4), radius: 2, y: 1)
        .accessibilityLabel("Rank #\(rank)")
    }
}

// MARK: - FavoritesStatsCard

/// Small stat card for favorites header.
struct FavoritesStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)

            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Previews

#Preview("GRButton Styles") {
    VStack(spacing: 16) {
        GRButton(title: "Primary", icon: "wand.and.stars") {}
        GRButton(title: "Secondary", style: .secondary) {}
        GRButton(title: "Outline", style: .outline) {}
        GRButton(title: "Loading", isLoading: true) {}
        GRButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("GRCard") {
    GRCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Title")
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text("Card content goes here")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("ShimmerView") {
    VStack(spacing: 12) {
        ShimmerView()
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        ShimmerView()
            .frame(height: 20)
        ShimmerView()
            .frame(height: 20)
            .frame(width: 200)
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("EmptyStateView") {
    EmptyStateView(
        icon: "wand.and.stars",
        title: "No Photos Yet",
        subtitle: "Generate your first AI dating photo to get started.",
        ctaTitle: "Generate Now"
    ) {}
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}
