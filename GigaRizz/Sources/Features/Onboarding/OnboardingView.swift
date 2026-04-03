import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var hasCompletedOnboarding: Bool

    private let pages: [OnboardingPage] = [
        OnboardingPage(icon: "flame.fill", title: "Welcome to GigaRizz", subtitle: "Your AI-powered dating photo upgrade.\nBetter photos = more matches.", gradient: [DesignSystem.Colors.flameOrange, .orange]),
        OnboardingPage(icon: "camera.fill", title: "Upload Your Selfies", subtitle: "Pick 3-6 of your best selfies.\nWe'll use AI to create fire dating photos.", gradient: [.purple, .blue]),
        OnboardingPage(icon: "wand.and.stars", title: "Choose Your Style", subtitle: "Confident, Adventurous, Golden Hour \u{2014}\npick a look that's 100% you.", gradient: [.teal, .cyan]),
        OnboardingPage(icon: "heart.circle.fill", title: "Get More Matches", subtitle: "AI coach helps with bios, openers,\nand conversation starters. Let's go!", gradient: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent]),
    ]

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button { completeOnboarding() } label: {
                            Text("Skip").font(DesignSystem.Typography.smallButton).foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.m).frame(height: 44)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        onboardingPageView(page).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.smoothSpring, value: currentPage)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surfaceSecondary)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(DesignSystem.Animation.quickSpring, value: currentPage)
                    }
                }.padding(.bottom, DesignSystem.Spacing.l)

                GRButton(
                    title: currentPage == pages.count - 1 ? "Get Started" : "Continue",
                    icon: currentPage == pages.count - 1 ? "flame.fill" : "arrow.right"
                ) {
                    if currentPage < pages.count - 1 {
                        withAnimation(DesignSystem.Animation.smoothSpring) { currentPage += 1 }
                    } else { completeOnboarding() }
                    DesignSystem.Haptics.light()
                }
                .padding(.horizontal, DesignSystem.Spacing.m).padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
    }

    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .shadow(color: page.gradient.first?.opacity(0.4) ?? .clear, radius: 20, y: 10)
                Image(systemName: page.icon).font(.system(size: 48, weight: .bold)).foregroundStyle(.white)
            }
            VStack(spacing: DesignSystem.Spacing.m) {
                Text(page.title).font(DesignSystem.Typography.headline).foregroundStyle(DesignSystem.Colors.textPrimary).multilineTextAlignment(.center)
                Text(page.subtitle).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textSecondary).multilineTextAlignment(.center).lineSpacing(4)
            }
            Spacer(); Spacer()
        }.padding(.horizontal, DesignSystem.Spacing.xl)
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        PostHogManager.shared.trackOnboardingCompleted()
        DesignSystem.Haptics.success()
    }
}

struct OnboardingPage {
    let icon: String; let title: String; let subtitle: String; let gradient: [Color]
}

#Preview { OnboardingView(hasCompletedOnboarding: .constant(false)).preferredColorScheme(.dark) }
