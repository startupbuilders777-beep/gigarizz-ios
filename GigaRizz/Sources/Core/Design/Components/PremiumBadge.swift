import SwiftUI

// MARK: - Premium Badge

/// Badge component for tier cards displaying "MOST POPULAR" or "BEST VALUE".
struct PremiumBadge: View {
    let text: String
    var style: BadgeStyle = .popular

    enum BadgeStyle {
        case popular
        case bestValue
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: style == .popular ? "star.fill" : "crown.fill")
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(style == .popular ? DesignSystem.Colors.goldAccent : .white)
        .padding(.horizontal, DesignSystem.Spacing.small)
        .padding(.vertical, DesignSystem.Spacing.micro)
        .background(
            Capsule()
                .fill(badgeBackgroundColor)
        )
    }

    private var badgeBackgroundColor: Color {
        switch style {
        case .popular:
            DesignSystem.Colors.goldAccent.opacity(0.2)
        case .bestValue:
            DesignSystem.Colors.goldAccent
        }
    }
}

// MARK: - Preview

#Preview("PremiumBadge") {
    VStack(spacing: 16) {
        PremiumBadge(text: "MOST POPULAR", style: .popular)
        PremiumBadge(text: "BEST VALUE", style: .bestValue)
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}