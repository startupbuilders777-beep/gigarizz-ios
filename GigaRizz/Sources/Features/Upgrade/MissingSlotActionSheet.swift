import SwiftUI

// MARK: - MissingSlotActionSheet
//
// Closes Codex's "missing slot is not actionable" gap. When the user taps a
// missing-archetype tile in the diagnosis, this sheet briefs them on the slot
// and routes to the right generator.
//
// Each archetype maps to one of:
//   - GenerateView with a pre-selected style (most slots)
//   - PoseStudioView (when InstantID identity-locking is the right call)
//   - AIOutfitChangerView (dressed_up)
//   - HairstylePickerView (when grooming is the lift)
//   - A non-generative tip (social_proof — AI shouldn't fabricate friends)

struct MissingSlotActionSheet: View {
    let archetype: PhotoArchetype
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var navigateToTool: SlotTool?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    header

                    if let tool = SlotTool.recommended(for: archetype) {
                        whyCard
                        primaryAction(tool: tool)
                    } else {
                        // Non-generatable archetype (social_proof) — coach the user instead.
                        whyCard
                        manualTipCard
                    }
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(archetype.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                        onDismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
            .navigationDestination(item: $navigateToTool) { tool in
                tool.destination
                    .environmentObject(subscriptionManager)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        V2HeroCard {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.flameOrange.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: archetype.systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("MISSING SLOT")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .tracking(0.8)
                    Text(archetype.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
        }
    }

    private var whyCard: some View {
        V2Card {
            VStack(alignment: .leading, spacing: 6) {
                Text("Why it matters")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text(archetype.whyItMatters)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
    }

    private func primaryAction(tool: SlotTool) -> some View {
        VStack(spacing: 10) {
            V2Card {
                HStack(spacing: 12) {
                    Image(systemName: tool.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .frame(width: 36, height: 36)
                        .background(DesignSystem.Colors.flameOrange.opacity(0.15))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tool.title)
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(tool.subtitle)
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                }
            }
            V2PrimaryButton("Generate", systemImage: "wand.and.sparkles") {
                navigateToTool = tool
            }
        }
    }

    private var manualTipCard: some View {
        V2Card {
            VStack(alignment: .leading, spacing: 8) {
                Label("Use a real photo for this one", systemImage: "person.3.fill")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Social proof works because viewers can tell it's real. Pull a recent photo with friends from your Camera Roll — group dinner, bachelorette, last brunch. Skip if you don't have one.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Slot → tool mapping

enum SlotTool: Hashable, Identifiable {
    case generateStyle(StyleSlug)
    case faceEnhance
    case outfitStudio
    case hairstyle
    case poseStudio

    var id: String {
        switch self {
        case .generateStyle(let s): return "style-\(s.rawValue)"
        case .faceEnhance: return "face_enhance"
        case .outfitStudio: return "outfit_studio"
        case .hairstyle: return "hairstyle"
        case .poseStudio: return "pose_studio"
        }
    }

    var title: String {
        switch self {
        case .generateStyle: return "Generate Photo"
        case .faceEnhance: return "Anti-plastic Face Enhance"
        case .outfitStudio: return "Outfit Studio"
        case .hairstyle: return "Hairstyle Studio"
        case .poseStudio: return "Pose Studio (any scene)"
        }
    }

    var subtitle: String {
        switch self {
        case .generateStyle(let s): return s.subtitle
        case .faceEnhance: return "Sharpen your strongest face shot without making it look fake."
        case .outfitStudio: return "Same face, swap the wardrobe — formal, casual, athletic."
        case .hairstyle: return "Try-on hair without leaving the chair."
        case .poseStudio: return "Drop your face into any scene with InstantID."
        }
    }

    var icon: String {
        switch self {
        case .generateStyle: return "wand.and.stars"
        case .faceEnhance: return "face.smiling.fill"
        case .outfitStudio: return "tshirt.fill"
        case .hairstyle: return "scissors"
        case .poseStudio: return "figure.wave"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .generateStyle:
            GenerateView()
        case .faceEnhance:
            FaceEnhancementView()
        case .outfitStudio:
            AIOutfitChangerView()
        case .hairstyle:
            HairstylePickerView()
        case .poseStudio:
            PoseStudioView()
        }
    }

    /// Maps an archetype to the tool most likely to land a strong photo for that slot.
    static func recommended(for archetype: PhotoArchetype) -> SlotTool? {
        switch archetype {
        case .firstPhoto: return .faceEnhance
        case .casualCandid: return .generateStyle(.casual)
        case .dressedUp: return .outfitStudio
        case .hobbyActivity: return .generateStyle(.adventure)
        case .travelLifestyle: return .poseStudio
        case .socialProof: return nil           // Don't fabricate group photos
        case .fullBody: return .generateStyle(.professional)
        }
    }
}

// MARK: - Style slug

/// Mirrors the most-useful style enum values for slot generation. The string
/// raw values must match the backend's `GenerationStyle` enum keys.
enum StyleSlug: String, Hashable {
    case professional, casual, adventure
    case fitness, nightOut = "night_out"
    case creative, luxury

    var subtitle: String {
        switch self {
        case .professional: return "Sharp, polished portrait — full body or half."
        case .casual: return "Relaxed, candid feel — coffee, walking, smiling at the camera."
        case .adventure: return "Hiking, boat day, surfing — pick a scene that's you."
        case .fitness: return "Gym, run, court — energy without being a thirst trap."
        case .nightOut: return "Going-out look — bar, restaurant, rooftop."
        case .creative: return "Studio, gallery, vinyl — show personality."
        case .luxury: return "Polished evening — date-night, formal, suited."
        }
    }
}
