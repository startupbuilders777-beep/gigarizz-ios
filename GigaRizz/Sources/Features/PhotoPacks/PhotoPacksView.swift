import SwiftUI

// MARK: - Photo Packs View

struct PhotoPacksView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedPlatform: DatingPlatform? 
    @State private var selectedPack: PhotoPack? 
    @State private var showPackDetail = false
    @State private var showPaywall = false

    private var filteredPacks: [PhotoPack] {
        guard let platform = selectedPlatform else { return PhotoPack.allPacks }
        return PhotoPack.allPacks.filter { $0.platform == platform || $0.platform == .general }
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.large) {
                    headerSection
                    platformFilter
                    packsGrid
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Photo Packs")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedPack) { pack in
            PackDetailSheet(pack: pack)
                .environmentObject(subscriptionManager)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo Packs")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Platform-optimized photo sets, one tap to generate all 6")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.small)
    }

    // MARK: - Platform Filter

    private var platformFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                platformChip(nil, name: "All", icon: "square.grid.2x2.fill")
                ForEach(DatingPlatform.allCases.filter { $0 != .general }) { platform in
                    platformChip(platform, name: platform.rawValue, icon: platform.icon)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func platformChip(_ platform: DatingPlatform?, name: String, icon: String) -> some View {
        let isSelected = selectedPlatform == platform
        return Button {
            withAnimation(DesignSystem.Animation.quickSpring) { selectedPlatform = platform }
            DesignSystem.Haptics.light()
        } label: {
            HStack(spacing: DesignSystem.Spacing.micro) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(name)
                    .font(DesignSystem.Typography.smallButton)
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                isSelected
                ? AnyShapeStyle(platform?.color ?? DesignSystem.Colors.flameOrange)
                : AnyShapeStyle(DesignSystem.Colors.surface)
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - Packs Grid

    private var packsGrid: some View {
        LazyVStack(spacing: DesignSystem.Spacing.medium) {
            ForEach(filteredPacks) { pack in
                PackCard(pack: pack, isLocked: shouldLock(pack)) {
                    if shouldLock(pack) {
                        showPaywall = true
                    } else {
                        selectedPack = pack
                    }
                }
            }
        }
    }

    private func shouldLock(_ pack: PhotoPack) -> Bool {
        switch subscriptionManager.currentTier {
        case .gold: return false
        case .plus: return pack.tier == .gold
        case .free: return pack.tier != .free
        }
    }
}

// MARK: - Pack Card

struct PackCard: View {
    let pack: PhotoPack
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header with gradient
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: pack.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)

                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: pack.icon)
                                    .font(.system(size: 16))
                                Text(pack.name)
                                    .font(DesignSystem.Typography.title)
                            }
                            .foregroundStyle(.white)

                            if let platform = pack.platform, platform != .general {
                                Text("Optimized for \(platform.rawValue)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }

                        Spacer()

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(8)
                                .background(Circle().fill(.black.opacity(0.3)))
                        } else {
                            Text("\(pack.photoCount) photos")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.white.opacity(0.2)))
                        }
                    }
                    .padding(DesignSystem.Spacing.medium)
                }

                // Description and photo types preview
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text(pack.description)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)

                    // Photo type icons row
                    HStack(spacing: DesignSystem.Spacing.small) {
                        ForEach(pack.photoTypes.prefix(5)) { photoType in
                            VStack(spacing: 2) {
                                Image(systemName: photoType.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                                    .frame(width: 32, height: 32)
                                    .background(DesignSystem.Colors.flameOrange.opacity(0.1))
                                    .clipShape(Circle())
                                Text(photoType.name)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        if pack.photoTypes.count > 5 {
                            VStack(spacing: 2) {
                                Text("+\(pack.photoTypes.count - 5)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(DesignSystem.Colors.surfaceSecondary)
                                    .clipShape(Circle())
                                Text("more")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(DesignSystem.Spacing.medium)
                .background(DesignSystem.Colors.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .cardShadow()
            .opacity(isLocked ? 0.8 : 1.0)
        }
    }
}

// MARK: - Pack Detail Sheet

struct PackDetailSheet: View {
    let pack: PhotoPack
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        // Pack header
                        ZStack {
                            LinearGradient(
                                colors: pack.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 180)

                            VStack(spacing: DesignSystem.Spacing.small) {
                                Image(systemName: pack.icon)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(pack.name)
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundStyle(.white)
                                Text(pack.description)
                                    .font(DesignSystem.Typography.footnote)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, DesignSystem.Spacing.xl)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))

                        // Photo types list
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("What You Get")
                                .font(DesignSystem.Typography.title)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            ForEach(pack.photoTypes) { photoType in
                                photoTypeRow(photoType)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)

                        // Generate button
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            GRButton(
                                title: "Generate \(pack.photoCount) Photos",
                                icon: "wand.and.stars",
                                isLoading: isGenerating
                            ) {
                                dismiss()
                                DesignSystem.Haptics.medium()
                            }

                            Text("Estimated time: \(pack.estimatedTime)")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.bottom, DesignSystem.Spacing.xxl)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private func photoTypeRow(_ photoType: PackPhotoType) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: photoType.icon)
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .frame(width: 40, height: 40)
                .background(DesignSystem.Colors.flameOrange.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(photoType.name)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    importanceBadge(photoType.importance)
                }
                Text(photoType.description)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    private func importanceBadge(_ importance: PackPhotoType.PhotoImportance) -> some View {
        let color: Color = {
            switch importance {
            case .critical: return DesignSystem.Colors.flameOrange
            case .recommended: return DesignSystem.Colors.success
            case .bonus: return DesignSystem.Colors.textSecondary
            }
        }()

        return Text(importance.rawValue)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        PhotoPacksView()
    }
    .environmentObject(SubscriptionManager.shared)
    .preferredColorScheme(.dark)
}
