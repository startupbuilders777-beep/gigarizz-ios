import SwiftUI

// MARK: - Response Time Tracker View

/// Response time tracking with average displayed and nudge system.
struct ResponseTimeTrackerView: View {
    let stats: ResponseTimeStats
    @State private var showTip: Bool = false

    var body: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                // Header
                HStack(spacing: DesignSystem.Spacing.s) {
                    ZStack {
                        Circle()
                        .fill(responseTimeColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.system(size: 20))
                            .foregroundStyle(responseTimeColor)
                    }
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Response Time Tracker")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("How fast do you reply to matches?")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                }

                // Average display
                HStack(spacing: DesignSystem.Spacing.m) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Average Response")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text(formatTime(stats.averageResponseHours))
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(responseTimeColor)
                            Text(responseTimeLabel)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    Spacer()
                    // Streak badge
                    VStack(spacing: DesignSystem.Spacing.micro) {
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.chip)
                                .fill(DesignSystem.Colors.success.opacity(0.2))
                                .frame(width: 60, height: 36)
                            VStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(DesignSystem.Colors.success)
                                Text("\(stats.streak)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.success)
                            }
                        }
                        Text("day streak")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                // Stats breakdown
                HStack(spacing: DesignSystem.Spacing.l) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Fastest")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Text(formatTime(stats.fastestResponseHours))
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.success)
                    }
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Slowest")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Text(formatTime(stats.slowestResponseHours))
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.warning)
                    }
                    Spacer()
                }

                // Nudge message (if present)
                if let nudge = stats.nudgeMessage {
                    HStack(spacing: DesignSystem.Spacing.s) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        Text(nudge)
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .padding(.horizontal, DesignSystem.Spacing.s)
                    .background(DesignSystem.Colors.flameOrange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                }

                // Improvement tip toggle
                Button {
                    withAnimation(DesignSystem.Animation.quickSpring) {
                        showTip.toggle()
                    }
                    DesignSystem.Haptics.light()
                } label: {
                    HStack {
                        Image(systemName: showTip ? "eye.slash" : "eye.fill")
                            .font(.system(size: 12))
                        Text(showTip ? "Hide Tip" : "Show Improvement Tip")
                            .font(DesignSystem.Typography.smallButton)
                        Spacer()
                        Image(systemName: showTip ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                if showTip {
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.goldAccent)
                            .padding(.top, 2)
                        Text(stats.improvementTip)
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var responseTimeColor: Color {
        if stats.averageResponseHours <= 2 { return DesignSystem.Colors.success }
        if stats.averageResponseHours <= 6 { return DesignSystem.Colors.flameOrange }
        if stats.averageResponseHours <= 12 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }

    private var responseTimeLabel: String {
        if stats.averageResponseHours <= 2 { return "Excellent" }
        if stats.averageResponseHours <= 6 { return "Good" }
        if stats.averageResponseHours <= 12 { return "Could be faster" }
        return "Needs attention"
    }

    private func formatTime(_ hours: Double) -> String {
        if hours < 1 {
            let minutes = Int(hours * 60)
            return "\(minutes)m"
        } else if hours < 24 {
            return "\(Int(hours))h"
        } else {
            let days = Int(hours / 24)
            return "\(days)d"
        }
    }
}

// MARK: - Preview

#Preview("Response Time Tracker") {
    VStack(spacing: 20) {
        ResponseTimeTrackerView(stats: ResponseTimeStats.demo)
        ResponseTimeTrackerView(stats: ResponseTimeStats(
            averageResponseHours: 0.5,
            fastestResponseHours: 0.2,
            slowestResponseHours: 2.0,
            streak: 7,
            nudgeMessage: nil,
            improvementTip: "You're a fast responder! Keep it up."
        ))
        ResponseTimeTrackerView(stats: ResponseTimeStats(
            averageResponseHours: 24,
            fastestResponseHours: 4,
            slowestResponseHours: 72,
            streak: 0,
            nudgeMessage: "5 matches waiting for replies. Don't let them fade!",
            improvementTip: "Responding within 2 hours increases match retention by 40%."
        ))
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}
