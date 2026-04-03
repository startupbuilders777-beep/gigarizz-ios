import SwiftUI

// MARK: - Rizz Score Card

/// Composite 1-100 score display with category breakdown.
struct RizzScoreCard: View {
    let score: RizzScore
    var isLoading: Bool = false
    var showAnimation: Bool = false
    var onRefresh: () -> Void = {}

    @State private var animatedScore: Int = 0
    @State private var expandedCategories: Bool = false

    var body: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.l) {
                // Main Score Display
                mainScoreView

                // Trend Indicator
                trendIndicator

                // Category Breakdown (Expandable)
                categoryBreakdown
            }
        }
        .onAppear {
            animateScore()
        }
        .onChange(of: score.overallScore) { _, newValue in
            animatedScore = 0
            animateScore()
        }
    }

    // MARK: - Main Score

    private var mainScoreView: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Text("Your Rizz Score")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ZStack {
                // Glow effect
                if showAnimation {
                    Circle()
                        .fill(scoreColor.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(showAnimation ? 1.3 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAnimation)
                }

                Text(String(animatedScore))
                    .font(DesignSystem.Typography.scoreLarge)
                    .foregroundStyle(scoreColor)
                    .scaleEffect(showAnimation ? 1.15 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAnimation)
            }

            Text(scoreLabel)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            if let previous = score.previousScore {
                HStack(spacing: DesignSystem.Spacing.micro) {
                    Image(systemName: scoreChangeIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(scoreChangeColor)
                    Text(scoreChangeDisplay(previous: previous))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(scoreChangeColor)
                    Text("vs last week")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trend Indicator

    private var trendIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            trendBadge
            Spacer()
            Button {
                onRefresh()
                DesignSystem.Haptics.light()
            } label: {
                HStack(spacing: DesignSystem.Spacing.micro) {
                    if isLoading {
                        ProgressView()
                            .tint(DesignSystem.Colors.flameOrange)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                    }
                    Text("Refresh")
                        .font(DesignSystem.Typography.smallButton)
                }
                .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
    }

    private var trendBadge: some View {
        HStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: trendIcon)
                .font(.system(size: 12))
            Text(score.trend.rawValue)
                .font(DesignSystem.Typography.caption)
        }
        .padding(.horizontal, DesignSystem.Spacing.s)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(trendColor.opacity(0.15))
        .foregroundStyle(trendColor)
        .clipShape(Capsule())
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Button {
                withAnimation(DesignSystem.Animation.quickSpring) {
                    expandedCategories.toggle()
                }
                DesignSystem.Haptics.light()
            } label: {
                HStack {
                    Text("Score Breakdown")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Image(systemName: expandedCategories ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            if expandedCategories {
                ForEach(score.categories) { category in
                    categoryBar(category)
                }
            }
        }
    }

    private func categoryBar(_ category: RizzScoreCategory) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(categoryColor(category.score))
                Text(category.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("\(category.score)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(categoryColor(category.score))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(categoryColor(category.score))
                        .frame(width: geometry.size.width * CGFloat(category.score) / 100, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: category.score)
                }
            }
            .frame(height: 8)

            if let feedback = category.feedback {
                Text(feedback)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Helpers

    private func animateScore() {
        let target = score.overallScore
        let duration = 1.0
        let steps = 20
        let stepTime = duration / Double(steps)

        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepTime * Double(step)) {
                let progress = Double(step) / Double(steps)
                animatedScore = Int(Double(target) * progress)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            animatedScore = target
        }
    }

    private var scoreColor: Color {
        if score.overallScore >= 80 { return DesignSystem.Colors.success }
        if score.overallScore >= 60 { return DesignSystem.Colors.flameOrange }
        if score.overallScore >= 40 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }

    private var scoreLabel: String {
        if score.overallScore >= 90 { return "Maximum Rizz" }
        if score.overallScore >= 80 { return "Strong Profile" }
        if score.overallScore >= 70 { return "Above Average" }
        if score.overallScore >= 60 { return "Good Progress" }
        if score.overallScore >= 50 { return "Needs Work" }
        if score.overallScore >= 40 { return "Room to Grow" }
        return "Let's Improve"
    }

    private func scoreChangeDisplay(previous: Int) -> String {
        let change = score.overallScore - previous
        if change > 0 { return "+\(change)" }
        if change < 0 { return "\(change)" }
        return "No change"
    }

    private var scoreChangeIcon: String {
        guard let previous = score.previousScore else { return "minus" }
        let change = score.overallScore - previous
        if change > 0 { return "arrow.up.right" }
        if change < 0 { return "arrow.down.right" }
        return "minus"
    }

    private var scoreChangeColor: Color {
        guard let previous = score.previousScore else { return DesignSystem.Colors.textSecondary }
        let change = score.overallScore - previous
        if change > 0 { return DesignSystem.Colors.success }
        if change < 0 { return DesignSystem.Colors.error }
        return DesignSystem.Colors.textSecondary
    }

    private var trendIcon: String {
        switch score.trend {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }

    private var trendColor: Color {
        switch score.trend {
        case .improving: return DesignSystem.Colors.success
        case .stable: return DesignSystem.Colors.textSecondary
        case .declining: return DesignSystem.Colors.warning
        }
    }

    private func categoryColor(_ score: Int) -> Color {
        if score >= 80 { return DesignSystem.Colors.success }
        if score >= 60 { return DesignSystem.Colors.flameOrange }
        if score >= 40 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }
}

// MARK: - Preview

#Preview("Rizz Score Card") {
    VStack(spacing: 20) {
        RizzScoreCard(score: RizzScore.demo, showAnimation: true)
        RizzScoreCard(score: RizzScore(
            overallScore: 45,
            categories: [
                RizzScoreCategory(name: "Photos", score: 50, weight: 0.35, icon: "photo.fill"),
                RizzScoreCategory(name: "Bio", score: 40, weight: 0.25, icon: "text.quote")
            ],
            previousScore: 55,
            trend: .declining
        ))
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}