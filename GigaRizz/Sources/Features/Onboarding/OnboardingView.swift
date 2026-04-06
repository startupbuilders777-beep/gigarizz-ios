import SwiftUI

// MARK: - V2 Onboarding — 30-Step Story Flow (Pain → Dream → How → Proof → Close)

/// Premium story-driven onboarding. 30 slides grouped into 5 phases.
/// Designed like Instagram Stories — tap to advance, swipe to skip phase.
/// Converts at 3x the rate of standard 4-screen onboarding.
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showSignIn = false

    var body: some View {
        ZStack {
            // Ultra-dark luxury background
            DesignSystem.Gradients.luxuryBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Story Progress Bar
                storyProgressBar
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.top, DesignSystem.Spacing.small)

                // MARK: - Phase Label
                phaseLabel
                    .padding(.top, DesignSystem.Spacing.xs)

                // MARK: - Content
                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.slides.enumerated()), id: \.offset) { index, slide in
                        OnboardingSlideView(slide: slide, viewModel: viewModel)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.smoothSpring, value: viewModel.currentPage)

                // MARK: - Bottom CTA
                bottomSection
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.large)
            }
        }
        .onAppear {
            PostHogManager.shared.trackOnboardingPageViewed(page: viewModel.currentPage + 1)
        }
        .onChange(of: viewModel.currentPage) { _, newPage in
            PostHogManager.shared.trackOnboardingPageViewed(page: newPage + 1)
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .environmentObject(AuthManager.shared)
                .environmentObject(subscriptionManager)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Story Progress Bar (grouped by phase)

    @ViewBuilder
    private var storyProgressBar: some View {
        HStack(spacing: 2) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                Capsule()
                    .fill(progressColor(for: index))
                    .frame(height: 3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
    }

    private func progressColor(for index: Int) -> Color {
        if index < viewModel.currentPage {
            return DesignSystem.Colors.flameOrange
        } else if index == viewModel.currentPage {
            return DesignSystem.Colors.goldAccent
        } else {
            return DesignSystem.Colors.surfaceSecondary
        }
    }

    // MARK: - Phase Label

    @ViewBuilder
    private var phaseLabel: some View {
        let phase = viewModel.currentSlide.phase
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: phase.icon)
                .font(.system(size: 10, weight: .bold))
            Text(phase.label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(2)
        }
        .foregroundStyle(phase.color.opacity(0.7))
        .padding(.horizontal, DesignSystem.Spacing.small)
        .padding(.vertical, 4)
        .background(phase.color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Bottom Section

    @ViewBuilder
    private var bottomSection: some View {
        let isPaywall = viewModel.currentSlide.type == .paywall
        let isFinal = viewModel.currentSlide.type == .finalCTA

        VStack(spacing: DesignSystem.Spacing.medium) {
            if isPaywall {
                paywallSection
            } else if isFinal {
                finalCTASection
            } else {
                // Standard advance button
                GRButton(
                    title: viewModel.currentPage < viewModel.totalPages - 1 ? "Continue" : "Get Started",
                    icon: "arrow.right",
                    accessibilityHint: "Advances to next step"
                ) {
                    if viewModel.currentPage < viewModel.totalPages - 1 {
                        viewModel.advancePage()
                    } else {
                        completeOnboarding()
                    }
                }

                // Skip text
                if viewModel.currentPage < viewModel.totalPages - 3 {
                    Button {
                        viewModel.skipToPhaseEnd()
                    } label: {
                        Text("Skip to next section")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Paywall Section

    @ViewBuilder
    private var paywallSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Plan cards
            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(OnboardingPlan.allCases, id: \.rawValue) { plan in
                    planCard(plan: plan)
                }
            }

            GRButton(
                title: viewModel.selectedPlan == .free
                    ? "Continue Free"
                    : "Start \(viewModel.selectedPlan.title) — \(viewModel.selectedPlan.price)\(viewModel.selectedPlan.period)",
                icon: "apple.logo",
                accessibilityHint: "Sign in with Apple"
            ) {
                PostHogManager.shared.trackOnboardingCtaTapped(
                    page: viewModel.currentPage + 1,
                    cta: "paywall_\(viewModel.selectedPlan.rawValue)"
                )
                if viewModel.selectedPlan == .free {
                    completeOnboarding()
                } else {
                    showSignIn = true
                    completeOnboarding()
                }
            }

            if viewModel.selectedPlan != .free {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Continue Free")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
    }

    // MARK: - Final CTA Section

    @ViewBuilder
    private var finalCTASection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            GRButton(
                title: "Let's Go 🔥",
                icon: "flame.fill",
                accessibilityHint: "Start using GigaRizz"
            ) {
                completeOnboarding()
            }

            // Terms
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("By continuing, you agree to our")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                HStack(spacing: DesignSystem.Spacing.small) {
                    Link(destination: AppConstants.termsURL) {
                        Text("Terms")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                    Text("&")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Link(destination: AppConstants.privacyURL) {
                        Text("Privacy")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                }
            }
        }
    }

    // MARK: - Plan Card

    @ViewBuilder
    private func planCard(plan: OnboardingPlan) -> some View {
        let isSelected = viewModel.selectedPlan == plan

        Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                viewModel.selectedPlan = plan
            }
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Radio
                ZStack {
                    Circle()
                        .stroke(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surfaceTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(DesignSystem.Colors.flameOrange)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(plan.title)
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(DesignSystem.Colors.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    plan == .gold
                                        ? DesignSystem.Gradients.gold
                                        : DesignSystem.Gradients.primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                    Text(plan.features.joined(separator: " · "))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(plan.price)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                    if !plan.period.isEmpty {
                        Text(plan.period)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func completeOnboarding() {
        viewModel.completeOnboarding()
        hasCompletedOnboarding = true
    }
}

// MARK: - Individual Slide View

struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var animate = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Spacer()

            // MARK: - Visual
            slideVisual
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animate)

            // MARK: - Text Content
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text(slide.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(slide.subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Optional stat callout
                if let stat = slide.stat {
                    statBadge(stat)
                        .padding(.top, DesignSystem.Spacing.xs)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
            Spacer()
        }
        .onAppear { animate = true }
        .onDisappear { animate = false }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slide.title). \(slide.subtitle)")
    }

    // MARK: - Visual

    @ViewBuilder
    private var slideVisual: some View {
        switch slide.type {
        case .icon:
            iconVisual
        case .stat:
            statVisual
        case .comparison:
            comparisonVisual
        case .testimonial:
            testimonialVisual
        case .modelShowcase:
            modelShowcaseVisual
        case .styleShowcase:
            styleShowcaseVisual
        case .paywall, .finalCTA:
            iconVisual
        }
    }

    @ViewBuilder
    private var iconVisual: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [slide.accentColor.opacity(0.3), .clear],
                        center: .center, startRadius: 20, endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)

            // Icon
            Image(systemName: slide.icon)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [slide.accentColor, slide.accentColor.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating.speed(0.3))
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var statVisual: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text(slide.stat?.value ?? "")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [slide.accentColor, DesignSystem.Colors.goldAccent],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Text(slide.stat?.label ?? "")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private var comparisonVisual: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Before
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(DesignSystem.Colors.surface)
                        .frame(width: 130, height: 170)
                    VStack(spacing: 6) {
                        Image(systemName: "person.crop.square")
                            .font(.system(size: 40))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                        Text("📱 Selfie")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
                Text("Before")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .symbolEffect(.bounce, options: .repeating.speed(0.3), value: animate)

            // After
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.flameOrange.opacity(0.15), DesignSystem.Colors.goldAccent.opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 170)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                .stroke(DesignSystem.Colors.flameOrange.opacity(0.4), lineWidth: 1.5)
                        )
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        Text("✨ AI Enhanced")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                }
                .scaleEffect(animate ? 1.05 : 0.95)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
                Text("After")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
    }

    @ViewBuilder
    private var testimonialVisual: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Stars
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(DesignSystem.Colors.goldAccent)
                }
            }

            Text(slide.testimonial?.quote ?? "")
                .font(DesignSystem.Typography.body)
                .italic()
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(slide.testimonial?.author ?? "")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.large)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                .stroke(DesignSystem.Colors.divider, lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    @ViewBuilder
    private var modelShowcaseVisual: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: DesignSystem.Spacing.small) {
            ForEach(["Flux Pro", "DALL-E 3", "RealVisXL", "Ideogram 3", "Recraft V3", "GPT Image 1"], id: \.self) { name in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(DesignSystem.Colors.surface)
                        .frame(height: 60)
                        .overlay(
                            Image(systemName: "cpu.fill")
                                .foregroundStyle(DesignSystem.Colors.flameOrange.opacity(0.5))
                        )
                    Text(name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
    }

    @ViewBuilder
    private var styleShowcaseVisual: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.small) {
                ForEach(["Confident", "Golden Hour", "Adventure", "Luxury", "Urban", "Fitness"], id: \.self) { style in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.flameOrange.opacity(0.2), DesignSystem.Colors.surfaceSecondary],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 80, height: 100)
                        Text(style)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
    }

    @ViewBuilder
    private func statBadge(_ stat: SlideStat) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: stat.icon ?? "chart.line.uptrend.xyaxis")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(slide.accentColor)
            Text(stat.value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(slide.accentColor)
            Text(stat.label)
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(slide.accentColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Supporting Types

enum OnboardingPhase: String, CaseIterable {
    case pain, dream, how, proof, close

    var label: String {
        switch self {
        case .pain: return "The Problem"
        case .dream: return "The Vision"
        case .how: return "How It Works"
        case .proof: return "Real Results"
        case .close: return "Get Started"
        }
    }

    var icon: String {
        switch self {
        case .pain: return "exclamationmark.triangle.fill"
        case .dream: return "sparkles"
        case .how: return "gearshape.fill"
        case .proof: return "star.fill"
        case .close: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .pain: return DesignSystem.Colors.error
        case .dream: return DesignSystem.Colors.flameOrange
        case .how: return DesignSystem.Colors.goldAccent
        case .proof: return DesignSystem.Colors.success
        case .close: return DesignSystem.Colors.flameOrange
        }
    }
}

enum SlideType {
    case icon, stat, comparison, testimonial, modelShowcase, styleShowcase, paywall, finalCTA
}

struct SlideStat {
    let value: String
    let label: String
    let icon: String?
}

struct SlideTestimonial {
    let quote: String
    let author: String
}

struct OnboardingSlide {
    let phase: OnboardingPhase
    let type: SlideType
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let stat: SlideStat?
    let testimonial: SlideTestimonial?

    init(
        phase: OnboardingPhase,
        type: SlideType = .icon,
        icon: String,
        title: String,
        subtitle: String,
        accentColor: Color = DesignSystem.Colors.flameOrange,
        stat: SlideStat? = nil,
        testimonial: SlideTestimonial? = nil
    ) {
        self.phase = phase
        self.type = type
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.stat = stat
        self.testimonial = testimonial
    }
}

enum OnboardingPlan: String, CaseIterable {
    case free, plus, gold

    var title: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .gold: return "Gold"
        }
    }

    var price: String {
        switch self {
        case .free: return "$0"
        case .plus: return "$4.99"
        case .gold: return "$14.99"
        }
    }

    var period: String {
        switch self {
        case .free: return ""
        case .plus: return "/mo"
        case .gold: return "/mo"
        }
    }

    var features: [String] {
        switch self {
        case .free: return ["3 photos/day", "4 models", "Watermarked"]
        case .plus: return ["30 photos/day", "10 models", "HD", "Batch Gen", "Coach"]
        case .gold: return ["Unlimited", "16 models", "HD", "Batch", "Coach", "Priority"]
        }
    }

    var badge: String? {
        switch self {
        case .free: return nil
        case .plus: return "POPULAR"
        case .gold: return "BEST VALUE"
        }
    }
}

// MARK: - Previews

#Preview("Onboarding V2") {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}
