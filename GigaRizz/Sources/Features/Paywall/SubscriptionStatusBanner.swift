import SwiftUI

// MARK: - Subscription Status Banner

/// Persistent top banner showing current subscription tier, photo credits, and renewal info.
/// Slides down with spring animation when appearing.
/// Tap to expand for renewal date + upgrade CTA.
struct SubscriptionStatusBanner: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            bannerContent
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.surface)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 4)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                    DesignSystem.Haptics.light()
                }

            if isExpanded {
                expandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Collapsed Banner

    @ViewBuilder
    private var bannerContent: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            // Tier icon
            Image(systemName: tierIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tierIconColor)

            // Status text
            Text(statusText)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            // CTA or chevron
            if showCTA {
                Button {
                    DesignSystem.Haptics.medium()
                    subscriptionManager.showPaywall = true
                } label: {
                    Text(ctaText)
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
        }
        .padding(.leading, DesignSystem.Spacing.xs)
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Divider()
                .background(DesignSystem.Colors.divider)

            switch subscriptionManager.bannerState {
            case .freePhotosLeft:
                Label("Upgrade to Plus or Gold to unlock unlimited generations", systemImage: "arrow.up.circle")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

            case .freeNoPhotosLeft:
                Label("You've used all your free photos today. Upgrade to continue.", systemImage: "exclamationmark.circle")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.warning)

            case .plusActive(let renewsAt):
                Label("Renews \(renewsAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

            case .plusExpiringSoon(let days):
                Label("\(days) day\(days == 1 ? "" : "s") until renewal", systemImage: "exclamationmark.triangle")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.warning)

            case .goldActive:
                Label("You're on the best plan. Thank you! 🎉", systemImage: "star.fill")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.goldAccent)

            case .gracePeriod:
                Label("Subscription issue detected. Tap to resolve.", systemImage: "exclamationmark.octagon")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.error)
            }

            if showUpgradeButton {
                Button {
                    DesignSystem.Haptics.medium()
                    subscriptionManager.showPaywall = true
                } label: {
                    Text("Upgrade Now")
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.small)
                        .background(DesignSystem.Colors.flameOrange)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.bottom, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
    }

    // MARK: - Helpers

    private var tierIcon: String {
        switch subscriptionManager.bannerState {
        case .goldActive: return "star.fill"
        case .plusActive, .plusExpiringSoon: return "sparkles"
        case .freePhotosLeft, .freeNoPhotosLeft: return "person.fill"
        case .gracePeriod: return "exclamationmark.triangle.fill"
        }
    }

    private var tierIconColor: Color {
        switch subscriptionManager.bannerState {
        case .goldActive: return DesignSystem.Colors.goldAccent
        case .plusActive, .plusExpiringSoon: return DesignSystem.Colors.flameOrange
        case .freePhotosLeft: return DesignSystem.Colors.textSecondary
        case .freeNoPhotosLeft: return DesignSystem.Colors.warning
        case .gracePeriod: return DesignSystem.Colors.error
        }
    }

    private var accentColor: Color {
        switch subscriptionManager.bannerState {
        case .goldActive: return DesignSystem.Colors.goldAccent
        case .plusActive, .plusExpiringSoon: return DesignSystem.Colors.flameOrange
        case .freePhotosLeft, .freeNoPhotosLeft: return DesignSystem.Colors.textSecondary
        case .gracePeriod: return DesignSystem.Colors.error
        }
    }

    private var statusText: String {
        switch subscriptionManager.bannerState {
        case .freePhotosLeft(let count):
            return "Free · \(count) photo\(count == 1 ? "" : "s") left today"
        case .freeNoPhotosLeft:
            return "Daily limit reached"
        case .plusActive:
            return "Plus · Active"
        case .plusExpiringSoon(let days):
            return "Plus · Renews in \(days) day\(days == 1 ? "" : "s")"
        case .goldActive:
            return "Gold · Unlimited"
        case .gracePeriod:
            return "Subscription issue — tap to fix"
        }
    }

    private var showCTA: Bool {
        switch subscriptionManager.bannerState {
        case .freePhotosLeft, .freeNoPhotosLeft, .gracePeriod: return true
        case .plusActive, .plusExpiringSoon, .goldActive: return false
        }
    }

    private var ctaText: String {
        switch subscriptionManager.bannerState {
        case .gracePeriod: return "Fix Now"
        default: return "Upgrade"
        }
    }

    private var showUpgradeButton: Bool {
        switch subscriptionManager.bannerState {
        case .freePhotosLeft, .freeNoPhotosLeft: return true
        default: return false
        }
    }
}

// MARK: - Preview

#Preview("Free Photos Left") {
    NavigationStack {
        Color.black.ignoresSafeArea()
            .navigationTitle("Generate")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SubscriptionStatusBanner()
                        .environmentObject(SubscriptionManager.shared)
                }
            }
    }
    .preferredColorScheme(.dark)
}

#Preview("Gold Active") {
    NavigationStack {
        Color.black.ignoresSafeArea()
            .navigationTitle("Generate")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SubscriptionStatusBanner()
                        .environmentObject(SubscriptionManager.shared)
                }
            }
    }
    .preferredColorScheme(.dark)
}
