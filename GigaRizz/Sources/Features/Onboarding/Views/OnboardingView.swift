import SwiftUI

// MARK: - Onboarding View (4-Screen High-Conversion Flow)

/// First impression onboarding flow.
/// Screen 1: The Promise — value proposition with social proof
/// Screen 2: How It Works — 3 steps
/// Screen 3: Before & After — visual transformation proof
/// Screen 4: Soft Paywall + Apple Sign-In CTA
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    @State private var showSignIn = false
    @State private var showPermissionEducation = false
    
    // MARK: - Background Gradient
    
    private let backgroundGradient = LinearGradient(
        colors: [
            DesignSystem.Colors.background,
            DesignSystem.Colors.deepNight,
            Color(hex: "0D0D14").opacity(0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Skip Button
                skipButton
                
                // MARK: - Tab View (Pages)
                TabView(selection: $viewModel.currentPage) {
                    OnboardingPage1View(viewModel: viewModel)
                        .tag(0)
                    
                    OnboardingPage2View(viewModel: viewModel)
                        .tag(1)
                    
                    OnboardingBeforeAfterView(viewModel: viewModel)
                        .tag(2)
                    
                    OnboardingPaywallView(
                        viewModel: viewModel,
                        onContinueFree: { handleContinueFree() },
                        onSignIn: { handleSignIn() }
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.smoothSpring, value: viewModel.currentPage)
                
                // MARK: - Page Dots
                pageDots
                    .padding(.bottom, DesignSystem.Spacing.large)
                
                // MARK: - CTA Button (hidden on paywall page — it has its own)
                if viewModel.currentPage < 3 {
                    ctaButton
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.bottom, DesignSystem.Spacing.xl)
                }
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
    }
    
    // MARK: - Skip Button
    
    @ViewBuilder
    private var skipButton: some View {
        HStack {
            Spacer()
            if viewModel.currentPage < viewModel.totalPages - 1 {
                Button {
                    viewModel.skipOnboarding()
                    hasCompletedOnboarding = true
                    PostHogManager.shared.trackOnboardingCtaTapped(page: viewModel.currentPage + 1, cta: "Skip")
                } label: {
                    Text("Skip")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .accessibilityHint("Skip onboarding and go directly to sign in")
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .frame(height: 44)
    }
    
    // MARK: - Page Dots
    
    @ViewBuilder
    private var pageDots: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentPage ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surfaceSecondary)
                    .frame(width: index == viewModel.currentPage ? 24 : 8, height: 8)
                    .animation(DesignSystem.Animation.quickSpring, value: viewModel.currentPage)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pageLabel)
    }
    
    private var pageLabel: String {
        return "Page \(viewModel.currentPage + 1) of 4"
    }
    
    // MARK: - CTA Button
    
    @ViewBuilder
    private var ctaButton: some View {
        GRButton(
            title: ctaTitle,
            icon: ctaIcon,
            accessibilityHint: ctaHint
        ) {
            handleCtaTap()
            PostHogManager.shared.trackOnboardingCtaTapped(page: viewModel.currentPage + 1, cta: ctaTitle)
        }
    }
    
    private var ctaTitle: String {
        switch viewModel.currentPage {
        case 0: return "See How It Works"
        case 1: return "See the Magic"
        case 2: return "Get Started"
        default: return "Continue"
        }
    }
    
    private var ctaIcon: String {
        switch viewModel.currentPage {
        case 0: return "arrow.right"
        case 1: return "sparkles"
        case 2: return "arrow.right"
        default: return "arrow.right"
        }
    }
    
    private var ctaHint: String {
        switch viewModel.currentPage {
        case 0: return "Shows the next onboarding page"
        case 1: return "Shows before and after examples"
        case 2: return "Proceeds to pricing options"
        default: return "Continues to next step"
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleCtaTap() {
        if viewModel.currentPage < 3 {
            viewModel.advancePage()
        }
    }
    
    private func handleContinueFree() {
        viewModel.completeOnboarding()
        hasCompletedOnboarding = true
        showSignIn = true
    }
    
    private func handleSignIn() {
        viewModel.completeOnboarding()
        hasCompletedOnboarding = true
        showSignIn = true
    }
}

// MARK: - Onboarding Page 1 — The Promise

struct OnboardingPage1View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // MARK: - Hero Visual
            heroVisual
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // MARK: - Text Content
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Your Best Dating Photos,\nAI-Generated")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("Pick 3-5 photos. Our AI transforms them into magazine-quality dating photos in 60 seconds.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your Best Dating Photos, AI-Generated. Pick 3-5 photos. Our AI transforms them into magazine-quality dating photos in 60 seconds.")
    }
    
    // MARK: - Hero Visual (Animated)
    
    @ViewBuilder
    private var heroVisual: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.flameOrange.opacity(0.2),
                            DesignSystem.Colors.goldAccent.opacity(0.1)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .accessibilityHidden(true)
            
            // Main icon with animation
            ZStack {
                // Photo stack
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(width: 80, height: 100)
                        .rotationEffect(.degrees(Double(index) * -15 + 15))
                        .offset(x: CGFloat(index) * 20 - 20, y: CGFloat(index) * 10 - 10)
                        .opacity(index == 0 ? 1 : 0.6)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.1),
                            value: viewModel.currentPage
                        )
                }
                
                // Wand overlay
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
                    .offset(y: -20)
            }
            .accessibilityHidden(true)
        }
    }
}

