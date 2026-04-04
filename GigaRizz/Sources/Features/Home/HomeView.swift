import SwiftUI

// MARK: - Home Dashboard View

/// Primary navigation hub for GigaRizz — first thing users see when opening the app.
/// Features: user greeting, hero CTA, quick actions, recent generations, daily tip, stats strip.
struct HomeView: View {
    @Binding var selectedTab: MainTabView.Tab
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = HomeViewModel()
    @State private var showPaywall = false
    @State private var showQuickUpload = false
    @AppStorage("hasGeneratedPhotos") private var hasGeneratedPhotos = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        // Header section
                        headerSection
                        
                        // Onboarding banner (if needed)
                        if viewModel.showOnboardingBanner {
                            onboardingBanner
                        }
                        
                        // Hero CTA card
                        heroCard
                        
                        // Quick actions row
                        quickActionsSection
                        
                        // Recent generations
                        if hasGeneratedPhotos {
                            recentGenerationsSection
                        }
                        
                        // Tools & Resources
                        toolsSection
                        
                        // Daily Rizz tip
                        dailyTipSection
                        
                        // Stats strip
                        statsSection
                        
                        // Subscription status
                        subscriptionStatusCard
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.top, DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    settingsButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    creditsBadge
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showQuickUpload) {
                QuickUploadSheet()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
            }
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottomTrailing) {
            // Quick Upload FAB - power user single-photo express generation
            QuickUploadFAB(isPresented: $showQuickUpload)
                .padding(.trailing, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.large)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text(viewModel.userGreeting)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text("Ready to boost your dating game?")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.top, DesignSystem.Spacing.small)
    }
    
    // MARK: - Settings Button
    
    private var settingsButton: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
    
    // MARK: - Credits Badge
    
    private var creditsBadge: some View {
        Button {
            showPaywall = true
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: DesignSystem.Spacing.micro) {
                Image(systemName: subscriptionManager.currentTier == .free ? "crown" : "crown.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.goldAccent)
                
                Text("\(subscriptionManager.photosRemainingToday)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.surface)
            .clipShape(Capsule())
        }
        .accessibilityLabel("Credits: \(subscriptionManager.photosRemainingToday) photos remaining")
    }
    
    // MARK: - Onboarding Banner
    
    private var onboardingBanner: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Complete Setup")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    Text("Finish onboarding to unlock all features")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.clearOnboardingBanner()
                    DesignSystem.Haptics.light()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(DesignSystem.Animation.quickSpring, value: viewModel.showOnboardingBanner)
    }
    
    // MARK: - Hero CTA Card
    
    private var heroCard: some View {
        Button {
            selectedTab = .generate
            DesignSystem.Haptics.medium()
        } label: {
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.flameOrange,
                                DesignSystem.Colors.goldAccent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                
                // Content
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, options: .repeating, isActive: true)
                    
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Generate New Photos")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(.white)
                        
                        Text("3-6 selfies → Magazine-quality dating photos")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .cardShadow()
        }
        .accessibilityLabel("Generate new AI photos")
        .accessibilityHint("Double tap to switch to photo generation tab")
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(QuickAction.allCases) { action in
                    quickActionButton(action)
                }
            }
        }
    }
    
    private func quickActionButton(_ action: QuickAction) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Group {
                if let tab = action.switchesTab {
                    // Actions that have dedicated tabs → switch tab instead of pushing
                    Button {
                        selectedTab = tab
                        DesignSystem.Haptics.light()
                    } label: {
                        quickActionIcon(action)
                    }
                } else {
                    // Actions without dedicated tabs → NavigationLink
                    NavigationLink {
                        destinationForAction(action)
                    } label: {
                        quickActionIcon(action)
                    }
                    .buttonStyle(HapticButtonStyle(hapticStyle: .light))
                }
            }
            
            Text(action.title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            
            Text(action.subtitle)
                .font(.system(size: 10))
                .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(action.title): \(action.subtitle)")
    }
    
    /// Icon circle shared between NavigationLink and Button quick actions
    private func quickActionIcon(_ action: QuickAction) -> some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.surface)
                .frame(width: 64, height: 64)
            
            Image(systemName: action.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
        }
        .overlay(
            Circle()
                .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func destinationForAction(_ action: QuickAction) -> some View {
        switch action {
        case .profileScore:
            ProfileView()
        case .myGallery:
            GeneratedPhotosGalleryView()
        default:
            EmptyView() // Tab-switching actions handled by button, not NavigationLink
        }
    }
    
    // MARK: - Recent Generations Section
    
    private var recentGenerationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("Recent Generations")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink {
                    GeneratedPhotosGalleryView()
                } label: {
                    Text("See All")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
            
            if viewModel.recentGenerations.isEmpty {
                emptyRecentGenerations
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        ForEach(viewModel.recentGenerations) { generation in
                            recentGenerationCard(generation)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyRecentGenerations: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 28))
                    .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.5))
                
                Text("No generations yet")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
        }
    }
    
    private func recentGenerationCard(_ generation: RecentGeneration) -> some View {
        NavigationLink {
            GeneratedPhotosGalleryView()
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Thumbnail placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.flameOrange.opacity(0.3),
                                    DesignSystem.Colors.goldAccent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                        )
                        )
                        .frame(width: 120, height: 160)
                    
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Text("\(generation.photoCount)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(generation.style)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    Text(generation.dateText)
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(HapticButtonStyle(hapticStyle: .light))
    }
    
    // MARK: - Tools Section
    
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Tools & Resources")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            NavigationLink {
                ToolsHubView()
            } label: {
                GRCard {
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .fill(DesignSystem.Colors.flameOrange.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 20))
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                            Text("Tools Hub")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("Photo audit, packs, bio tips & more")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .buttonStyle(HapticButtonStyle(hapticStyle: .light))
            .accessibilityLabel("Tools Hub: Photo audit, packs, bio tips and more")
        }
    }
    
    // MARK: - Daily Tip Section
    
    private var dailyTipSection: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.small) {
                HStack {
                    Image(systemName: viewModel.dailyTip.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.goldAccent)
                    
                    Text(viewModel.dailyTip.title)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("Today")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                
                Text(viewModel.dailyTip.content)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.dailyTip.title): \(viewModel.dailyTip.content)")
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            statCard(
                value: viewModel.photosGenerated,
                label: "Photos",
                icon: "photo.fill"
            )
            
            statCard(
                value: viewModel.daysActive,
                label: "Days Active",
                icon: "calendar"
            )
            
            statCard(
                value: viewModel.profilesUpdated,
                label: "Profiles",
                icon: "person.crop.circle.fill"
            )
        }
    }
    
    private func statCard(value: Int, label: String, icon: String) -> some View {
        GRCard(padding: DesignSystem.Spacing.small) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystem.Colors.flameOrange.opacity(0.6))
                
                Text("\(value)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .contentTransition(.numericText())
                
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
    
    // MARK: - Subscription Status Card
    
    private var subscriptionStatusCard: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Tier badge
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(subscriptionManager.currentTier == .free
                              ? DesignSystem.Colors.surfaceSecondary
                              : DesignSystem.Colors.goldAccent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.goldAccent)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("\(subscriptionManager.currentTier.displayName) Plan")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    Text(bannerText)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if subscriptionManager.currentTier == .free {
                    Button {
                        showPaywall = true
                        DesignSystem.Haptics.light()
                    } label: {
                        Text("Upgrade")
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.deepNight)
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.flameOrange,
                                        DesignSystem.Colors.goldAccent
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                            )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private var bannerText: String {
        switch subscriptionManager.bannerState {
        case .freePhotosLeft(count: let count):
            return "\(count) free photos remaining"
        case .freeNoPhotosLeft:
            return "Daily limit reached"
        case .plusActive:
            return "Plus subscription active"
        case .plusExpiringSoon(days: let days):
            return "Renews in \(days) days"
        case .goldActive:
            return "Gold subscription active"
        case .gracePeriod:
            return "Subscription renewal pending"
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}