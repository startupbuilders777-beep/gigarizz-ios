import SwiftUI

// MARK: - Weekly Rizz Report Card

/// Compact card showing weekly report summary with tap to expand.
struct WeeklyRizzReportCard: View {
    let report: WeeklyRizzReport

    var body: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Header
                HStack(spacing: DesignSystem.Spacing.small) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .fill(report.scoreChange >= 0 ? DesignSystem.Colors.success.opacity(0.2) : DesignSystem.Colors.warning.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: report.scoreChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(report.scoreChange >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                    }
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Weekly Rizz Report")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(weekRangeText)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: DesignSystem.Spacing.micro) {
                        Text(report.scoreChange >= 0 ? "+\(report.scoreChange)" : "\(report.scoreChange)")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(report.scoreChange >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                        Text("pts")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                // Milestone (if any)
                if let milestone = report.milestone {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(DesignSystem.Colors.goldAccent)
                        Text(milestone)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.goldAccent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .background(DesignSystem.Colors.goldAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                }

                // Top Insights (show 2)
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(report.insights.prefix(2)) { insight in
                        insightRow(insight)
                    }
                }

                // Tap to see more
                HStack {
                    Text("Tap to see full report")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func insightRow(_ insight: RizzInsight) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Circle()
                .fill(insightColor(insight.type).opacity(0.2))
                .frame(width: 24, height: 24)
                .overlay {
                    Image(systemName: insightIcon(insight.type))
                        .font(.system(size: 10))
                        .foregroundStyle(insightColor(insight.type))
                }
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text(insight.title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(insight.description)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: report.weekStartDate)
        let end = formatter.string(from: report.weekEndDate)
        return "\(start) - \(end)"
    }

    private func insightIcon(_ type: RizzInsight.InsightType) -> String {
        switch type {
        case .photo: return "photo.fill"
        case .bio: return "text.quote"
        case .response: return "clock.fill"
        case .activity: return "chart.line.uptrend.xyaxis"
        case .prompts: return "text.badge.star"
        }
    }

    private func insightColor(_ type: RizzInsight.InsightType) -> Color {
        switch type {
        case .photo: return DesignSystem.Colors.flameOrange
        case .bio: return DesignSystem.Colors.hinge
        case .response: return DesignSystem.Colors.success
        case .activity: return DesignSystem.Colors.bumble
        case .prompts: return DesignSystem.Colors.goldAccent
        }
    }
}

// MARK: - Weekly Rizz Report Detail View

/// Full sheet view for the weekly report with all insights and actions.
struct WeeklyRizzReportDetailView: View {
    let report: WeeklyRizzReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        headerSection
                        scoreChangeSection
                        milestoneSection
                        insightsSection
                        topActionsSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                        DesignSystem.Haptics.light()
                    }
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerSection: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(weekRangeText)
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Your personalized dating insights")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    private var scoreChangeSection: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.large) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Score Change")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(report.scoreChange >= 0 ? "+\(report.scoreChange)" : "\(report.scoreChange)")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(report.scoreChange >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                        Text("points")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(report.scoreChange >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error, lineWidth: 3)
                        .frame(width: 60, height: 60)
                    Image(systemName: report.scoreChange >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(report.scoreChange >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                }
            }
        }
    }

    private var milestoneSection: some View {
        Group {
            if let milestone = report.milestone {
                GRCard {
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(DesignSystem.Colors.goldAccent)
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                            Text("Milestone Achieved!")
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.goldAccent)
                            Text(milestone)
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("This Week's Insights")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(report.insights) { insight in
                GRCard {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Circle()
                            .fill(insightColor(insight.type))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: insightIcon(insight.type))
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                            }
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                            Text(insight.title)
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text(insight.description)
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var topActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Top Actions for Next Week")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(report.topActions) { action in
                GRCard {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Text("#\(action.priority)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.micro)
                            .background(DesignSystem.Colors.flameOrange.opacity(0.2))
                            .clipShape(Capsule())

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                            Text(action.title)
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text(action.description)
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: report.weekStartDate)
        let end = formatter.string(from: report.weekEndDate)
        return "\(start) - \(end)"
    }

    private func insightIcon(_ type: RizzInsight.InsightType) -> String {
        switch type {
        case .photo: return "photo.fill"
        case .bio: return "text.quote"
        case .response: return "clock.fill"
        case .activity: return "chart.line.uptrend.xyaxis"
        case .prompts: return "text.badge.star"
        }
    }

    private func insightColor(_ type: RizzInsight.InsightType) -> Color {
        switch type {
        case .photo: return DesignSystem.Colors.flameOrange
        case .bio: return DesignSystem.Colors.hinge
        case .response: return DesignSystem.Colors.success
        case .activity: return DesignSystem.Colors.bumble
        case .prompts: return DesignSystem.Colors.goldAccent
        }
    }
}

// MARK: - Previews

#Preview("Weekly Report Card") {
    WeeklyRizzReportCard(report: WeeklyRizzReport.demo)
        .padding()
        .background(DesignSystem.Colors.background)
        .preferredColorScheme(.dark)
}

#Preview("Weekly Report Detail") {
    WeeklyRizzReportDetailView(report: WeeklyRizzReport.demo)
}
