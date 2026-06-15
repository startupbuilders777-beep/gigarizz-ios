import SwiftUI

// MARK: - PhotosTabView (V2 tab #2)
//
// Replaces V1's Generate / ToolsHub tabs when V2 is on.
// Three sections, top to bottom:
//   1. Kit photos — every photo from the active ProfileKit (current + generated)
//   2. Missing slots — empty cards that link straight into the right generator
//   3. Photo tools — escape hatch into the SOTA tools (face enhance, outfit, etc)
//
// Encourages the user to think in slots, not tools — the Codex IA shift.

struct PhotosTabView: View {
    @StateObject private var kitStore = ProfileKitStore.shared
    @StateObject private var featureFlags = FeatureFlagManager.shared
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var slotSheet: PhotoArchetype?
    @State private var showAddMenu = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    magicStudioHero

                    if let kit = kitStore.current, !kit.totalPhotos.isZero {
                        kitPhotosSection(kit: kit)
                    } else {
                        emptyState
                    }

                    if let kit = kitStore.current, kit.hasAudit {
                        missingSlotsSection(kit: kit)
                    }

                    photoToolsSection
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.top, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Photos")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink {
                            GenerateView().environmentObject(subscriptionManager)
                        } label: {
                            Label("Generate from style", systemImage: "wand.and.stars")
                        }
                        NavigationLink {
                            FaceEnhancementView()
                        } label: {
                            Label("Face Enhance", systemImage: "face.smiling.fill")
                        }
                        if featureFlags.isEnabled(.outfitStudio) {
                            NavigationLink {
                                AIOutfitChangerView().environmentObject(subscriptionManager)
                            } label: {
                                Label("Outfit Studio", systemImage: "tshirt.fill")
                            }
                        }
                        if featureFlags.isEnabled(.poseStudio) {
                            NavigationLink {
                                PoseStudioView().environmentObject(subscriptionManager)
                            } label: {
                                Label("Pose Studio", systemImage: "figure.wave")
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                }
            }
            .sheet(item: $slotSheet) { archetype in
                MissingSlotActionSheet(archetype: archetype) {
                    slotSheet = nil
                }
                .environmentObject(subscriptionManager)
            }
        }
    }

    // MARK: - Sections

    private var magicStudioHero: some View {
        NavigationLink {
            MagicStudioView()
        } label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Gradients.flameCTA)
                HStack(spacing: 14) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(.white.opacity(0.18))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Magic Studio")
                            .font(DesignSystem.Typography.title)
                            .foregroundStyle(.white)
                        Text("Describe any edit — we plan and do it all, locked to your face.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(16)
            }
            .shadow(color: DesignSystem.Colors.flameOrange.opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        V2HeroCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                    Text("No photos in your kit yet")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
                Text("Run the Upgrade flow to seed your kit, or use the + button to start with a single tool.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                NavigationLink {
                    UpgradeFlowView()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.sparkles")
                        Text("Start Upgrade")
                    }
                    .font(DesignSystem.Typography.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DesignSystem.Gradients.flameCTA)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }
            }
        }
    }

    private func kitPhotosSection(kit: ProfileKit) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader(
                "Your Kit",
                subtitle: "\(kit.totalPhotos) photos · \(kit.targetPlatforms.count) app\(kit.targetPlatforms.count == 1 ? "" : "s")"
            )
            let urls = (kit.currentPhotoUrls + kit.generatedPhotoUrls).compactMap(URL.init(string:))
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(urls.enumerated()), id: \.offset) { _, url in
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(DesignSystem.Colors.surfaceSecondary)
                    }
                    .frame(height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func missingSlotsSection(kit: ProfileKit) -> some View {
        let missing = kit.audit?.missingArchetypes ?? []
        return Group {
            if !missing.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    V2SectionHeader(
                        "Missing Slots",
                        subtitle: "Tap any slot to generate the missing photo."
                    )
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(missing) { archetype in
                            Button {
                                DesignSystem.Haptics.medium()
                                slotSheet = archetype
                            } label: {
                                missingSlotCard(archetype)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func missingSlotCard(_ archetype: PhotoArchetype) -> some View {
        V2Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.hinge.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: archetype.systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.hinge)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                Text(archetype.displayName)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Tap to generate")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
    }

    private var photoToolsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader(
                "Photo Tools",
                subtitle: "One-click upgrades on any photo."
            )
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                photoToolTile(
                    title: "Drop Me In",
                    subtitle: "Any scene you choose",
                    icon: "person.and.background.dotted",
                    tint: DesignSystem.Colors.flameOrange
                ) { AnyView(SceneSwapView()) }
                if featureFlags.isEnabled(.faceEnhance) {
                    photoToolTile(
                        title: "Face Enhance",
                        subtitle: "Anti-plastic retouch",
                        icon: "face.smiling.fill",
                        tint: DesignSystem.Colors.success
                    ) { AnyView(FaceEnhancementView()) }
                }
                if featureFlags.isEnabled(.outfitStudio) {
                    photoToolTile(
                        title: "Outfit Studio",
                        subtitle: "Swap clothes, keep face",
                        icon: "tshirt.fill",
                        tint: DesignSystem.Colors.goldAccent
                    ) { AnyView(AIOutfitChangerView().environmentObject(subscriptionManager)) }
                }
                if featureFlags.isEnabled(.hairstyle) {
                    photoToolTile(
                        title: "Hairstyle",
                        subtitle: "Try-on new looks",
                        icon: "scissors",
                        tint: .pink
                    ) { AnyView(HairstylePickerView().environmentObject(subscriptionManager)) }
                }
                if featureFlags.isEnabled(.poseStudio) {
                    photoToolTile(
                        title: "Pose Studio",
                        subtitle: "Any scene, locked face",
                        icon: "figure.wave",
                        tint: .cyan
                    ) { AnyView(PoseStudioView().environmentObject(subscriptionManager)) }
                }
                if featureFlags.isEnabled(.backgroundReplacer) {
                    photoToolTile(
                        title: "Backgrounds",
                        subtitle: "AI scene replacement",
                        icon: "photo.on.rectangle.angled",
                        tint: DesignSystem.Colors.flameOrange
                    ) { AnyView(BackgroundReplacerView()) }
                }
                if featureFlags.isEnabled(.colorGrade) {
                    photoToolTile(
                        title: "Color Grade",
                        subtitle: "Pro lighting presets",
                        icon: "camera.filters",
                        tint: .purple
                    ) { AnyView(LightingColorGradeView()) }
                }
            }
        }
    }

    private func photoToolTile(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder destination: @escaping () -> AnyView
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            V2Card {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(tint)
                        .frame(width: 44, height: 44)
                        .background(tint.opacity(0.15))
                        .clipShape(Circle())
                    Text(title)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private extension Int {
    var isZero: Bool { self == 0 }
}
