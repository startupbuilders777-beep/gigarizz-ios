import SwiftUI

// MARK: - Coach View

struct CoachView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            EmptyStateView(
                icon: "brain.head.profile",
                title: "Rizz Coach",
                subtitle: "Get AI-powered opening lines, bio reviews, and conversation starters.",
                ctaTitle: "Start Coaching"
            ) {
                DesignSystem.Haptics.light()
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
        }
        .navigationTitle("Coach")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        CoachView()
    }
    .preferredColorScheme(.dark)
}
