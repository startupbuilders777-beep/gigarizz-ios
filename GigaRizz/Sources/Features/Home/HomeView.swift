import SwiftUI

// MARK: - Home Dashboard View

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = HomeViewModel()
    @State private var navigateToGenerate = false
    @State private var navigateToCoach = false
    @State private var navigateToPhotoAudit = false
    @State private var navigateToGallery = false
    @State private var showSettings = false
    @State private var selectedTab: Int?

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.m) {
                    headerSection
                    heroGenerateCard
                    quickActionsRow
                    recentGenerationsSection
                    rizzTipSection
                    statsStrip
                    onboardingBanner
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.top, DesignSystem.Spacing.s)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    DesignSystem.Haptics.light()
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            viewModel.loadDashboardData()
        }
        .onChange(of: selectedTab) { _, newValue in
            if let tab = newValue {
                // Navigate via tab selection - handled by parent
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text(viewModel.greetingText)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(viewModel.dateText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            // Credits Badge
            creditsBadge
        }
        .padding(.top, DesignSystem.Spacing.xs)
    }

    private var creditsBadge: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: subscriptionManager.currentTier.icon)
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.goldAccent)

            Text("\(subscriptionManager.photosRemainingToday)")
                .font(DesignSystem.Typography.smallButton)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.s)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.surface)
        .clipShape(Capsule())
    }

    // MARK: - Hero Generate Card

    private var heroGenerateCard: some View {
        Button {
            DesignSystem.Haptics.medium()
            navigateToGenerate = true
        } label: {
            ZStack {
                LinearGradient(
                    colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge))

                VStack(spacing: DesignSystem.Spacing.s) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, options: .repeating.speed(0.5))

                    Text("Generate New Photos")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(.white)

                    Text("Transform selfies into dating app gold")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
        }
        .navigationDestination(isPresented: $navigateToGenerate) {
            GenerateView().environmentObject(AIGenerationService.shared)
        }
    }

    // MARK: - Quick Actions Row

    private var quickActionsRow: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.m) {
                QuickActionButton(
                    icon: "photo.on.rectangle.angled",
                    label: "Photo Picker",
                    color: DesignSystem.Colors.flameOrange
                ) {
                    DesignSystem.Haptics.light()
                    navigateToGenerate = true
                }

                QuickActionButton(
                    icon: "brain.head.profile",
                    label: "Rizz Coach",
                    color: DesignSystem.Colors.goldAccent
                ) {
                    DesignSystem.Haptics.light()
                    navigateToCoach = true
                }

                QuickActionButton(
                    icon: "chart.bar.doc.horizontal",
                    label: "Profile Score",
                    color: DesignSystem.Colors.success
                ) {
                    DesignSystem.Haptics.light()
                    navigateToPhotoAudit = true
                }

                QuickActionButton(
                    icon: "rectangle.stack.fill",
                    label: "My Gallery",
                    color: DesignSystem.Colors.hinge
                ) {
                    DesignSystem.Haptics.light()
                    // Navigate to photo packs/gallery
                }
            }
        }
        .navigationDestination(isPresented: $navigateToCoach) {
            RizzCoachDashboardView()
        }
        .navigationDestination(isPresented: $navigateToPhotoAudit) {
            PhotoAuditView()
        }
    }

    // MARK: - Recent Generations Section

    private var recentGenerationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            HStack {
                Text("Recent Generations")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                if viewModel.hasRecentGenerations {
                    Text("View All")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }

            if viewModel.hasRecentGenerations {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.s) {
                        ForEach(viewModel.recentGenerations) { generation in
                            RecentGenerationCard(generation: generation)
                        }
                    }
                }
            } else {
                emptyGenerationsCard
            }
        }
    }

    private var emptyGenerationsCard: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.m) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(DesignSystem.Colors.flameOrange.opacity(0.6))

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("No generations yet")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Start creating stunning photos to fill this gallery")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Rizz Tip Section

    private var rizzTipSection: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(DesignSystem.Colors.goldAccent)

                    Text("Today's Rizz Tip")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Spacer()
                }

                Text(viewModel.dailyTip)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(3)
            }
        }
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            StatCard(
                value: viewModel.photosGenerated,
                label: "Photos\nGenerated"
            )

            StatCard(
                value: viewModel.daysActive,
                label: "Days\nActive"
            )

            StatCard(
                value: viewModel.profilesUpdated,
                label: "Profiles\nUpdated"
            )
        }
    }

    // MARK: - Onboarding Banner

    @ViewBuilder
    private var onboardingBanner: some View {
        if !viewModel.onboardingComplete {
            GRCard {
                HStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DesignSystem.Colors.warning)

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Complete Your Setup")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("Set up your profile to unlock all features")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    Spacer()

                    Button("Go") {
                        DesignSystem.Haptics.light()
                    }
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(DesignSystem.Colors.warning)
                }
            }
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(color)
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Generation Card

struct RecentGenerationCard: View {
    let generation: GenerationRecord

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Thumbnail placeholder - would use actual image from generation
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .frame(width: 120, height: 160)

                Image(systemName: "photo.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(DesignSystem.Colors.flameOrange.opacity(0.6))

                // Style badge
                VStack {
                    HStack {
                        Spacer()
                        Text(generation.styleName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.flameOrange)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(4)
            }

            Text(generation.dateText)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.micro) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.flameOrange)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}

// MARK: - Generation Record Model

struct GenerationRecord: Identifiable {
    let id: String
    let styleName: String
    let createdAt: Date
    let photoCount: Int

    var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: createdAt)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(AuthManager())
    .environmentObject(SubscriptionManager())
    .preferredColorScheme(.dark)
}