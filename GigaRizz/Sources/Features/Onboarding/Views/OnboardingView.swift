import SwiftUI

// MARK: - Onboarding View (3-Screen Flow)

/// First impression onboarding flow.
/// Screen 1: The Promise — value proposition
/// Screen 2: How It Works — 3 steps
/// Screen 3: Demo mini-picker + Apple Sign-In CTA
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var hasCompletedOnboarding: Bool
    
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
                    
                    OnboardingPage3View(viewModel: viewModel, onContinue: handlePage3Continue)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.smoothSpring, value: viewModel.currentPage)
                
                // MARK: - Page Dots
                pageDots
                    .padding(.bottom, DesignSystem.Spacing.large)
                
                // MARK: - CTA Button
                ctaButton
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.xl)
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
                .environmentObject(AuthManager())
        }
        .sheet(isPresented: $showPermissionEducation) {
            PermissionEducationView(
                viewModel: viewModel,
                permissionType: .photo,
                onGranted: { handlePermissionGranted() },
                onDenied: { handlePermissionDenied() }
            )
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
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
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
        return "Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)"
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
        case 1: return "Try It Free"
        case 2: return "Continue with Apple"
        default: return "Continue"
        }
    }
    
    private var ctaIcon: String {
        switch viewModel.currentPage {
        case 0: return "arrow.right"
        case 1: return "play.fill"
        case 2: return "apple.logo"
        default: return "arrow.right"
        }
    }
    
    private var ctaHint: String {
        switch viewModel.currentPage {
        case 0: return "Shows the next onboarding page"
        case 1: return "Proceeds to the demo photo picker"
        case 2: return "Opens Apple Sign In"
        default: return "Continues to next step"
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleCtaTap() {
        if viewModel.currentPage == 2 {
            // Apple Sign-In on last page
            viewModel.completeOnboarding()
            hasCompletedOnboarding = true
            showSignIn = true
        } else {
            viewModel.advancePage()
        }
    }
    
    private func handlePage3Continue() {
        viewModel.completeOnboarding()
        hasCompletedOnboarding = true
        // Show permission education before sign-in
        showPermissionEducation = true
    }
    
    private func handlePermissionGranted() {
        showSignIn = true
    }
    
    private func handlePermissionDenied() {
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
                        endPoint: .bottomTrailing
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

// MARK: - Onboarding Page 3 — Demo Picker

struct OnboardingPage3View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // MARK: - Header
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Try the Demo")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text("Tap to select photos (demo only)")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            
            // MARK: - Demo Photo Grid
            demoPhotoGrid
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // MARK: - Final Message
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Your dating life starts now")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text("1 photo selected = 4 AI variations")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Try the Demo. Tap to select photos. Your dating life starts now.")
    }
    
    // MARK: - Demo Photo Grid
    
    @ViewBuilder
    private var demoPhotoGrid: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            ForEach(viewModel.demoPhotos) { photo in
                demoPhotoCard(photo: photo)
            }
        }
    }
    
    @ViewBuilder
    private func demoPhotoCard(photo: DemoPhoto) -> some View {
        Button {
            viewModel.toggleDemoPhoto(id: photo.id)
        } label: {
            ZStack(alignment: .bottom) {
                // Photo placeholder
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .frame(width: 100, height: 120)
                    .overlay {
                        // Placeholder icon
                        Image(systemName: "person.crop.square")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.5))
                    }
                    .accessibilityHidden(true)
                
                // Selection indicator
                if viewModel.selectedDemoPhotos.contains(photo.id) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .stroke(DesignSystem.Colors.flameOrange, lineWidth: 3)
                        .frame(width: 100, height: 120)
                    
                    // Check mark
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                                .padding(DesignSystem.Spacing.small)
                        }
                        Spacer()
                    }
                    .accessibilityHidden(true)
                }
                
                // Description label
                Text(photo.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(DesignSystem.Spacing.xs)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.surface)
            }
            .frame(width: 100, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .cardShadow()
        }
        .accessibilityLabel(photo.description)
        .accessibilityHint(viewModel.selectedDemoPhotos.contains(photo.id) ? "Selected. Double tap to deselect." : "Not selected. Double tap to select.")
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

#Preview("Page 3 - Demo Picker") {
    OnboardingPage3View(viewModel: OnboardingViewModel(), onContinue: {})
        .preferredColorScheme(.dark)
}