import SwiftUI

// MARK: - Pose Category

enum PoseCategory: String, CaseIterable, Identifiable {
    case casual
    case confident
    case candid
    case seated
    case leaning
    case walking

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .casual: return "Casual"
        case .confident: return "Confident"
        case .candid: return "Candid"
        case .seated: return "Seated"
        case .leaning: return "Leaning"
        case .walking: return "Walking"
        }
    }

    var icon: String {
        switch self {
        case .casual: return "person.fill"
        case .confident: return "figure.stand"
        case .candid: return "camera.fill"
        case .seated: return "figure.seated.seatbelt"
        case .leaning: return "figure.cooldown"
        case .walking: return "figure.walk"
        }
    }
}

// MARK: - Pose

struct DatingPose: Identifiable {
    let id = UUID()
    let name: String
    let category: PoseCategory
    let description: String
    let tips: [String]
    let matchBoost: String  // e.g. "+25% matches"
    let difficulty: Int     // 1-3
    let bestFor: [String]   // e.g. ["Tinder", "Hinge"]
    let icon: String

    static let library: [DatingPose] = [
        // Casual
        DatingPose(
            name: "The Natural Lean",
            category: .casual,
            description: "Lean one shoulder against a wall, hands in pockets. Relaxed and approachable.",
            tips: ["Keep weight on back foot", "One hand in pocket, one out", "Slight smile, eyes at camera"],
            matchBoost: "+28%",
            difficulty: 1,
            bestFor: ["Tinder", "Bumble", "Hinge"],
            icon: "figure.cooldown"
        ),
        DatingPose(
            name: "Hands in Jacket",
            category: .casual,
            description: "Hands casually in jacket or coat pockets. Works great outdoors.",
            tips: ["Thumbs out of pockets", "Chin slightly up", "Look past the camera"],
            matchBoost: "+22%",
            difficulty: 1,
            bestFor: ["Tinder", "Bumble"],
            icon: "person.fill"
        ),
        DatingPose(
            name: "The Casual Cross",
            category: .casual,
            description: "Arms loosely crossed at chest. Warm expression prevents looking closed off.",
            tips: ["Keep arms loose, not tight", "Smile warmly", "Angle body 30° from camera"],
            matchBoost: "+18%",
            difficulty: 1,
            bestFor: ["Hinge", "Raya"],
            icon: "person.fill"
        ),
        DatingPose(
            name: "Coffee Shop Hold",
            category: .casual,
            description: "Hold a coffee cup naturally. Creates a cozy, date-ready vibe.",
            tips: ["Hold cup at chest level", "Both hands or one", "Genuine smile"],
            matchBoost: "+20%",
            difficulty: 1,
            bestFor: ["Hinge", "Bumble"],
            icon: "cup.and.saucer.fill"
        ),
        DatingPose(
            name: "Looking Away",
            category: .casual,
            description: "Look off to the side with a subtle smile. Mysterious and attractive.",
            tips: ["Turn head 45°", "Slight smile on lips", "Good jaw angle"],
            matchBoost: "+24%",
            difficulty: 1,
            bestFor: ["Tinder", "Raya"],
            icon: "eye"
        ),

        // Confident
        DatingPose(
            name: "Power Stance",
            category: .confident,
            description: "Stand with feet shoulder-width apart, hands at sides or one in pocket.",
            tips: ["Square shoulders to camera", "Feet shoulder-width apart", "Chin level, not up"],
            matchBoost: "+32%",
            difficulty: 2,
            bestFor: ["Tinder", "Bumble"],
            icon: "figure.stand"
        ),
        DatingPose(
            name: "The Laughing Look",
            category: .confident,
            description: "Mid-laugh with genuine joy. The #1 most-swiped-right expression.",
            tips: ["Think of something genuinely funny", "Open mouth laugh is OK", "Crinkle eyes"],
            matchBoost: "+45%",
            difficulty: 2,
            bestFor: ["Tinder", "Bumble", "Hinge", "Raya"],
            icon: "face.smiling.inverse"
        ),
        DatingPose(
            name: "Suit Adjustment",
            category: .confident,
            description: "Straighten a tie, adjust cuffs, or hold lapels. Photos confidence + style.",
            tips: ["One-handed adjustment", "Look at camera", "Slight smirk"],
            matchBoost: "+35%",
            difficulty: 2,
            bestFor: ["Raya", "Hinge"],
            icon: "tshirt.fill"
        ),
        DatingPose(
            name: "Arms Behind Head",
            category: .confident,
            description: "One or both arms behind head. Relaxed alpha energy.",
            tips: ["Works best seated or standing", "Keep expression soft", "Show your watch/bracelet"],
            matchBoost: "+20%",
            difficulty: 2,
            bestFor: ["Tinder", "Bumble"],
            icon: "figure.stand"
        ),
        DatingPose(
            name: "Hands on Hips",
            category: .confident,
            description: "Classic confident pose. Works well for full-body shots.",
            tips: ["Don't press hands in", "Elbows out slightly", "Big smile"],
            matchBoost: "+15%",
            difficulty: 1,
            bestFor: ["Bumble", "Hinge"],
            icon: "figure.stand"
        ),

        // Candid
        DatingPose(
            name: "The Mid-Activity",
            category: .candid,
            description: "Captured 'in the moment' — cooking, hiking, playing guitar, etc.",
            tips: ["Actually do the activity", "Photographer shoots from the side", "Natural expression"],
            matchBoost: "+38%",
            difficulty: 2,
            bestFor: ["Hinge", "Bumble"],
            icon: "camera.fill"
        ),
        DatingPose(
            name: "Over the Shoulder",
            category: .candid,
            description: "Look back over your shoulder at the camera. Flirty and engaging.",
            tips: ["Turn body away, look back", "Smile coyly", "Works great walking away from camera"],
            matchBoost: "+30%",
            difficulty: 2,
            bestFor: ["Tinder", "Raya"],
            icon: "arrow.turn.up.right"
        ),
        DatingPose(
            name: "Petting an Animal",
            category: .candid,
            description: "With a dog, cat, or any animal. Massive match boost.",
            tips: ["Real interaction with animal", "Eye contact with animal or camera", "Genuine joy"],
            matchBoost: "+52%",
            difficulty: 1,
            bestFor: ["Tinder", "Bumble", "Hinge"],
            icon: "pawprint.fill"
        ),
        DatingPose(
            name: "The Friend Photo",
            category: .candid,
            description: "Laughing with friends in a group. Shows you're social.",
            tips: ["You should be clearly identifiable", "Crop after to show 2-3 people max", "Real laughing"],
            matchBoost: "+25%",
            difficulty: 1,
            bestFor: ["Hinge", "Bumble"],
            icon: "person.3.fill"
        ),
        DatingPose(
            name: "Travel Discovery",
            category: .candid,
            description: "Looking out at a view, exploring a new city, or reacting to something.",
            tips: ["Include scenery context", "Body turned, face in profile or 3/4", "Natural awe expression"],
            matchBoost: "+28%",
            difficulty: 1,
            bestFor: ["Hinge", "Raya"],
            icon: "airplane"
        ),

        // Seated
        DatingPose(
            name: "The Restaurant Lean",
            category: .seated,
            description: "Lean forward slightly at a table. Engaged and date-ready.",
            tips: ["Forearms on table", "Head tilted slightly", "Warm eye contact"],
            matchBoost: "+22%",
            difficulty: 1,
            bestFor: ["Hinge", "Bumble"],
            icon: "fork.knife"
        ),
        DatingPose(
            name: "Couch Relaxed",
            category: .seated,
            description: "Lounging casually on a nice couch or chair. Lifestyle shot.",
            tips: ["Arm along back of couch", "One leg crossed", "Relaxed smile"],
            matchBoost: "+18%",
            difficulty: 1,
            bestFor: ["Raya", "Hinge"],
            icon: "sofa.fill"
        ),
        DatingPose(
            name: "Bar Stool",
            category: .seated,
            description: "Sitting at a bar with a drink. Night-out energy.",
            tips: ["Hold drink casually", "Twist toward camera", "Dim lighting flatters"],
            matchBoost: "+20%",
            difficulty: 1,
            bestFor: ["Tinder", "Bumble"],
            icon: "wineglass.fill"
        ),
        DatingPose(
            name: "Bench in Nature",
            category: .seated,
            description: "Seated on a bench, steps, or rock outdoors. Relaxed and grounded.",
            tips: ["Lean back slightly", "One arm on knee", "Golden hour lighting"],
            matchBoost: "+26%",
            difficulty: 1,
            bestFor: ["Hinge", "Bumble"],
            icon: "leaf.fill"
        ),
        DatingPose(
            name: "Floor Sitting",
            category: .seated,
            description: "Sitting on the floor with legs crossed or extended. Artsy vibes.",
            tips: ["Works best in studios or clean spaces", "Lean on one arm", "Look up at camera"],
            matchBoost: "+15%",
            difficulty: 2,
            bestFor: ["Raya"],
            icon: "figure.seated.side"
        ),

        // Leaning
        DatingPose(
            name: "Wall Lean",
            category: .leaning,
            description: "One shoulder against a textured wall. Classic and versatile.",
            tips: ["Foot flat against wall", "Face the camera at 45°", "One hand in pocket"],
            matchBoost: "+30%",
            difficulty: 1,
            bestFor: ["Tinder", "Bumble", "Hinge"],
            icon: "figure.cooldown"
        ),
        DatingPose(
            name: "Railing Lean",
            category: .leaning,
            description: "Lean on a railing or fence, facing camera. Great with a view behind.",
            tips: ["Elbows on railing", "Body facing camera", "Relaxed shoulders"],
            matchBoost: "+24%",
            difficulty: 1,
            bestFor: ["Hinge", "Raya"],
            icon: "rectangle.split.3x1"
        ),
        DatingPose(
            name: "Car Lean",
            category: .leaning,
            description: "Lean against a nice car. Status + casual confidence.",
            tips: ["Arms crossed loosely", "Don't block the car entirely", "Slight smirk"],
            matchBoost: "+20%",
            difficulty: 1,
            bestFor: ["Tinder", "Raya"],
            icon: "car.fill"
        ),
        DatingPose(
            name: "Doorway Lean",
            category: .leaning,
            description: "Lean in a doorway or archway. Beautiful framing device.",
            tips: ["One arm up on door frame", "Body turned slightly", "Moody lighting"],
            matchBoost: "+26%",
            difficulty: 2,
            bestFor: ["Raya", "Hinge"],
            icon: "door.left.hand.open"
        ),
        DatingPose(
            name: "Table Lean",
            category: .leaning,
            description: "Lean against a table or counter with hands supporting. Casual authority.",
            tips: ["Hands on edge of table behind you", "Legs crossed or straight", "Head slightly tilted"],
            matchBoost: "+18%",
            difficulty: 1,
            bestFor: ["Bumble", "Hinge"],
            icon: "table.furniture.fill"
        ),

        // Walking
        DatingPose(
            name: "The Confident Stride",
            category: .walking,
            description: "Mid-stride walking toward camera. Dynamic and confident.",
            tips: ["Look at camera", "Natural arm swing", "Photographer shoots slightly low angle"],
            matchBoost: "+33%",
            difficulty: 3,
            bestFor: ["Tinder", "Bumble"],
            icon: "figure.walk"
        ),
        DatingPose(
            name: "Walking Away",
            category: .walking,
            description: "Walking away from camera, looking back. Mysterious and cinematic.",
            tips: ["Walk slowly", "Look back over shoulder", "Cool urban backdrop"],
            matchBoost: "+28%",
            difficulty: 2,
            bestFor: ["Raya", "Hinge"],
            icon: "figure.walk"
        ),
        DatingPose(
            name: "Street Cross",
            category: .walking,
            description: "Crossing a street or walkway. Urban lifestyle shot.",
            tips: ["Hands in pockets or holding bag", "Eyes forward", "Busy backdrop adds energy"],
            matchBoost: "+22%",
            difficulty: 3,
            bestFor: ["Tinder", "Raya"],
            icon: "figure.walk"
        ),
        DatingPose(
            name: "Beach Walk",
            category: .walking,
            description: "Walking along a beach. Classic romantic setting.",
            tips: ["Barefoot if on sand", "Hold shoes in one hand", "Golden hour mandatory"],
            matchBoost: "+35%",
            difficulty: 1,
            bestFor: ["Tinder", "Bumble", "Hinge"],
            icon: "beach.umbrella.fill"
        ),
        DatingPose(
            name: "Staircase Ascend",
            category: .walking,
            description: "Walking up stairs, hand on railing. Creates height and structure.",
            tips: ["Shot from below for best angle", "Look down at camera", "Interesting staircase helps"],
            matchBoost: "+20%",
            difficulty: 2,
            bestFor: ["Raya", "Hinge"],
            icon: "figure.stairs"
        ),
    ]
}