// MARK: - Onboarding Page 2 — How It Works

struct OnboardingPage2View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var stepAnimations: [Bool] = [false, false, false]
    
    // MARK: - Steps Data
    
    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "photo.badge.plus",
            title: "Pick 3-5 photos",
            subtitle: "We pick the best ones from your library",
            color: DesignSystem.Colors.flameOrange
        ),
        OnboardingStep(
            icon: "wand.and.stars",
            title: "AI Transforms",
            subtitle: "Professional quality, authentic you",
            color: DesignSystem.Colors.goldAccent
        ),
        OnboardingStep(
            icon: "heart.fill",
            title: "Get More Matches",
            subtitle: "Optimized for Tinder, Hinge, Bumble",
            color: DesignSystem.Colors.success
        )
    ]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // MARK: - Header
            Text("How It Works")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            // MARK: - Steps
            VStack(spacing: DesignSystem.Spacing.large) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepCard(step: step, index: index)
                        .frame(height: 90)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateStepsSequentially()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("How It Works. Step 1: Pick 3-5 photos. Step 2: AI Transforms. Step 3: Get More Matches.")
    }
    
    // MARK: - Step Card
    
    @ViewBuilder
    private func stepCard(step: OnboardingStep, index: Int) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Icon
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: step.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(step.color)
            }
            .scaleEffect(stepAnimations[index] ? 1 : 0.5)
            .opacity(stepAnimations[index] ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.15), value: stepAnimations[index])
            .accessibilityHidden(true)
            
            // Text
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(step.title)
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text(step.subtitle)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            // Step number
            Text("\(index + 1)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(step.color)
                .padding(DesignSystem.Spacing.xs)
                .background(step.color.opacity(0.2))
                .clipShape(Circle())
                .accessibilityHidden(true)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .cardShadow()
    }
    
    private func animateStepsSequentially() {
        for i in 0..<stepAnimations.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                stepAnimations[i] = true
            }
        }
    }
}

// MARK: - Onboarding Page 3 — Before & After Visual Proof

struct OnboardingBeforeAfterView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var showAfter = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // MARK: - Header
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("See the Difference")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text("Real users. Real transformations.")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            
            // MARK: - Before/After Cards
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Before card
                VStack(spacing: DesignSystem.Spacing.small) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(DesignSystem.Colors.surfaceSecondary)
                            .frame(width: 140, height: 180)
                        
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "person.crop.square")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.4))
                            
                            Text("📱 Selfie")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    Text("Before")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .opacity(showAfter ? 0.6 : 1)
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .symbolEffect(.bounce, options: .repeating.speed(0.3), value: showAfter)
                
                // After card
                VStack(spacing: DesignSystem.Spacing.small) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.flameOrange.opacity(0.2), DesignSystem.Colors.goldAccent.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                    .stroke(DesignSystem.Colors.flameOrange.opacity(0.5), lineWidth: 2)
                            )
                        
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                            
                            Text("✨ AI Enhanced")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    }
                    .scaleEffect(showAfter ? 1.05 : 0.95)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showAfter)
                    
                    Text("After")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // MARK: - Social Proof
            VStack(spacing: DesignSystem.Spacing.small) {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(DesignSystem.Colors.goldAccent)
                    }
                }
                
                Text("\"Got 3x more matches in the first week\"")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .italic()
                
                Text("— Alex, 28")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(.top, DesignSystem.Spacing.large)
            
            Spacer()
            Spacer()
        }
        .onAppear { showAfter = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("See the Difference. Real users, real transformations. Quote: Got 3x more matches in the first week.")
    }
}

