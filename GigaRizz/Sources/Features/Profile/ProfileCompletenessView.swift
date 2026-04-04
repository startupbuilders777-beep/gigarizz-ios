import SwiftUI

// MARK: - Completeness Ring

struct CompletenessRing: View {
    let score: Int
    var diameter: CGFloat = 80
    var strokeWidth: CGFloat = 8
    
    @State private var animatedScore: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    DesignSystem.Colors.surfaceSecondary,
                    lineWidth: strokeWidth
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedScore / 100)
                .stroke(
                    LinearGradient(
                        colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    DesignSystem.Animation.cardSpring,
                    value: animatedScore
                )
            
            // Score text
            VStack(spacing: DesignSystem.Spacing.micro) {
                Text("\(score)%")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Complete")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            animatedScore = Double(score)
        }
        .onChange(of: score) { _, newValue in
            animatedScore = Double(newValue)
        }
    }
}

// MARK: - Milestone Badge

struct MilestoneBadgeView: View {
    let level: MilestoneLevel
    var size: CGFloat = 32
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(level.color.opacity(0.2))
                    .frame(width: size, height: size)
                Image(systemName: level.icon)
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(level.color)
            }
            Text(level.name)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(level.color)
        }
    }
}

// MARK: - Completeness Checklist Item

struct CompletenessItemView: View {
    let item: CompletenessItem
    let onTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            // Checkmark or progress indicator
            ZStack {
                Circle()
                    .fill(item.isComplete ? DesignSystem.Colors.flameOrange.opacity(0.2) : DesignSystem.Colors.surfaceSecondary)
                    .frame(width: 28, height: 28)
                
                if item.isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                } else {
                    Image(systemName: item.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text(item.name)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text(item.description)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Weight badge
            Text("+\(item.weight)%")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(item.isComplete ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, 4)
                .background(
                    (item.isComplete ? DesignSystem.Colors.success : DesignSystem.Colors.surfaceSecondary)
                        .opacity(0.2)
                )
                .clipShape(Capsule())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let onTap {
                DesignSystem.Haptics.light()
                onTap()
            }
        }
    }
}

// MARK: - Next Step Card

struct NextStepCard: View {
    let item: CompletenessItem
    let pointsGain: Int
    let nextLevel: MilestoneLevel?
    let onTap: () -> Void
    
    var body: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Next Step")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        
                        Text(item.name)
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        
                        if let next = nextLevel {
                            Text("Reach \(next.name) (+\(pointsGain)%)")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.flameOrange.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: item.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                }
                
                if let actionTitle = item.actionTitle {
                    GRButton(
                        title: actionTitle,
                        icon: "arrow.right",
                        action: onTap
                    )
                }
            }
        }
    }
}

// MARK: - Reward Banner

struct RewardBanner: View {
    let credits: Int
    let level: MilestoneLevel
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.goldAccent.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "gift.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.Colors.goldAccent)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text("Reward Unlocked!")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.goldAccent)
                Text("\(credits) free generation credits earned")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Button {
                DesignSystem.Haptics.light()
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.goldAccent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .strokeBorder(DesignSystem.Colors.goldAccent.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Profile Completeness View

struct ProfileCompletenessView: View {
    @StateObject private var viewModel = ProfileCompletenessViewModel()
    @State private var isExpanded = false
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // Reward banner (if applicable)
            if viewModel.showRewardBanner {
                RewardBanner(
                    credits: viewModel.currentLevel.rewardCredits,
                    level: viewModel.currentLevel,
                    onDismiss: { viewModel.dismissRewardBanner() }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Main completeness card
            GRCard {
                VStack(spacing: DesignSystem.Spacing.m) {
                    // Header with ring and level
                    HStack(spacing: DesignSystem.Spacing.m) {
                        CompletenessRing(score: viewModel.completenessScore)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Profile Completeness")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            
                            MilestoneBadgeView(level: viewModel.currentLevel)
                        }
                        
                        Spacer()
                        
                        // Expand/collapse button
                        Button {
                            withAnimation(DesignSystem.Animation.quickSpring) {
                                isExpanded.toggle()
                            }
                            DesignSystem.Haptics.light()
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .padding(DesignSystem.Spacing.s)
                                .background(DesignSystem.Colors.surfaceSecondary)
                                .clipShape(Circle())
                        }
                    }
                    
                    // Progress to next milestone
                    if let next = viewModel.nextLevel {
                        HStack(spacing: DesignSystem.Spacing.s) {
                            Text("Progress to \(next.name)")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(viewModel.completenessScore)/\(next.rawValue)%")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                        
                        ProgressView(value: viewModel.progressToNextMilestone)
                            .tint(DesignSystem.Colors.flameOrange)
                            .progressViewStyle(.linear)
                    } else {
                        Text("Match Magnet Status Achieved!")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.success)
                    }
                    
                    // Expanded content
                    if isExpanded {
                        VStack(spacing: DesignSystem.Spacing.s) {
                            Divider()
                                .background(DesignSystem.Colors.divider)
                            
                            // Checklist
                            ForEach(viewModel.completenessItems) { item in
                                CompletenessItemView(
                                    item: item,
                                    onTap: item.actionTitle != nil ? { } : nil
                                )
                            }
                            
                            Divider()
                                .background(DesignSystem.Colors.divider)
                            
                            // Next step card
                            if let nextStep = viewModel.nextStep {
                                NextStepCard(
                                    item: nextStep,
                                    pointsGain: viewModel.nextStepPointsGain,
                                    nextLevel: viewModel.nextLevel,
                                    onTap: { }
                                )
                            }
                            
                            // Earned credits display
                            if viewModel.earnedCredits > 0 {
                                HStack(spacing: DesignSystem.Spacing.s) {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(DesignSystem.Colors.goldAccent)
                                    Text("\(viewModel.earnedCredits) free credits earned from milestones")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    Spacer()
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .animation(DesignSystem.Animation.cardSpring, value: isExpanded)
        .animation(DesignSystem.Animation.cardSpring, value: viewModel.showRewardBanner)
    }
}

// MARK: - Compact Banner Variant (for profile tab header)

struct ProfileCompletenessBanner: View {
    @StateObject private var viewModel = ProfileCompletenessViewModel()
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            CompletenessRing(score: viewModel.completenessScore, diameter: 48, strokeWidth: 4)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text("Profile Completeness")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text(viewModel.currentLevel.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(viewModel.currentLevel.color)
            }
            
            Spacer()
            
            // Next milestone indicator
            if let next = viewModel.nextLevel {
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.micro) {
                    Text("\(next.rawValue)%")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text("Next Goal")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .cardShadow()
    }
}

// MARK: - Previews

#Preview("Profile Completeness View") {
    ScrollView {
        ProfileCompletenessView()
            .padding()
    }
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("Profile Completeness Banner") {
    ProfileCompletenessBanner()
        .padding()
        .background(DesignSystem.Colors.background)
        .preferredColorScheme(.dark)
}
