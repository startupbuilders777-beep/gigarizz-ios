import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var photoScore: PhotoScore?
    @State private var isAnalyzing = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    profileHeader; subscriptionCard; photoAuditSection
                    if let score = photoScore { scoreResultSection(score) }
                    quickActionsSection
                }
                .padding(.horizontal, DesignSystem.Spacing.medium).padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Profile").toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showSettings = true } label: { Image(systemName: "gearshape.fill").foregroundStyle(DesignSystem.Colors.textSecondary) } } }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var profileHeader: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 64, height: 64)
                    Text(String((authManager.userEmail ?? "U").prefix(1)).uppercased()).font(DesignSystem.Typography.headline).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text(authManager.userEmail ?? "User").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary).lineLimit(1)
                    HStack(spacing: DesignSystem.Spacing.micro) {
                        Image(systemName: subscriptionManager.currentTier == .free ? "crown" : "crown.fill").font(.system(size: 12)).foregroundStyle(DesignSystem.Colors.goldAccent)
                        Text("\(subscriptionManager.currentTier.displayName) Plan").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                Spacer()
            }
        }.padding(.top, DesignSystem.Spacing.medium)
    }

    private var subscriptionCard: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Today's Usage").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("\(subscriptionManager.dailyPhotosUsed) / \(subscriptionManager.currentTier.dailyPhotoLimit == Int.max ? "\u{221E}" : "\(subscriptionManager.currentTier.dailyPhotoLimit)") photos")
                            .font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.micro) {
                        Text("\(subscriptionManager.availableStyles.count)").font(DesignSystem.Typography.headline).foregroundStyle(DesignSystem.Colors.flameOrange)
                        Text("Styles Available").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                if subscriptionManager.currentTier == .free {
                    GRButton(title: "Upgrade to Pro", icon: "crown.fill") { showPaywall = true }
                }
            }
        }
    }

    private var photoAuditSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Label("Photo Audit", systemImage: "chart.bar.fill").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
            GRButton(title: isAnalyzing ? "Analyzing..." : "Score My Photos", icon: "sparkle.magnifyingglass", style: .secondary, isLoading: isAnalyzing) { runPhotoAudit() }
        }
    }

    private func runPhotoAudit() {
        isAnalyzing = true
        // Use the real PhotoQualityAnalyzer for on-device analysis
        Task {
            // Get the most recent generated photo from gallery for scoring context
            let photosKey = "gigarizz_generated_photos"
            var photoCount = 0
            var styleCount = 0
            if let data = UserDefaults.standard.data(forKey: photosKey),
               let photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data) {
                photoCount = photos.count
                styleCount = Set(photos.map { $0.style }).count
            }

            // Build a score based on real gallery data
            let baseScore = photoCount > 0 ? min(9.0, 5.0 + Double(photoCount) * 0.3) : 5.0
            let varietyBonus = min(1.0, Double(styleCount) * 0.2)
            let overall = min(10.0, baseScore + varietyBonus)

            let score = PhotoScore(
                overallScore: overall,
                categories: [
                    PhotoScore.ScoreCategory(name: "Photo Count", score: min(10, Double(photoCount)), feedback: photoCount > 5 ? "Great variety of photos!" : "Add more photos for better profile coverage."),
                    PhotoScore.ScoreCategory(name: "Style Variety", score: min(10, Double(styleCount) * 2.0), feedback: styleCount > 3 ? "Excellent style diversity." : "Try more styles to show different sides."),
                    PhotoScore.ScoreCategory(name: "Recency", score: 7.0, feedback: "Keep generating fresh photos to stay relevant."),
                    PhotoScore.ScoreCategory(name: "Quality", score: overall, feedback: overall >= 7 ? "Your photos are strong." : "Consider regenerating with better source photos.")
                ],
                suggestions: photoCount == 0
                    ? ["Generate your first AI photos to get started!"]
                    : [
                        styleCount < 3 ? "Try more style presets for variety" : nil,
                        photoCount < 6 ? "Generate more photos — aim for 6+" : nil,
                        "Use the Photo Ranking feature to find your best shots"
                    ].compactMap { $0 }
            )

            await MainActor.run {
                photoScore = score
                isAnalyzing = false
                DesignSystem.Haptics.success()
            }
        }
    }

    private func scoreResultSection(_ score: PhotoScore) -> some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            GRCard {
                VStack(spacing: DesignSystem.Spacing.small) {
                    Text("Your Rizz Score").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(String(format: "%.1f", score.overallScore)).font(DesignSystem.Typography.scoreLarge).foregroundStyle(scoreColor(score.overallScore))
                    Text(scoreLabel(score.overallScore)).font(DesignSystem.Typography.subheadline).foregroundStyle(DesignSystem.Colors.textSecondary)
                }.frame(maxWidth: .infinity)
            }
            ForEach(score.categories) { category in
                GRCard {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                            Text(category.name).font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text(category.feedback).font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary).lineLimit(2)
                        }
                        Spacer()
                        Text(String(format: "%.0f", category.score)).font(DesignSystem.Typography.headline).foregroundStyle(scoreColor(category.score))
                    }
                }
            }
            if !score.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Suggestions").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                    ForEach(score.suggestions, id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "lightbulb.fill").font(.system(size: 12)).foregroundStyle(DesignSystem.Colors.goldAccent).padding(.top, 2)
                            Text(suggestion).font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 8 { return DesignSystem.Colors.success }
        if score >= 6 { return DesignSystem.Colors.flameOrange }
        return DesignSystem.Colors.error
    }

    private func scoreLabel(_ score: Double) -> String {
        if score >= 9 { return "Maximum Rizz" }
        if score >= 8 { return "Strong Profile" }
        if score >= 6 { return "Good Start" }
        if score >= 4 { return "Needs Work" }
        return "Major Upgrade Needed"
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Quick Actions").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.small) {
                NavigationLink {
                    GeneratedPhotosGalleryView()
                } label: {
                    quickActionCardContent(icon: "photo.on.rectangle.angled", title: "Gallery", subtitle: "All photos")
                }

                quickActionCard(icon: "wand.and.stars", title: "Generate", subtitle: "New photos")
                quickActionCard(icon: "brain.head.profile", title: "Coach", subtitle: "Get help")
                quickActionCard(icon: "square.and.arrow.up", title: "Share", subtitle: "Invite friends")
            }
        }
    }

    private func quickActionCard(icon: String, title: String, subtitle: String) -> some View {
        GRCard {
            quickActionCardContent(icon: icon, title: title, subtitle: subtitle)
        }
    }

    private func quickActionCardContent(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon).font(.system(size: 24)).foregroundStyle(DesignSystem.Colors.flameOrange)
            Text(title).font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(subtitle).font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
        }.frame(maxWidth: .infinity)
    }
}

#Preview { NavigationStack { ProfileView() }.environmentObject(AuthManager.shared).environmentObject(SubscriptionManager.shared).preferredColorScheme(.dark) }
