import SwiftUI

struct MatchesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var showAddMatch = false
    @State private var selectedMatch: Match?

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            if viewModel.matches.isEmpty {
                EmptyStateView(icon: "heart.circle", title: "No Matches Yet", subtitle: "Add your matches to track conversations and never miss a follow-up.", ctaTitle: "Add First Match") { showAddMatch = true }
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.large) { statsBar; matchList }
                    .padding(.horizontal, DesignSystem.Spacing.medium).padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Matches").toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddMatch = true } label: { Image(systemName: "plus.circle.fill").foregroundStyle(DesignSystem.Colors.flameOrange) }
            }
        }
        .sheet(isPresented: $showAddMatch) { AddMatchView(viewModel: viewModel) }
        .sheet(item: $selectedMatch) { match in MatchDetailView(match: match, viewModel: viewModel) }
    }

    private var statsBar: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            statCard(count: viewModel.matches.count, label: "Total", color: DesignSystem.Colors.flameOrange)
            statCard(count: viewModel.activeCount, label: "Active", color: DesignSystem.Colors.success)
            statCard(count: viewModel.staleCount, label: "Stale", color: DesignSystem.Colors.warning)
            statCard(count: viewModel.scheduledCount, label: "Dates", color: .cyan)
        }.padding(.top, DesignSystem.Spacing.medium)
    }

    private func statCard(count: Int, label: String, color: Color) -> some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.micro) {
                Text("\(count)").font(DesignSystem.Typography.headline).foregroundStyle(color)
                Text(label).font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
            }.frame(maxWidth: .infinity)
        }
    }

    private var matchList: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(viewModel.matches) { match in
                Button { selectedMatch = match } label: { matchRow(match) }
            }
        }
    }

    private func matchRow(_ match: Match) -> some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                ZStack {
                    Circle().fill(match.platform.color.opacity(0.2)).frame(width: 48, height: 48)
                    Text(String(match.name.prefix(1))).font(DesignSystem.Typography.title).foregroundStyle(match.platform.color)
                }
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    HStack {
                        Text(match.name).font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                        Image(systemName: match.platform.icon).font(.system(size: 12)).foregroundStyle(match.platform.color)
                    }
                    if let days = match.daysSinceLastMessage {
                        Text(days == 0 ? "Messaged today" : "\(days)d since last message")
                            .font(DesignSystem.Typography.footnote).foregroundStyle(match.isStale ? DesignSystem.Colors.warning : DesignSystem.Colors.textSecondary)
                    } else {
                        Text("No messages yet").font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                Spacer()
                HStack(spacing: DesignSystem.Spacing.micro) {
                    Image(systemName: match.status.icon).font(.system(size: 12))
                    Text(match.status.rawValue).font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(match.status.color)
                .padding(.horizontal, DesignSystem.Spacing.xs).padding(.vertical, 4)
                .background(match.status.color.opacity(0.1)).clipShape(Capsule())
            }
        }
    }
}

#Preview { NavigationStack { MatchesView() }.preferredColorScheme(.dark) }