// MARK: - Pose Library View

struct PoseLibraryView: View {
    @State private var selectedCategory: PoseCategory = .casual
    @State private var selectedPose: DatingPose?
    @State private var searchText = ""

    private var filteredPoses: [DatingPose] {
        let categoryPoses = DatingPose.library.filter { $0.category == selectedCategory }
        if searchText.isEmpty { return categoryPoses }
        return categoryPoses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Category picker
                categoryPicker
                    .padding(.top, DesignSystem.Spacing.small)

                // Poses list
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: DesignSystem.Spacing.small) {
                        ForEach(filteredPoses) { pose in
                            poseCard(pose)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedPose = selectedPose?.id == pose.id ? nil : pose
                                    }
                                    DesignSystem.Haptics.light()
                                }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Pose Library")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search poses...")
        .onAppear {
            PostHogManager.shared.trackEvent("pose_library_opened")
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.small) {
                ForEach(PoseCategory.allCases) { category in
                    Button {
                        withAnimation { selectedCategory = category }
                        DesignSystem.Haptics.light()
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.displayName)
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(selectedCategory == category ? .white : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedCategory == category
                                ? DesignSystem.Colors.flameOrange
                                : DesignSystem.Colors.surface
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
        }
    }

    // MARK: - Pose Card

    private func poseCard(_ pose: DatingPose) -> some View {
        let isExpanded = selectedPose?.id == pose.id

        return GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack(spacing: DesignSystem.Spacing.medium) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.flameOrange.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: pose.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pose.name)
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text(pose.description)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }

                    Spacer()

                    // Match boost badge
                    Text(pose.matchBoost)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(DesignSystem.Colors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.success.opacity(0.15))
                        .clipShape(Capsule())
                }

                if isExpanded {
                    Divider()
                        .background(DesignSystem.Colors.divider)

                    // Tips
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Pro Tips")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.goldAccent)

                        ForEach(pose.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DesignSystem.Colors.success)
                                Text(tip)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                            }
                        }
                    }

                    // Best for platforms
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Best for:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        ForEach(pose.bestFor, id: \.self) { platform in
                            Text(platform)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(platformColor(platform))
                                .clipShape(Capsule())
                        }
                        Spacer()

                        // Difficulty
                        HStack(spacing: 2) {
                            ForEach(0..<3) { i in
                                Circle()
                                    .fill(i < pose.difficulty ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
            }
        }
    }

    private func platformColor(_ platform: String) -> Color {
        switch platform {
        case "Tinder": return DesignSystem.Colors.flameOrange
        case "Hinge": return DesignSystem.Colors.hinge
        case "Bumble": return DesignSystem.Colors.bumble
        case "Raya": return .purple
        default: return DesignSystem.Colors.surface
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PoseLibraryView()
    }
    .preferredColorScheme(.dark)
}
