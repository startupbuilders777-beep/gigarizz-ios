import SwiftUI

/// Utility for generating marketing screenshots and automated visual testing.
@MainActor
final class ScreenshotTestHelper: ObservableObject {
    static let shared = ScreenshotTestHelper()

    @Published var isCapturing = false
    @Published var capturedScreens: [String] = []

    struct ScreenConfig: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let darkMode: Bool
        let category: ScreenCategory
    }

    enum ScreenCategory: String, CaseIterable {
        case onboarding = "Onboarding"
        case generation = "Generation"
        case profile = "Profile"
        case social = "Social"
        case settings = "Settings"
    }

    func allScreenConfigs() -> [ScreenConfig] {
        [
            ScreenConfig(name: "onboarding_welcome", description: "Welcome screen with animated particles", darkMode: true, category: .onboarding),
            ScreenConfig(name: "paywall", description: "Subscription paywall with social proof", darkMode: true, category: .onboarding),
            ScreenConfig(name: "generate_main", description: "Main generation view with photo picker", darkMode: true, category: .generation),
            ScreenConfig(name: "generation_result", description: "Generation results with rizz scores", darkMode: true, category: .generation),
            ScreenConfig(name: "background_replacer", description: "AI background replacement scene picker", darkMode: true, category: .generation),
            ScreenConfig(name: "profile_main", description: "User profile with photo audit", darkMode: true, category: .profile),
            ScreenConfig(name: "profile_preview", description: "Dating app preview (Tinder/Hinge/Bumble)", darkMode: true, category: .profile),
            ScreenConfig(name: "analytics_dashboard", description: "Match rate analytics and insights", darkMode: true, category: .profile),
            ScreenConfig(name: "coach_main", description: "Rizz Coach with AI suggestions", darkMode: true, category: .social),
            ScreenConfig(name: "matches_list", description: "Match inbox tracking", darkMode: true, category: .social),
            ScreenConfig(name: "rating_view", description: "App rating pre-prompt with stars", darkMode: true, category: .social),
            ScreenConfig(name: "settings_main", description: "Settings with all options", darkMode: true, category: .settings),
        ]
    }

    @discardableResult
    func captureAllScreens() async -> [String] {
        isCapturing = true; capturedScreens = []
        for config in allScreenConfigs() {
            capturedScreens.append(config.name)
            PostHogManager.shared.track("screenshot_captured", properties: ["screen_name": config.name, "category": config.category.rawValue, "dark_mode": config.darkMode])
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        isCapturing = false; return capturedScreens
    }

    var totalScreenCount: Int { allScreenConfigs().count }
    func screens(for category: ScreenCategory) -> [ScreenConfig] { allScreenConfigs().filter { $0.category == category } }
}

#if DEBUG
struct ScreenshotGalleryView: View {
    @StateObject private var helper = ScreenshotTestHelper()
    @State private var selectedCategory: ScreenshotTestHelper.ScreenCategory = .onboarding

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.m) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            ForEach(ScreenshotTestHelper.ScreenCategory.allCases, id: \.self) { cat in
                                Button { selectedCategory = cat } label: {
                                    Text(cat.rawValue).font(DesignSystem.Typography.callout)
                                        .padding(.horizontal, DesignSystem.Spacing.m).padding(.vertical, DesignSystem.Spacing.xs)
                                        .background(selectedCategory == cat ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
                                        .foregroundStyle(selectedCategory == cat ? .white : DesignSystem.Colors.textSecondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }.padding(.horizontal, DesignSystem.Spacing.m)
                    }

                    let configs = helper.screens(for: selectedCategory)
                    ForEach(Array(configs.enumerated()), id: \.offset) { _, config in
                        GRCard {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text(config.name.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                                Text(config.description).font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                                HStack {
                                    Label(config.category.rawValue, systemImage: "folder.fill").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.flameOrange)
                                    Spacer()
                                    Image(systemName: config.darkMode ? "moon.fill" : "sun.max.fill").font(.system(size: 12)).foregroundStyle(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }.padding(.horizontal, DesignSystem.Spacing.m)
                    }

                    Button { Task { await helper.captureAllScreens() } } label: {
                        HStack { Image(systemName: "camera.fill"); Text("Capture All (\(helper.totalScreenCount) screens)") }
                            .font(DesignSystem.Typography.callout).foregroundStyle(.white).frame(maxWidth: .infinity).padding()
                            .background(DesignSystem.Colors.flameOrange).clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    }.padding(.horizontal, DesignSystem.Spacing.m).padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
        }.navigationTitle("Screenshot Gallery")
    }
}

#Preview { NavigationStack { ScreenshotGalleryView() }.preferredColorScheme(.dark) }
#endif
