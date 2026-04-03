import SwiftUI

// MARK: - Onboarding Data

struct OnboardingStep: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let lottieHint: String // For future Lottie integration
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @State private var currentStep = 0
    @Binding var hasCompletedOnboarding: Bool
    @State private var selectedGoals: Set<String> = []
    @State private var selectedPlatforms: Set<String> = []
    @State private var photoCount: Double = 3
    @State private var animateIcon = false
    @State private var showContent = false

    private let steps: [OnboardingStep] = [
        OnboardingStep(id: 0, icon: "flame.fill", title: "Welcome to GigaRizz", subtitle: "The AI dating photo generator that\nactually gets you matches.", gradient: [DesignSystem.Colors.flameOrange, .orange], lottieHint: "flame"),
        OnboardingStep(id: 1, icon: "chart.line.uptrend.xyaxis", title: "3x More Matches", subtitle: "Users with AI-enhanced photos get\n3x more right swipes on average.", gradient: [DesignSystem.Colors.success, .teal], lottieHint: "chart"),
        OnboardingStep(id: 2, icon: "camera.fill", title: "Upload Your Selfies", subtitle: "Pick 3-6 clear selfies. Different angles,\ngood lighting \u{2014} we handle the rest.", gradient: [.purple, .blue], lottieHint: "camera"),
        OnboardingStep(id: 3, icon: "paintpalette.fill", title: "Pick Your Vibe", subtitle: "Confident? Adventurous? Golden Hour?\nChoose from 10 AI style presets.", gradient: [.pink, DesignSystem.Colors.flameOrange], lottieHint: "palette"),
        OnboardingStep(id: 4, icon: "wand.and.stars", title: "AI Does the Magic", subtitle: "Our AI analyzes your features and\ncreates stunning dating photos in seconds.", gradient: [.indigo, .purple], lottieHint: "wand"),
        OnboardingStep(id: 5, icon: "person.crop.rectangle.stack.fill", title: "Preview on Any App", subtitle: "See exactly how you'll look on Tinder,\nHinge, and Bumble before uploading.", gradient: [DesignSystem.Colors.tinder, .pink], lottieHint: "preview"),
        OnboardingStep(id: 6, icon: "brain.head.profile", title: "Your Rizz Coach", subtitle: "AI-written bios, opening lines, and\nHinge prompts that actually work.", gradient: [.cyan, .blue], lottieHint: "brain"),
        OnboardingStep(id: 7, icon: "heart.text.square.fill", title: "Track Your Matches", subtitle: "Log matches, track conversations,\nand never ghost anyone again.", gradient: [.pink, .red], lottieHint: "heart"),
        OnboardingStep(id: 8, icon: "crown.fill", title: "Free vs Pro", subtitle: "3 free photos daily. Upgrade for unlimited\ngenerations, all styles, and HD downloads.", gradient: [DesignSystem.Colors.goldAccent, .orange], lottieHint: "crown"),
        OnboardingStep(id: 9, icon: "bolt.fill", title: "Let's Get Started", subtitle: "Your dating profile glow-up\nstarts right now. Ready?", gradient: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent], lottieHint: "rocket"),
    ]

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            // Animated background particles
            backgroundParticles

            VStack(spacing: 0) {
                // Top bar with skip and progress
                topBar

                // Step content
                TabView(selection: $currentStep) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        stepView(step, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.smoothSpring, value: currentStep)

                // Progress dots
                progressIndicator
                    .padding(.bottom, DesignSystem.Spacing.m)

                // Bottom button
                bottomButton
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .onChange(of: currentStep) { _, _ in
            animateIcon = false
            showContent = false
            withAnimation(DesignSystem.Animation.smoothSpring.delay(0.1)) {
                animateIcon = true
            }
            withAnimation(DesignSystem.Animation.smoothSpring.delay(0.2)) {
                showContent = true
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.smoothSpring.delay(0.3)) {
                animateIcon = true
            }
            withAnimation(DesignSystem.Animation.smoothSpring.delay(0.4)) {
                showContent = true
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Step counter
            Text("\(currentStep + 1) / \(steps.count)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .monospacedDigit()

            Spacer()

            if currentStep < steps.count - 1 {
                Button { completeOnboarding() } label: {
                    Text("Skip")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .frame(height: 44)
    }

    // MARK: - Step View

    private func stepView(_ step: OnboardingStep, index: Int) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Animated icon with glow
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [step.gradient.first?.opacity(0.3) ?? .clear, .clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(animateIcon ? 1.0 : 0.5)
                    .opacity(animateIcon ? 1.0 : 0.0)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: step.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: step.gradient.first?.opacity(0.5) ?? .clear, radius: 30, y: 15)
                    .scaleEffect(animateIcon ? 1.0 : 0.3)

                // Icon
                Image(systemName: step.icon)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(animateIcon ? 1.0 : 0.5)
                    .rotationEffect(.degrees(animateIcon ? 0 : -30))
            }

            // Text content
            VStack(spacing: DesignSystem.Spacing.m) {
                Text(step.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text(step.subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }

            // Interactive content for specific steps
            if index == 3 { stylePreviewGrid }
            if index == 5 { platformPreviewRow }
            if index == 8 { tierComparisonMini }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
    }

    // MARK: - Interactive Step Content

    private var stylePreviewGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.s) {
                ForEach(["Confident", "Adventurous", "Golden Hour", "Urban Moody", "Sporty"], id: \.self) { style in
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(
                                LinearGradient(
                                    colors: gradientForStyle(style),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: iconForStyle(style))
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                            )
                        Text(style)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
        }
        .opacity(showContent ? 1 : 0)
    }

    private var platformPreviewRow: some View {
        HStack(spacing: DesignSystem.Spacing.l) {
            platformBadge(name: "Tinder", color: DesignSystem.Colors.tinder, icon: "flame.fill")
            platformBadge(name: "Hinge", color: DesignSystem.Colors.hinge, icon: "heart.fill")
            platformBadge(name: "Bumble", color: DesignSystem.Colors.bumble, icon: "bolt.fill")
        }
        .opacity(showContent ? 1 : 0)
    }

    private func platformBadge(name: String, color: Color, icon: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)
                )
            Text(name)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var tierComparisonMini: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            tierBadge(name: "Free", features: "3 photos/day\n1 style", color: DesignSystem.Colors.textSecondary)
            tierBadge(name: "Plus", features: "30 photos/day\nAll styles", color: DesignSystem.Colors.flameOrange)
            tierBadge(name: "Gold", features: "Unlimited\nHD + Priority", color: DesignSystem.Colors.goldAccent)
        }
        .opacity(showContent ? 1 : 0)
    }

    private func tierBadge(name: String, features: String, color: Color) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text(name)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(color)
            Text(features)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.micro) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentStep
                            ? DesignSystem.Colors.flameOrange
                            : index < currentStep
                                ? DesignSystem.Colors.flameOrange.opacity(0.4)
                                : DesignSystem.Colors.surfaceSecondary
                    )
                    .frame(width: index == currentStep ? 28 : 8, height: 6)
                    .animation(DesignSystem.Animation.quickSpring, value: currentStep)
            }
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        GRButton(
            title: currentStep == steps.count - 1 ? "Let's Rizz \u{1F525}" : "Continue",
            icon: currentStep == steps.count - 1 ? "flame.fill" : "arrow.right"
        ) {
            if currentStep < steps.count - 1 {
                withAnimation(DesignSystem.Animation.smoothSpring) {
                    currentStep += 1
                }
            } else {
                completeOnboarding()
            }
            DesignSystem.Haptics.light()
        }
    }

    // MARK: - Background Particles

    private var backgroundParticles: some View {
        GeometryReader { geo in
            ForEach(0..<15, id: \.self) { i in
                Circle()
                    .fill(DesignSystem.Colors.flameOrange.opacity(Double.random(in: 0.03...0.08)))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        PostHogManager.shared.trackOnboardingCompleted()
        DesignSystem.Haptics.success()
    }

    private func gradientForStyle(_ style: String) -> [Color] {
        switch style {
        case "Confident": return [DesignSystem.Colors.flameOrange, .orange]
        case "Adventurous": return [.green, .teal]
        case "Golden Hour": return [.orange, .yellow]
        case "Urban Moody": return [.purple, .blue]
        case "Sporty": return [.red, DesignSystem.Colors.flameOrange]
        default: return [DesignSystem.Colors.flameOrange, .orange]
        }
    }

    private func iconForStyle(_ style: String) -> String {
        switch style {
        case "Confident": return "sparkles"
        case "Adventurous": return "mountain.2.fill"
        case "Golden Hour": return "sun.max.fill"
        case "Urban Moody": return "building.2.fill"
        case "Sporty": return "figure.run"
        default: return "sparkles"
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}
