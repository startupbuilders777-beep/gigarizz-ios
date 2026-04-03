import SwiftUI

// MARK: - Generation Tips View

/// Rotating tips carousel shown during photo generation loading
struct GenerationTipsView: View {
    @State private var currentTipIndex = 0
    let timer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()

    private let tips: [(icon: String, title: String, body: String)] = [
        ("flame.fill", "First Photo = Everything",
         "Your first photo gets 90% of the attention. Make it count with great lighting and a genuine smile."),
        ("person.2.fill", "Show Variety",
         "Profiles with 4-6 diverse photos get 3x more matches than single-style profiles."),
        ("camera.fill", "Eye Contact Wins",
         "Photos where you look directly at the camera create 2x more connection than looking away."),
        ("sun.max.fill", "Golden Hour Magic",
         "Photos taken during golden hour (sunrise/sunset) get 40% more likes on dating apps."),
        ("figure.walk", "Full Body Shots Matter",
         "Including at least one full-body photo increases match rates by 203% according to Hinge."),
        ("face.smiling.fill", "Smile > Serious",
         "Genuine smiles get 2x more right swipes than serious or moody expressions."),
        ("dog.fill", "The Pet Effect",
         "Photos with dogs get 5x more conversation starters. Thank us later."),
        ("fork.knife", "Food Photos Work",
         "Pics at restaurants or cooking show you're interesting. Just skip the blurry ones."),
        ("airplane", "Travel Photos",
         "Showing adventure in your profile makes you 48% more attractive in Bumble studies."),
        ("tshirt.fill", "Dress Up",
         "Wearing fitted, well-coordinated outfits increases perceived attractiveness by 30%."),
        ("sparkles", "AI Advantage",
         "GigaRizz users get 4.2x more matches in their first week. You're ahead of the game."),
        ("person.crop.rectangle", "Crop Smart",
         "Chest-up photos perform best for main pics. Save full body shots for slots 3-4."),
        ("paintbrush.fill", "Background Matters",
         "Clean, interesting backgrounds beat messy rooms every time. Think cafés, parks, skylines."),
        ("hands.clap.fill", "Group Photos",
         "One group photo shows you're social, but never make it your first. They should find YOU."),
        ("bolt.fill", "Update Regularly",
         "Refreshing your photos every 2-3 weeks keeps the algorithm working in your favor.")
    ]

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.goldAccent)
                Text("PRO TIP")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.goldAccent)
                Spacer()
                // Dot indicators
                HStack(spacing: 4) {
                    ForEach(0..<min(tips.count, 5), id: \.self) { i in
                        Circle()
                            .fill(
                                i == (currentTipIndex % 5)
                                ? DesignSystem.Colors.flameOrange
                                : DesignSystem.Colors.textSecondary.opacity(0.3)
                            )
                            .frame(width: 5, height: 5)
                    }
                }
            }

            HStack(alignment: .top, spacing: DesignSystem.Spacing.s) {
                Image(systemName: tips[currentTipIndex].icon)
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tips[currentTipIndex].title)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(tips[currentTipIndex].body)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(3)
                }
            }
            .id(currentTipIndex) // key for transition
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .padding(DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .onReceive(timer) { _ in
            withAnimation(DesignSystem.Animation.smoothSpring) {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
        .onAppear {
            currentTipIndex = Int.random(in: 0..<tips.count)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        GenerationTipsView()
            .padding()
    }
}
