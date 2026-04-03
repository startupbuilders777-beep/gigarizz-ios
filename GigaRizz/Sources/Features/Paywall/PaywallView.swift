import SwiftUI

// MARK: - Paywall View

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedPlan: PlanOption = .monthly
    @State private var isRestoring = false
    @State private var showCheckmark = false
    @State private var pulseGlow = false
    @State private var statsVisible = false
    @Environment(\.dismiss) private var dismiss

    enum PlanOption: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case lifetime = "Lifetime"

        var price: String {
            switch self {
            case .weekly: return "$4.99"
            case .monthly: return "$9.99"
            case .lifetime: return "$49.99"
            }
        }

        var period: String {
            switch self {
            case .weekly: return "/week"
            case .monthly: return "/month"
            case .lifetime: return "one-time"
            }
        }

        var perDay: String {
            switch self {
            case .weekly: return "$0.71/day"
            case .monthly: return "$0.33/day"
            case .lifetime: return "forever"
            }
        }

        var savings: String? {
            switch self {
            case .weekly: return nil
            case .monthly: return "MOST POPULAR"
            case .lifetime: return "BEST VALUE"
            }
        }

        var badgeColor: Color {
            switch self {
            case .weekly: return .clear
            case .monthly: return DesignSystem.Colors.flameOrange
            case .lifetime: return DesignSystem.Colors.goldAccent
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        heroSection
                        socialProofBanner
                        featuresSection
                        planSelection
                        ctaSection
                        guaranteeSection
                        footerSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .font(.system(size: 22))
                    }
                }
            }
            .onAppear {
                withAnimation(DesignSystem.Animation.smoothSpring.delay(0.5)) {
                    statsVisible = true
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // Before / After comparison
            HStack(spacing: DesignSystem.Spacing.m) {
                // Before
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(DesignSystem.Colors.surfaceSecondary)
                            .frame(width: 140, height: 180)
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            Text("2 likes")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.error)
                        }
                    }
                    Text("Before")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                // Arrow with animation
                VStack(spacing: DesignSystem.Spacing.micro) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                    Text("AI")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }

                // After
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.flameOrange.opacity(0.3), DesignSystem.Colors.goldAccent.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 180)
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                            Text("47 likes")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(DesignSystem.Colors.flameOrange, lineWidth: 2)
                    )
                    .shadow(color: pulseGlow ? DesignSystem.Colors.flameOrange.opacity(0.4) : .clear, radius: 20)
                    Text("After")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
            .padding(.top, DesignSystem.Spacing.l)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Unlock Your Full Rizz")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("10x your matches with AI-powered dating photos")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Social Proof Banner

    private var socialProofBanner: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            HStack(spacing: DesignSystem.Spacing.l) {
                statPill(value: "50K+", label: "Photos Made")
                statPill(value: "4.9\u{2B50}", label: "App Rating")
                statPill(value: "3x", label: "More Matches")
            }
            .opacity(statsVisible ? 1 : 0)
            .offset(y: statsVisible ? 0 : 10)

            // Scrolling testimonials
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.s) {
                    testimonialCard(name: "Mike R.", text: "Got 3 dates in my first week after upgrading my photos!", stars: 5)
                    testimonialCard(name: "Sarah K.", text: "The AI coach helped me write the perfect bio. 10/10.", stars: 5)
                    testimonialCard(name: "James T.", text: "Went from 2 matches a month to 15. No joke.", stars: 5)
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.flameOrange)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private func testimonialCard(name: String, text: String, stars: Int) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: 2) {
                ForEach(0..<stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.goldAccent)
                }
            }
            Text("\"\(text)\"")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(3)
            Text("- \(name)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.s)
        .frame(width: 220)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            featureRow(icon: "wand.and.stars", title: "Unlimited AI Photos", subtitle: "Generate as many dating photos as you want", checked: true)
            featureRow(icon: "paintpalette.fill", title: "All 10 Style Presets", subtitle: "Confident, Adventurous, Golden Hour, and more", checked: true)
            featureRow(icon: "arrow.down.circle.fill", title: "HD Downloads", subtitle: "Full resolution photos, no watermark", checked: true)
            featureRow(icon: "brain.head.profile", title: "Rizz Coach Pro", subtitle: "AI bios, openers, and conversation tips", checked: true)
            featureRow(icon: "bolt.fill", title: "Priority Generation", subtitle: "Skip the line \u{2014} your photos generate first", checked: true)
            featureRow(icon: "sparkle.magnifyingglass", title: "Photo Audit", subtitle: "AI scores your existing photos with tips", checked: true)
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String, checked: Bool) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.flameOrange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(subtitle)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DesignSystem.Colors.success)
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    // MARK: - Plan Selection

    private var planSelection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Text("Choose Your Plan")
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.s) {
                ForEach(PlanOption.allCases, id: \.self) { plan in
                    planRow(plan)
                }
            }
        }
    }

    private func planRow(_ plan: PlanOption) -> some View {
        Button {
            withAnimation(DesignSystem.Animation.quickSpring) { selectedPlan = plan }
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: DesignSystem.Spacing.m) {
                // Radio button
                Circle()
                    .strokeBorder(selectedPlan == plan ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.divider, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(selectedPlan == plan ? DesignSystem.Colors.flameOrange : .clear)
                            .frame(width: 14, height: 14)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(plan.rawValue)
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(plan.badgeColor))
                        }
                    }
                    Text(plan.perDay)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(selectedPlan == plan ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                    Text(plan.period)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(DesignSystem.Spacing.m)
            .background(selectedPlan == plan ? DesignSystem.Colors.flameOrange.opacity(0.08) : DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .strokeBorder(selectedPlan == plan ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.divider, lineWidth: selectedPlan == plan ? 2 : 1)
            )
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            GRButton(title: "Start 3-Day Free Trial", icon: "flame.fill") {
                DesignSystem.Haptics.medium()
                PostHogManager.shared.trackPaywallViewed(trigger: "paywall_cta")
            }

            Text("Cancel anytime \u{B7} No charge during trial \u{B7} Instant access")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Guarantee Section

    private var guaranteeSection: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 28))
                .foregroundStyle(DesignSystem.Colors.success)

            VStack(alignment: .leading, spacing: 2) {
                Text("100% Satisfaction Guarantee")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Not happy? Cancel within 7 days for a full refund.")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.success.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .strokeBorder(DesignSystem.Colors.success.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Button {
                isRestoring = true
                Task {
                    await subscriptionManager.restorePurchases()
                    isRestoring = false
                }
            } label: {
                Text(isRestoring ? "Restoring..." : "Restore Purchases")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .disabled(isRestoring)

            HStack(spacing: DesignSystem.Spacing.m) {
                Button { } label: {
                    Text("Terms of Service")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Text("\u{B7}")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Button { } label: {
                    Text("Privacy Policy")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}
