import SwiftUI

struct AddMatchView: View {
    @ObservedObject var viewModel: MatchesViewModel
    @State private var name = ""
    @State private var platform: DatingPlatform = .tinder
    @State private var notes = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Name").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                            TextField("Match name", text: $name)
                                .textFieldStyle(.plain).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary)
                                .padding(DesignSystem.Spacing.m).background(DesignSystem.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        }
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Platform").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                ForEach(DatingPlatform.allCases) { p in
                                    Button {
                                        platform = p; DesignSystem.Haptics.light()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: p.icon).font(.system(size: 14))
                                            Text(p.rawValue).font(DesignSystem.Typography.smallButton)
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.s).padding(.vertical, DesignSystem.Spacing.xs)
                                        .background(platform == p ? p.color.opacity(0.15) : DesignSystem.Colors.surface)
                                        .foregroundStyle(platform == p ? p.color : DesignSystem.Colors.textSecondary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().strokeBorder(platform == p ? p.color : .clear, lineWidth: 1.5))
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Notes (optional)").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
                            TextField("Interests, conversation notes...", text: $notes, axis: .vertical)
                                .textFieldStyle(.plain).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary)
                                .lineLimit(3...6)
                                .padding(DesignSystem.Spacing.m).background(DesignSystem.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        }
                        GRButton(title: "Add Match", icon: "heart.fill", isDisabled: name.isEmpty) {
                            viewModel.addMatch(Match(name: name, platform: platform, notes: notes)); dismiss()
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m).padding(.top, DesignSystem.Spacing.l)
                }
            }
            .navigationTitle("Add Match").navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.foregroundStyle(DesignSystem.Colors.textSecondary) } }
        }
    }
}

#Preview { AddMatchView(viewModel: MatchesViewModel()).preferredColorScheme(.dark) }
