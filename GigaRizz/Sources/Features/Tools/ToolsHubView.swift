import SwiftUI

// MARK: - Tools Hub View

struct ToolsHubView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var featureFlags = FeatureFlagManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.large) {
                headerSection

                // Featured Tool
                NavigationLink {
                    PhotoAuditView()
                } label: {
                    featuredCard(
                        title: "AI Photo Audit",
                        subtitle: "Get your dating photos scored by AI",
                        icon: "magnifyingglass",
                        badge: "FREE",
                        gradient: [DesignSystem.Colors.flameOrange, .orange]
                    )
                }

                // Tools Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.medium),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.medium)
                ], spacing: DesignSystem.Spacing.medium) {
                    NavigationLink {
                        PhotoPacksView().environmentObject(subscriptionManager)
                    } label: {
                        toolCard(
                            title: "Photo Packs",
                            subtitle: "Platform-optimized styles",
                            icon: "rectangle.stack.fill",
                            color: DesignSystem.Colors.hinge
                        )
                    }

                    NavigationLink {
                        BioWriterView().environmentObject(subscriptionManager)
                    } label: {
                        toolCard(
                            title: "Bio Writer",
                            subtitle: "AI-crafted dating bios",
                            icon: "text.bubble.fill",
                            color: DesignSystem.Colors.bumble
                        )
                    }

                    NavigationLink {
                        CoachView()
                    } label: {
                        toolCard(
                            title: "Rizz Coach",
                            subtitle: "Photo coaching tips",
                            icon: "brain.head.profile",
                            color: .purple
                        )
                    }

                    NavigationLink {
                        FaceEnhancementView()
                    } label: {
                        toolCard(
                            title: "Face Enhance",
                            subtitle: "Natural AI retouching",
                            icon: "face.smiling.fill",
                            color: DesignSystem.Colors.success
                        )
                    }

                    NavigationLink {
                        BackgroundReplacerView()
                    } label: {
                        toolCard(
                            title: "Backgrounds",
                            subtitle: "AI scene replacement",
                            icon: "photo.on.rectangle.angled",
                            color: DesignSystem.Colors.flameOrange
                        )
                    }
                    .opacity(featureFlags.isEnabled(.backgroundReplacer) ? 1 : 0.4)
                    .disabled(!featureFlags.isEnabled(.backgroundReplacer))

                    if featureFlags.isEnabled(.photoRanking) {
                        NavigationLink {
                            PhotoRankingView()
                        } label: {
                            toolCard(
                                title: "Photo Ranking",
                                subtitle: "Rank your best shots",
                                icon: "trophy.fill",
                                color: DesignSystem.Colors.goldAccent
                            )
                        }
                    }

                    if featureFlags.isEnabled(.colorGrade) {
                        NavigationLink {
                            LightingColorGradeView()
                        } label: {
                            toolCard(
                                title: "Color Grade",
                                subtitle: "Pro lighting presets",
                                icon: "camera.filters",
                                color: .purple
                            )
                        }
                    }

                    if featureFlags.isEnabled(.expressionCoach) {
                        NavigationLink {
                            ExpressionCoachView()
                        } label: {
                            toolCard(
                                title: "Expression Coach",
                                subtitle: "Real-time face coaching",
                                icon: "face.smiling",
                                color: .cyan
                            )
                        }
                    }

                    if featureFlags.isEnabled(.poseLibrary) {
                        NavigationLink {
                            PoseLibraryView()
                        } label: {
                            toolCard(
                                title: "Pose Library",
                                subtitle: "30 dating-ready poses",
                                icon: "figure.stand",
                                color: .indigo
                            )
                        }
                    }
                }

                // Stats Banner
                statsBanner
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Tools")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await featureFlags.refreshIfNeeded()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Level Up Your Profile")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text("AI-powered tools to maximize your matches")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DesignSystem.Spacing.small)
    }

    // MARK: - Featured Card

    private func featuredCard(title: String, subtitle: String, icon: String, badge: String, gradient: [Color]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                Spacer()
                Text(badge)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.25))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack {
                Text("Score your photos now")
                    .font(DesignSystem.Typography.button)
                    .foregroundStyle(.white)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.white)
            }
        }
        .padding(DesignSystem.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    // MARK: - Tool Card

    private func toolCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    // MARK: - Stats Banner

    private var statsBanner: some View {
        HStack(spacing: DesignSystem.Spacing.large) {
            statItem(value: "4.2x", label: "More Matches", icon: "flame.fill")
            statItem(value: "89%", label: "Score Boost", icon: "chart.line.uptrend.xyaxis")
            statItem(value: "200+", label: "Photo Styles", icon: "photo.stack.fill")
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
            Text(value)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ToolsHubView()
    }
    .environmentObject(SubscriptionManager.shared)
    .preferredColorScheme(.dark)
}
