import SwiftUI
import UniformTypeIdentifiers

// MARK: - Favorites Gallery View

/// Dedicated view for favorites collection with drag-to-reorder ranking.
struct FavoritesGalleryView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isReorderMode = false
    @State private var draggedItem: FavoritePhotoItem?
    @State private var showRemoveConfirmation = false
    @State private var itemToRemove: FavoritePhotoItem?

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Stats header
                favoritesStatsHeader

                // Main content
                if viewModel.isLoading {
                    loadingPlaceholder
                } else if viewModel.favorites.isEmpty {
                    emptyStateView
                } else {
                    favoritesGridSection
                }

                // Reorder mode footer
                if isReorderMode {
                    reorderModeFooter
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.favorites.isEmpty {
                    reorderModeButton
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPhotoDetail) {
            FullScreenPhotoPreviewView(
                photos: viewModel.favorites.map { $0.photo },
                startingIndex: $viewModel.detailStartingIndex,
                onDismiss: {
                    viewModel.showPhotoDetail = false
                    viewModel.loadFavorites()
                }
            )
        }
        .alert("Remove from Favorites?", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {
                itemToRemove = nil
            }
            Button("Remove", role: .destructive) {
                if let item = itemToRemove {
                    viewModel.removeFromFavorites(item)
                    DesignSystem.Haptics.medium()
                }
                itemToRemove = nil
            }
        } message: {
            Text("This photo will be removed from your favorites but stay in your gallery.")
        }
        .onAppear {
            viewModel.loadFavorites()
        }
    }

    // MARK: - Stats Header

    private var favoritesStatsHeader: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            // Total favorites
            statCard(
                title: "Total",
                value: "\(viewModel.totalFavorites)",
                icon: "heart.fill",
                color: DesignSystem.Colors.flameOrange
            )

            // Top platform
            statCard(
                title: "Top Platform",
                value: viewModel.topPlatform?.rawValue ?? "—",
                icon: viewModel.topPlatform?.icon ?? "app.badge.fill",
                color: viewModel.topPlatform?.color ?? DesignSystem.Colors.textSecondary
            )

            // Weekly additions
            statCard(
                title: "This Week",
                value: "+\(viewModel.weeklyAdditions)",
                icon: "calendar.badge.plus",
                color: DesignSystem.Colors.success
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surfaceSecondary.opacity(0.3))
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)

            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    // MARK: - Loading Placeholder

    private var loadingPlaceholder: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ForEach(0..<3) { _ in
                ShimmerView()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.top, DesignSystem.Spacing.large)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Spacer()

            // Trophy case illustration
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.surfaceSecondary.opacity(0.5))
                    .frame(width: 120, height: 120)

                Image(systemName: "trophy")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.goldAccent, DesignSystem.Colors.flameOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Favorites Yet")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Mark your best photos to build your personal highlight reel!")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            NavigationLink {
                GeneratedPhotosGalleryView()
            } label: {
                Text("Browse Gallery")
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(DesignSystem.Colors.flameOrange)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }

    // MARK: - Favorites Grid

    private var favoritesGridSection: some View {
        ScrollView(showsIndicators: false) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.favorites) { item in
                    favoritePhotoCell(item)
                        .onDrag {
                            if isReorderMode {
                                draggedItem = item
                                return NSItemProvider(object: NSString(string: item.id))
                            }
                            return NSItemProvider()
                        }
                        .onDrop(of: [UTType.text], delegate: FavoritesDropDelegate(
                            item: item,
                            items: viewModel.favorites,
                            isReorderMode: isReorderMode,
                            onDrop: { from, to in
                                viewModel.reorderFavorites(from: from, to: to)
                            }
                        ))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, isReorderMode ? 100 : DesignSystem.Spacing.large)
        }
    }

    private func favoritePhotoCell(_ item: FavoritePhotoItem) -> some View {
        let rank = item.photo.favoriteRank ?? (viewModel.favorites.firstIndex(where: { $0.id == item.id }) ?? 0) + 1

        return ZStack(alignment: .topLeading) {
            // Photo thumbnail placeholder
            ZStack(alignment: .topTrailing) {
                // Gradient background matching style
                LinearGradient(
                    colors: gradientForStyle(item.photo.style),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Placeholder icon
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.3))

                // Style badge overlay
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 8))
                        Text(item.photo.style)
                            .font(.system(size: 9, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.4))
                    .padding(4)
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .scaleEffect(isReorderMode && draggedItem?.id == item.id ? 1.05 : 1.0)
            .elevatedShadow()
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        isReorderMode ? DesignSystem.Colors.flameOrange.opacity(0.5) : .clear,
                        lineWidth: 1.5
                    )
            )
            .onTapGesture {
                if isReorderMode {
                    DesignSystem.Haptics.light()
                } else {
                    viewModel.openPhotoDetail(item)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: !isReorderMode) {
                if !isReorderMode {
                    Button(role: .destructive) {
                        itemToRemove = item
                        showRemoveConfirmation = true
                        DesignSystem.Haptics.warning()
                    } label: {
                        Image(systemName: "heart.slash.fill")
                    }
                }
            }

            // Rank badge (#1, #2, #3...)
            RankBadge(rank: rank)

            // Favorite heart indicator
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .padding(4)
                }
                Spacer()
            }
            .padding(4)

            // Platform badges
            if let platform = item.platformTag {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        platformBadge(platform)
                            .padding(4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Favorite photo #\(rank), \(item.photo.style) style")
        .accessibilityHint(isReorderMode ? "Drag to reorder" : "Tap to view, swipe to remove")
    }

    private func platformBadge(_ platform: DatingPlatform) -> some View {
        Image(systemName: platform.icon)
            .font(.system(size: 8))
            .foregroundStyle(.white)
            .padding(4)
            .background(platform.color)
            .clipShape(Circle())
    }

    private func gradientForStyle(_ style: String) -> [Color] {
        switch style.lowercased() {
        case "confident": return [DesignSystem.Colors.flameOrange, .orange]
        case "adventurous": return [.green, .teal]
        case "mysterious": return [.purple, .indigo]
        case "golden hour": return [.orange, .yellow]
        case "urban moody": return [.purple, .blue]
        case "casual chic": return [.brown, DesignSystem.Colors.goldAccent]
        case "sporty": return [.red, DesignSystem.Colors.flameOrange]
        case "professional": return [.gray, .blue]
        case "travel adventure": return [.teal, .cyan]
        case "clean minimal": return [.white.opacity(0.8), .gray]
        default: return [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent]
        }
    }

    // MARK: - Reorder Mode Button

    private var reorderModeButton: some View {
        Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                isReorderMode.toggle()
            }
            DesignSystem.Haptics.selection()
        } label: {
            if isReorderMode {
                Text("Done")
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.flameOrange)
                    .clipShape(Capsule())
            } else {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .accessibilityLabel(isReorderMode ? "Finish reordering" : "Reorder favorites")
    }

    // MARK: - Reorder Mode Footer

    private var reorderModeFooter: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("Drag photos to change ranking")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("#1 is your best photo — shown first everywhere")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.flameOrange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.divider)
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Drop Delegate for Drag-to-Reorder

struct FavoritesDropDelegate: DropDelegate {
    let item: FavoritePhotoItem
    let items: [FavoritePhotoItem]
    let isReorderMode: Bool
    let onDrop: (FavoritePhotoItem, FavoritePhotoItem) -> Void

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard isReorderMode else { return }
        guard let draggedItem = info.itemProviders(for: [UTType.text]).first else { return }

        draggedItem.loadObject(ofClass: NSString.self) { reading, _ in
            guard let draggedId = reading as? String else { return }
            guard let fromItem = items.first(where: { $0.id == draggedId }) else { return }

            Task { @MainActor in
                if fromItem.id != item.id {
                    onDrop(fromItem, item)
                    DesignSystem.Haptics.light()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FavoritesGalleryView()
    }
    .preferredColorScheme(.dark)
}