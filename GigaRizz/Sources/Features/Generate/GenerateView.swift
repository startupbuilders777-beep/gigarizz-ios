import SwiftUI

// MARK: - Generate View

struct GenerateView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            EmptyStateView(
                icon: "wand.and.stars",
                title: "AI Photo Generator",
                subtitle: "Transform your selfies into magazine-quality dating photos with AI magic.",
                ctaTitle: "Start Generating"
            ) {
                DesignSystem.Haptics.light()
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
        }
        .navigationTitle("Generate")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        GenerateView()
    }
    .preferredColorScheme(.dark)
}
