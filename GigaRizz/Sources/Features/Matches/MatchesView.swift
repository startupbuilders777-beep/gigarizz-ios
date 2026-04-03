import SwiftUI

// MARK: - Matches View

struct MatchesView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            EmptyStateView(
                icon: "heart.circle",
                title: "Your Matches",
                subtitle: "Track your matches, reply rates, and never miss a conversation.",
                ctaTitle: "View Matches"
            ) {
                DesignSystem.Haptics.light()
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
        }
        .navigationTitle("Matches")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        MatchesView()
    }
    .preferredColorScheme(.dark)
}
