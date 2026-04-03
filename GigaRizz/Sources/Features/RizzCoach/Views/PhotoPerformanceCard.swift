import SwiftUI

// MARK: - Photo Performance Card

/// Photo ranking card showing swipe/match rates with feedback.
struct PhotoPerformanceCard: View {
    let performance: PhotoPerformance
    @State private var isExpanded: Bool = false

    var body: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.s) {
                // Main row
                HStack(spacing: DesignSystem.Spacing.m) {
                    // Rank badge
                    ZStack {
                        Circle()
                            .fill(rankColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Text("#\(performance.rank)")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(rankColor)
                    }

                    // Photo placeholder (would show actual photo thumbnail)
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .fill(DesignSystem.Colors.surfaceSecondary)
                            .frame(width: 48, height: 48)
                        Image(systemName: "photo.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text(rankLabel)
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        HStack(spacing: DesignSystem.Spacing.s) {
                            Label("\(Int(performance.swipeRate * 100))%", systemImage: "arrow.right.circle")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(swipeRateColor)
                            Label("\(Int(performance.matchRate * 100))%", systemImage: "heart.circle")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(matchRateColor)
                        }
                    }
                    Spacer()

                    // Expand indicator
                    Button {
                        withAnimation(DesignSystem.Animation.quickSpring) {
                            isExpanded.toggle()
                        }
                        DesignSystem.Haptics.light()
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                // Expanded feedback
                if isExpanded {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Divider()
                            .background(DesignSystem.Colors.divider)

                        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: performance.rank <= 2 ? "checkmark.circle.fill" : "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(performance.rank <= 2 ? DesignSystem.Colors.success : DesignSystem.Colors.goldAccent)

                            Text(performance.feedback)
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var rankColor: Color {
        if performance.rank == 1 { return DesignSystem.Colors.goldAccent }
        if performance.rank <= 2 { return DesignSystem.Colors.success }
        if performance.rank <= 3 { return DesignSystem.Colors.flameOrange }
        return DesignSystem.Colors.warning
    }

    private var rankLabel: String {
        if performance.rank == 1 { return "Top Performer" }
        if performance.rank == 2 { return "Strong Second" }
        if performance.rank <= 3 { return "Average" }
        return "Needs Improvement"
    }

    private var swipeRateColor: Color {
        if performance.swipeRate >= 0.7 { return DesignSystem.Colors.success }
        if performance.swipeRate >= 0.5 { return DesignSystem.Colors.flameOrange }
        return DesignSystem.Colors.warning
    }

    private var matchRateColor: Color {
        if performance.matchRate >= 0.2 { return DesignSystem.Colors.success }
        if performance.matchRate >= 0.1 { return DesignSystem.Colors.flameOrange }
        return DesignSystem.Colors.warning
    }
}

// MARK: - Photo Performance Section Header

/// Section showing all photos ranked by performance.
struct PhotoPerformanceSection: View {
    let performances: [PhotoPerformance]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Label("Photo Performance Ranking", systemImage: "photo.stack.fill")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Ranked by swipe and match rates")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ForEach(performances) { performance in
                PhotoPerformanceCard(performance: performance)
            }
        }
    }
}

// MARK: - Previews

#Preview("Photo Performance Cards") {
    VStack(spacing: 12) {
        PhotoPerformanceCard(performance: PhotoPerformance.demoPerformances[0])
        PhotoPerformanceCard(performance: PhotoPerformance.demoPerformances[2])
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("Photo Performance Section") {
    ScrollView {
        PhotoPerformanceSection(performances: PhotoPerformance.demoPerformances)
            .padding()
    }
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}