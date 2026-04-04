import SwiftUI

// MARK: - Paywall View

/// Full-screen paywall modal with tier selection (Free, Plus, Gold).
/// The single most important revenue-conversion surface for GigaRizz.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PaywallViewModel

    @State private var closeButtonScale: CGFloat = 1.0
    
    // MARK: - Deep Link Parameters
    
    /// Initial tier to pre-select (from deep link gigarizz://paywall?tier=plus)
    let initialTier: TierOption?
    
    /// Promo/referral code (from deep link gigarizz://paywall?promo=GRIZZ-XXXX)
    let promoCode: String?

    init(initialTier: TierOption? = nil, promoCode: String? = nil) {
        self.initialTier = initialTier
        self.promoCode = promoCode
        // Initialize ViewModel with pre-selected tier
        _viewModel = StateObject(wrappedValue: PaywallViewModel(initialTier: initialTier ?? .plus))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        // Hero illustration
                        heroSection

                        // Headline
                        headlineSection

                        // Tier cards
                        tierCardsSection

                        // Footer
                        footerSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                // Dismiss button (only if user has free photos remaining)
                if viewModel.canDismiss {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                closeButtonScale = 0.8
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(DesignSystem.Colors.surface)
                                .clipShape(Circle())
                                .scaleEffect(closeButtonScale)
                        }
                        .accessibilityLabel("Close paywall")
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Decorative flame/lens illustration
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.flameOrange.opacity(0.3),
                            DesignSystem.Colors.goldAccent.opacity(0.2),
                            .clear
                        ],
                        startPoint: .center,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)

            // Central icon
            Image(systemName: "flame.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.top, DesignSystem.Spacing.large)
        }
        .padding(.top, DesignSystem.Spacing.xxl)
    }

    // MARK: - Headline Section

    private var headlineSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("Unlock Your Best Photos")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Upgrade to Plus or Gold and never hit a wall.")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Tier Cards Section

    private var tierCardsSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Horizontal scroll for iPhone, vertical for iPad
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(Array(TierOption.allCases.enumerated()), id: \.element.id) { index, tier in
                        TierCardView(
                            tier: tier,
                            isSelected: viewModel.selectedTier == tier,
                            animationIndex: index,
                            currentAnimationIndex: viewModel.cardAnimationIndex,
                            onSelect: { viewModel.selectTier(tier) }
                        )
                        .frame(width: tierCardWidth)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.micro)
            }
            .frame(height: tierCardHeight)

            // Purchase button
            if viewModel.selectedTier != .free {
                purchaseButton
            }
        }
    }

    private var purchaseButton: some View {
        GRButton(
            title: viewModel.isLoading ? "Processing..." : "Subscribe to \(viewModel.selectedTier.displayName)",
            icon: viewModel.selectedTier == .gold ? "crown.fill" : "star.fill",
            isLoading: viewModel.isLoading,
            isDisabled: viewModel.isLoading
        ) {
            Task {
                await viewModel.purchaseSelectedTier()
            }
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Restore purchases
            Button {
                Task {
                    await viewModel.restorePurchases()
                }
            } label: {
                Text(viewModel.isRestoring ? "Restoring..." : "Restore Purchases")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .disabled(viewModel.isRestoring)

            // Terms and privacy
            HStack(spacing: DesignSystem.Spacing.medium) {
                Button {} label: {
                    Text("Terms of Service")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Button {} label: {
                    Text("Privacy Policy")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.error)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, DesignSystem.Spacing.large)
    }

    // MARK: - Layout Helpers

    private var tierCardWidth: CGFloat {
        // Full width minus 32pt margins, divided by 3 with spacing
        let screenWidth = UIScreen.main.bounds.width
        let margins = DesignSystem.Spacing.medium * 2
        let spacing = DesignSystem.Spacing.small * 2
        return (screenWidth - margins - spacing) / 3
    }

    private var tierCardHeight: CGFloat {
        // 120pt on iPhone per spec, taller for feature list
        return 280
    }
}

// MARK: - Preview

#Preview("PaywallView") {
    PaywallView()
        .preferredColorScheme(.dark)
}

#Preview("PaywallView - Light") {
    PaywallView()
        .preferredColorScheme(.light)
}