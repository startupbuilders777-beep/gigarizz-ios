import SwiftUI

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var animateCharts = false

    enum TimeRange: String, CaseIterable { case week = "7D", month = "30D", allTime = "All" }

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    timeRangePicker
                    heroStatsRow
                    generationChartCard
                    matchRateCard
                    platformBreakdownCard
                    stylePerformanceCard
                    streakCard
                    insightsCard
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Analytics")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadAnalytics()
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) { animateCharts = true }
        }
    }

    private var timeRangePicker: some View {
        HStack(spacing: 4) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTimeRange = range }
                } label: {
                    Text(range.rawValue)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(selectedTimeRange == range ? .bold : .regular)
                        .foregroundStyle(selectedTimeRange == range ? DesignSystem.Colors.background : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(selectedTimeRange == range ? DesignSystem.Colors.flameOrange : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4).background(DesignSystem.Colors.surface).clipShape(Capsule())
    }

    private var heroStatsRow: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            heroStat(value: "\(viewModel.analytics?.totalGenerations ?? 0)", label: "Photos", icon: "photo.stack.fill", color: DesignSystem.Colors.flameOrange)
            heroStat(value: "\(viewModel.analytics?.totalMatches ?? 0)", label: "Matches", icon: "heart.fill", color: .pink)
            heroStat(value: String(format: "%.0f%%", viewModel.analytics?.matchRate ?? 0), label: "Rate", icon: "chart.line.uptrend.xyaxis", color: .green)
        }
    }

    private func heroStat(value: String, label: String, icon: String, color: Color) -> some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color)
                Text(value).font(DesignSystem.Typography.title).foregroundStyle(DesignSystem.Colors.textPrimary).fontWeight(.bold)
                Text(label).font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
            }.frame(maxWidth: .infinity)
        }
    }

    private var generationChartCard: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Photo Generations").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Last 7 days").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                    Text("\(viewModel.weeklyTotal) total").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.flameOrange).fontWeight(.semibold)
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(viewModel.weeklyGenerations.enumerated()), id: \.offset) { index, count in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent], startPoint: .bottom, endPoint: .top))
                                .frame(height: animateCharts ? max(4, CGFloat(count) / CGFloat(max(viewModel.weeklyMax, 1)) * 80) : 4)
                            Text(viewModel.dayLabel(for: index)).font(.system(size: 10)).foregroundStyle(DesignSystem.Colors.textSecondary)
                        }.frame(maxWidth: .infinity)
                    }
                }.frame(height: 100)
            }
        }
    }

    private var matchRateCard: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Match Rate Trend").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array(viewModel.matchRateTrend.enumerated()), id: \.offset) { index, rate in
                        Rectangle()
                            .fill(rate > (index > 0 ? viewModel.matchRateTrend[index - 1] : rate) ? Color.green.opacity(0.6) : Color.orange.opacity(0.6))
                            .frame(height: animateCharts ? max(2, CGFloat(rate) / 100.0 * 60) : 2)
                            .frame(maxWidth: .infinity)
                    }
                }.frame(height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
                HStack {
                    Text("Current: \(String(format: "%.1f", viewModel.analytics?.matchRate ?? 0))%").font(DesignSystem.Typography.caption).foregroundStyle(.green)
                    Spacer()
                    Label("\(viewModel.matchRateChange >= 0 ? "+" : "")\(String(format: "%.1f", viewModel.matchRateChange))%", systemImage: viewModel.matchRateChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(DesignSystem.Typography.caption).foregroundStyle(viewModel.matchRateChange >= 0 ? .green : .red)
                }
            }
        }
    }

    private var platformBreakdownCard: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Platform Breakdown").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                ForEach(viewModel.platformStats, id: \.platform) { stat in
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Circle().fill(stat.color).frame(width: 10, height: 10)
                        Text(stat.platform).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Text("\(stat.matches)").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textSecondary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(DesignSystem.Colors.surface).frame(height: 6)
                                RoundedRectangle(cornerRadius: 3).fill(stat.color)
                                    .frame(width: animateCharts ? geo.size.width * CGFloat(stat.percentage) / 100.0 : 0, height: 6)
                            }
                        }.frame(width: 60, height: 6)
                    }
                }
            }
        }
    }

    private var stylePerformanceCard: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Top Performing Styles").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                ForEach(viewModel.styleStats) { stat in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.style).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("\(stat.generationCount) photos").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.0f", stat.matchRate))%").font(DesignSystem.Typography.callout).foregroundStyle(stat.matchRate > 30 ? .green : DesignSystem.Colors.flameOrange).fontWeight(.bold)
                            Text("match rate").font(.system(size: 10)).foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    if stat.id != viewModel.styleStats.last?.id { Divider().overlay(DesignSystem.Colors.surface) }
                }
            }
        }
    }

    private var streakCard: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("\u{1F525}").font(.system(size: 32))
                    Text("\(viewModel.analytics?.streakDays ?? 0)").font(DesignSystem.Typography.title).foregroundStyle(DesignSystem.Colors.flameOrange).fontWeight(.bold)
                    Text("Day Streak").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                }.frame(maxWidth: .infinity)
                Divider().frame(height: 60).overlay(DesignSystem.Colors.surface)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    achievementRow(icon: "\u{1F3C6}", text: "First Photo", done: true)
                    achievementRow(icon: "\u{2B50}", text: "10 Photos Club", done: (viewModel.analytics?.totalGenerations ?? 0) >= 10)
                    achievementRow(icon: "\u{1F48E}", text: "Match Master", done: (viewModel.analytics?.totalMatches ?? 0) >= 25)
                    achievementRow(icon: "\u{1F525}", text: "7-Day Streak", done: (viewModel.analytics?.streakDays ?? 0) >= 7)
                }.frame(maxWidth: .infinity)
            }
        }
    }

    private func achievementRow(icon: String, text: String, done: Bool) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text(icon).font(.system(size: 14)).opacity(done ? 1 : 0.3)
            Text(text).font(.system(size: 12)).foregroundStyle(done ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary).strikethrough(done, color: DesignSystem.Colors.flameOrange)
        }
    }

    private var insightsCard: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Label("AI Insights", systemImage: "brain.head.profile").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                ForEach(viewModel.insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "lightbulb.fill").font(.system(size: 12)).foregroundStyle(DesignSystem.Colors.goldAccent)
                        Text(insight).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

#Preview { NavigationStack { AnalyticsDashboardView() }.preferredColorScheme(.dark) }
