import SwiftUI

/// Interactive preview of how photos would look on Tinder/Hinge/Bumble
struct ProfilePreviewView: View {
    @State private var selectedPlatform: DatingPlatform = .tinder
    @State private var currentPhotoIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var showingInfo = false

    // Mock photos for demo
    private let demoPhotos = [
        "Generated Photo 1",
        "Generated Photo 2",
        "Generated Photo 3",
    ]

    private let demoBio = "Adventure seeker & coffee snob ☕️\nLet's explore the city together 🌆\nSwipe right if you like bad puns"

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    platformPicker
                    phonePreviewCard
                    tipsSection
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Profile Preview")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Platform Picker

    private var platformPicker: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(DatingPlatform.allCases) { platform in
                Button {
                    withAnimation(DesignSystem.Animation.quickSpring) { selectedPlatform = platform }
                    DesignSystem.Haptics.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: platform.icon).font(.system(size: 14))
                        Text(platform.rawValue).font(DesignSystem.Typography.smallButton)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(selectedPlatform == platform ? platform.color.opacity(0.15) : DesignSystem.Colors.surface)
                    .foregroundStyle(selectedPlatform == platform ? platform.color : DesignSystem.Colors.textSecondary)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(selectedPlatform == platform ? platform.color : .clear, lineWidth: 1.5))
                }
            }
        }
        .padding(.top, DesignSystem.Spacing.m)
    }

    // MARK: - Phone Preview

    private var phonePreviewCard: some View {
        VStack(spacing: 0) {
            // Phone frame
            ZStack {
                // Phone body
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.black)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

                // Screen content
                VStack(spacing: 0) {
                    platformHeader
                    photoArea
                    profileInfoArea
                    actionButtons
                }
                .clipShape(RoundedRectangle(cornerRadius: 36))
                .padding(4)
            }
            .frame(height: 560)
        }
    }

    private var platformHeader: some View {
        HStack {
            switch selectedPlatform {
            case .tinder:
                Image(systemName: "flame.fill").foregroundStyle(DesignSystem.Colors.tinder)
                Text("tinder").font(.system(size: 22, weight: .bold)).foregroundStyle(DesignSystem.Colors.tinder)
            case .hinge:
                Image(systemName: "hand.wave.fill").foregroundStyle(DesignSystem.Colors.hinge)
                Text("hinge").font(.system(size: 22, weight: .bold, design: .serif)).foregroundStyle(DesignSystem.Colors.textPrimary)
            case .bumble:
                Image(systemName: "hexagon.fill").foregroundStyle(DesignSystem.Colors.bumble)
                Text("bumble").font(.system(size: 22, weight: .bold)).foregroundStyle(DesignSystem.Colors.bumble)
            case .raya:
                Image(systemName: "star.fill").foregroundStyle(Color(hex: "8B5CF6"))
                Text("raya").font(.system(size: 22, weight: .bold)).foregroundStyle(Color(hex: "8B5CF6"))
            case .general, .other:
                Image(systemName: "heart.fill").foregroundStyle(DesignSystem.Colors.flameOrange)
                Text("dating app").font(.system(size: 22, weight: .bold)).foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            Spacer()
            Image(systemName: "slider.horizontal.3").foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.background)
    }

    private var photoArea: some View {
        ZStack {
            // Photo placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [selectedPlatform.color.opacity(0.2), DesignSystem.Colors.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: DesignSystem.Spacing.s) {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(selectedPlatform.color.opacity(0.5))
                Text("Your AI Photo Here")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Photo dots indicator
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<demoPhotos.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPhotoIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(maxWidth: .infinity, maxHeight: 3)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.s)
                .padding(.top, DesignSystem.Spacing.xs)
                Spacer()
            }

            // Swipe label overlay
            if abs(dragOffset.width) > 40 {
                VStack {
                    Spacer()
                    HStack {
                        if dragOffset.width > 40 {
                            Spacer()
                            likeLabel
                                .padding(.trailing, DesignSystem.Spacing.l)
                        } else {
                            nopeLabel
                                .padding(.leading, DesignSystem.Spacing.l)
                            Spacer()
                        }
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 300)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in dragOffset = value.translation }
                .onEnded { _ in
                    if abs(dragOffset.width) > 50 {
                        DesignSystem.Haptics.medium()
                    }
                    withAnimation(DesignSystem.Animation.quickSpring) { dragOffset = .zero }
                }
        )
        .onTapGesture { location in
            let midPoint = UIScreen.main.bounds.width / 2
            withAnimation(DesignSystem.Animation.quickSpring) {
                if location.x > midPoint {
                    currentPhotoIndex = min(currentPhotoIndex + 1, demoPhotos.count - 1)
                } else {
                    currentPhotoIndex = max(currentPhotoIndex - 1, 0)
                }
            }
        }
    }

    private var likeLabel: some View {
        Text("LIKE")
            .font(.system(size: 32, weight: .heavy))
            .foregroundStyle(DesignSystem.Colors.success)
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(DesignSystem.Colors.success, lineWidth: 3))
            .rotationEffect(.degrees(-15))
    }

    private var nopeLabel: some View {
        Text("NOPE")
            .font(.system(size: 32, weight: .heavy))
            .foregroundStyle(DesignSystem.Colors.error)
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(DesignSystem.Colors.error, lineWidth: 3))
            .rotationEffect(.degrees(15))
    }

    private var profileInfoArea: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("You").font(.system(size: 24, weight: .bold)).foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("25").font(.system(size: 18)).foregroundStyle(DesignSystem.Colors.textPrimary)
                if selectedPlatform == .tinder {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue).font(.system(size: 16))
                }
                Spacer()
                Button { showingInfo.toggle() } label: {
                    Image(systemName: "info.circle").foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            if selectedPlatform == .hinge {
                // Hinge-style prompt
                VStack(alignment: .leading, spacing: 4) {
                    Text("A life goal of mine").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.hinge)
                    Text("To visit every coffee shop in the world ☕️").font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary)
                }
                .padding(DesignSystem.Spacing.s)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
            } else {
                Text(demoBio)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.background)
    }

    private var actionButtons: some View {
        HStack(spacing: DesignSystem.Spacing.l) {
            switch selectedPlatform {
            case .tinder:
                circleButton(icon: "xmark", color: DesignSystem.Colors.error, size: 44)
                circleButton(icon: "star.fill", color: .cyan, size: 36)
                circleButton(icon: "heart.fill", color: DesignSystem.Colors.success, size: 44)
                circleButton(icon: "bolt.fill", color: .purple, size: 36)
            case .hinge:
                circleButton(icon: "xmark", color: DesignSystem.Colors.textSecondary, size: 44)
                Spacer()
                circleButton(icon: "heart.fill", color: DesignSystem.Colors.hinge, size: 44)
            case .bumble:
                circleButton(icon: "xmark", color: DesignSystem.Colors.error, size: 44)
                circleButton(icon: "star.fill", color: DesignSystem.Colors.bumble, size: 36)
                circleButton(icon: "checkmark", color: DesignSystem.Colors.success, size: 44)
            case .raya, .general, .other:
                circleButton(icon: "xmark", color: DesignSystem.Colors.error, size: 44)
                circleButton(icon: "heart.fill", color: DesignSystem.Colors.flameOrange, size: 44)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.background)
    }

    private func circleButton(icon: String, color: Color, size: CGFloat) -> some View {
        Button {
            DesignSystem.Haptics.light()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(color.opacity(0.3), lineWidth: 2)
                    .frame(width: size, height: size)
                Image(systemName: icon)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Profile Tips for \(selectedPlatform.rawValue)").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(tipsForPlatform, id: \.self) { tip in
                GRCard {
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.s) {
                        Image(systemName: "lightbulb.fill").font(.system(size: 14)).foregroundStyle(DesignSystem.Colors.goldAccent).padding(.top, 2)
                        Text(tip).font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary).lineSpacing(3)
                    }
                }
            }
        }
    }

    private var tipsForPlatform: [String] {
        switch selectedPlatform {
        case .tinder:
            return [
                "Lead with your best AI-generated photo — first impressions are everything on Tinder.",
                "Use 4-6 photos showing different sides of your personality.",
                "Outdoor/adventure photos get 19% more right swipes.",
                "Avoid group photos as your first pic — they want to see YOU.",
            ]
        case .hinge:
            return [
                "Hinge is about prompts — pair great photos with witty, specific answers.",
                "Photos with genuine smiles get 2x more likes on Hinge.",
                "Use the voice prompt feature to stand out — very few people do.",
                "Show a hobby or passion in at least one photo.",
            ]
        case .bumble:
            return [
                "Women make the first move on Bumble — make your photos approachable.",
                "Clear, well-lit headshots work best for your primary photo.",
                "Fill out your entire profile — complete profiles get 4x more matches.",
                "Bio badges (interests, lifestyle) help with Bumble's algorithm.",
            ]
        case .raya, .general, .other:
            return [
                "Quality over quantity — 3-5 strong photos beat 9 mediocre ones.",
                "Mix close-ups and full-body shots for a well-rounded profile.",
                "Natural lighting always beats harsh flash or indoor lighting.",
            ]
        }
    }
}

#Preview {
    NavigationStack {
        ProfilePreviewView()
    }
    .preferredColorScheme(.dark)
}
