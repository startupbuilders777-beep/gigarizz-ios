import SwiftUI

// MARK: - Profile View

struct ProfileView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            EmptyStateView(
                icon: "person.crop.circle",
                title: "Your Dating Profile",
                subtitle: "Set up your profile, get photo scores, and optimize for more matches.",
                ctaTitle: "Set Up Profile"
            ) {
                DesignSystem.Haptics.light()
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
        }
        .navigationTitle("Profile")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .preferredColorScheme(.dark)
}