// MARK: - Onboarding Page 4 — Soft Paywall

struct OnboardingPaywallView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinueFree: () -> Void
    let onSignIn: () -> Void
    
    @State private var selectedPlan: OnboardingPlan = .plus
    
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
            case .free: return ["3 photos/day", "1 style", "Watermarked"]
            case .plus: return ["30 photos/day", "10 styles", "HD downloads", "Rizz Coach"]
            case .gold: return ["Unlimited photos", "All styles", "HD downloads", "Rizz Coach", "Priority queue"]
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
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.large) {
                // MARK: - Header
                VStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    
                    Text("Choose Your Plan")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    Text("Start free. Upgrade anytime.")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.xl)
                
                // MARK: - Plan Cards
                VStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(OnboardingPlan.allCases, id: \.rawValue) { plan in
                        planCard(plan: plan)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                
                // MARK: - CTA
                VStack(spacing: DesignSystem.Spacing.medium) {
                    GRButton(
                        title: selectedPlan == .free ? "Continue Free" : "Start \(selectedPlan.title) — \(selectedPlan.price)\(selectedPlan.period)",
                        icon: "apple.logo",
                        accessibilityHint: "Sign in with Apple and start with \(selectedPlan.title) plan"
                    ) {
                        PostHogManager.shared.trackOnboardingCtaTapped(page: 4, cta: "paywall_\(selectedPlan.rawValue)")
                        if selectedPlan == .free {
                            onContinueFree()
                        } else {
                            onSignIn()
                        }
                    }
                    
                    if selectedPlan != .free {
                        Button {
                            PostHogManager.shared.trackOnboardingCtaTapped(page: 4, cta: "continue_free")
                            onContinueFree()
                        } label: {
                            Text("Continue with Free")
                                .font(DesignSystem.Typography.smallButton)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                
                // MARK: - Legal Footer
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("By continuing, you agree to our")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Link(destination: AppConstants.termsURL) {
                            Text("Terms")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                        
                        Text("and")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        
                        Link(destination: AppConstants.privacyURL) {
                            Text("Privacy Policy")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
    }
    
    // MARK: - Plan Card
    
    @ViewBuilder
    private func planCard(plan: OnboardingPlan) -> some View {
        let isSelected = selectedPlan == plan
        
        Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                selectedPlan = plan
            }
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surfaceSecondary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(DesignSystem.Colors.flameOrange)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Plan info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(DesignSystem.Typography.title)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DesignSystem.Colors.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.flameOrange)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(plan.features.joined(separator: " · "))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing) {
                    Text(plan.price)
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                    if !plan.period.isEmpty {
                        Text(plan.period)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(isSelected ? DesignSystem.Colors.flameOrange : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(plan.title) plan, \(plan.price)\(plan.period)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }
}

// MARK: - Supporting Types

struct OnboardingStep {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - Previews

#Preview("Onboarding Flow") {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}

#Preview("Page 1 - The Promise") {
    OnboardingPage1View(viewModel: OnboardingViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Page 2 - How It Works") {
    OnboardingPage2View(viewModel: OnboardingViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Page 3 - Before & After") {
    OnboardingBeforeAfterView(viewModel: OnboardingViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Page 4 - Soft Paywall") {
    OnboardingPaywallView(viewModel: OnboardingViewModel(), onContinueFree: {}, onSignIn: {})
        .preferredColorScheme(.dark)
}