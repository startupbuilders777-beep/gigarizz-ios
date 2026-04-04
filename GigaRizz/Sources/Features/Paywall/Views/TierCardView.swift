import SwiftUI

// MARK: - Tier Card View

/// Individual subscription tier card with pricing, features, and CTA.
struct TierCardView: View {
    let tier: TierOption
    let isSelected: Bool
    let animationIndex: Int
    let currentAnimationIndex: Int
    let onSelect: () -> Void
    /// Optional introductory offer string (e.g. "$2.49/mo first month")
    var introPrice: String?

    @State private var badgeScale: CGFloat = 0

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: DesignSystem.Spacing.small) {
                // Badge (if applicable)
                if let badgeText = tier.badgeText, let badgeStyle = tier.badgeStyle {
                    PremiumBadge(text: badgeText, style: badgeStyle)
                        .scaleEffect(badgeScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                badgeScale = 1
                            }
                        }
                }

                // Tier name
                Text(tier.displayName)
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(tierForegroundColor)

                // Price
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text(tier.price)
                            .font(.system(size: tier == .free ? 20 : 28, weight: .bold))
                            .strikethrough(introPrice != nil, color: DesignSystem.Colors.textSecondary)
                        if !tier.period.isEmpty {
                            Text(tier.period)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .foregroundStyle(introPrice != nil ? DesignSystem.Colors.textSecondary : tierForegroundColor)

                    // Intro offer price
                    if let introPrice {
                        Text(introPrice)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.success)
                        Text("first period")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.success.opacity(0.8))
                    }
                }

                // Features list
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(tier.features) { feature in
                        featureRow(feature)
                    }
                }
                .padding(.top, DesignSystem.Spacing.small)

                // CTA button (only for Plus and Gold)
                if tier != .free {
                    ctaButton
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(.plain)
        .disabled(tier == .free)
        .offset(y: animationIndex <= currentAnimationIndex ? 0 : 20)
        .opacity(animationIndex <= currentAnimationIndex ? 1 : 0)
    }

    // MARK: - Feature Row

    private func featureRow(_ feature: TierFeature) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: feature.included ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 14))
                .foregroundStyle(feature.included ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textSecondary.opacity(0.5))

            Text(feature.text)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(feature.included ? tierForegroundColor : DesignSystem.Colors.textSecondary.opacity(0.5))

            Spacer()
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
            Text(isSelected ? "Selected" : "Select")
                .font(DesignSystem.Typography.smallButton)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(ctaBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
    }

    // MARK: - Style Computed Properties

    private var tierForegroundColor: Color {
        switch tier {
        case .free:
            DesignSystem.Colors.textSecondary
        case .plus:
            isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary
        case .gold:
            DesignSystem.Colors.goldAccent
        }
    }

    private var borderColor: Color {
        switch tier {
        case .free:
            DesignSystem.Colors.divider
        case .plus:
            DesignSystem.Colors.flameOrange
        case .gold:
            .clear
        }
    }

    private var borderWidth: Double {
        switch tier {
        case .free: 1
        case .plus: 2
        case .gold: 0
        }
    }

    // Use Color for all backgrounds to avoid type mismatch
    private var cardBackgroundColor: Color {
        switch tier {
        case .free:
            DesignSystem.Colors.surface.opacity(0.3)
        case .plus:
            isSelected ? DesignSystem.Colors.flameOrange.opacity(0.1) : DesignSystem.Colors.surface
        case .gold:
            DesignSystem.Colors.deepNight.opacity(0.8)
        }
    }

    private var ctaBackgroundColor: Color {
        switch tier {
        case .plus:
            DesignSystem.Colors.flameOrange
        case .gold:
            DesignSystem.Colors.goldAccent
        default:
            DesignSystem.Colors.flameOrange
        }
    }
}

// MARK: - Preview

#Preview("TierCards") {
    HStack(spacing: DesignSystem.Spacing.small) {
        ForEach(Array(TierOption.allCases.enumerated()), id: \.element.id) { index, tier in
            TierCardView(
                tier: tier,
                isSelected: tier == .plus,
                animationIndex: index,
                currentAnimationIndex: 2,
                onSelect: {},
                introPrice: tier == .plus ? "$2.49/mo" : nil
            )
        }
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}