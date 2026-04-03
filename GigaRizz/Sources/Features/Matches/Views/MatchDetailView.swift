import SwiftUI

struct MatchDetailView: View {
    let match: Match
    @ObservedObject var viewModel: MatchesViewModel
    @State private var suggestedReplies: [String] = []
    @State private var isLoadingReplies = false
    @State private var showChat = false
    @Environment(\.dismiss) private var dismiss

    private let coachService = CoachService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        matchHeader
                        openChatButton
                        statusUpdateSection
                        if !match.notes.isEmpty { notesSection }
                        aiReplySection
                        deleteButton
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium).padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(DesignSystem.Colors.textSecondary) } } }
            .sheet(isPresented: $showChat) { ChatView(match: match) }
        }
    }

    private var matchHeader: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                Circle().fill(match.platform.color.opacity(0.2)).frame(width: 80, height: 80)
                Text(String(match.name.prefix(1))).font(DesignSystem.Typography.scoreLarge).foregroundStyle(match.platform.color)
            }
            Text(match.name).font(DesignSystem.Typography.headline).foregroundStyle(DesignSystem.Colors.textPrimary)
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: match.platform.icon).foregroundStyle(match.platform.color)
                Text(match.platform.rawValue).font(DesignSystem.Typography.subheadline).foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("\u{00B7}").foregroundStyle(DesignSystem.Colors.textSecondary)
                HStack(spacing: 4) { Image(systemName: match.status.icon); Text(match.status.rawValue) }
                    .font(DesignSystem.Typography.caption).foregroundStyle(match.status.color)
            }
        }.padding(.top, DesignSystem.Spacing.medium)
    }

    private var openChatButton: some View {
        GRButton(
            title: "Open Chat",
            icon: "message.fill",
            style: .primary
        ) {
            showChat = true
            DesignSystem.Haptics.light()
        }
    }

    private var statusUpdateSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Update Status").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(MatchStatus.allCases) { status in
                        Button { viewModel.updateStatus(match, to: status) } label: {
                            HStack(spacing: 4) {
                                Image(systemName: status.icon).font(.system(size: 12))
                                Text(status.rawValue).font(DesignSystem.Typography.caption)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.small).padding(.vertical, DesignSystem.Spacing.xs)
                            .background(match.status == status ? status.color.opacity(0.15) : DesignSystem.Colors.surface)
                            .foregroundStyle(match.status == status ? status.color : DesignSystem.Colors.textSecondary)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Notes").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                Text(match.notes).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var aiReplySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Label("AI Reply Suggestions", systemImage: "sparkles").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
            GRButton(title: "Get Reply Ideas", icon: "brain.head.profile", style: .secondary, isLoading: isLoadingReplies) {
                Task {
                    isLoadingReplies = true
                    if let replies = try? await coachService.suggestReply(to: "Hey", matchName: match.name) { suggestedReplies = replies }
                    isLoadingReplies = false
                }
            }
            ForEach(Array(suggestedReplies.enumerated()), id: \.offset) { _, reply in
                GRCard {
                    HStack {
                        Text(reply).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Button { UIPasteboard.general.string = reply; DesignSystem.Haptics.success() } label: {
                            Image(systemName: "doc.on.doc").foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    }
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) { viewModel.deleteMatch(match); dismiss() } label: {
            Label("Delete Match", systemImage: "trash").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.error)
        }.padding(.top, DesignSystem.Spacing.large)
    }
}

#Preview { MatchDetailView(match: Match.demoMatches[0], viewModel: MatchesViewModel()).preferredColorScheme(.dark) }
