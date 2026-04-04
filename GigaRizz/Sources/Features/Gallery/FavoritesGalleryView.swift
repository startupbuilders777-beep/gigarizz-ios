import SwiftUI

// MARK: - Favorites Gallery View

struct FavoritesGalleryView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isReorderMode = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Stats Header
                statsHeader

                // Main Content
                if viewModel.isLoading {
                    loadingPlaceholder
                } else if viewModel.favoritePhotos.isEmpty {
                    emptyStateView
                } else {
                    favoritesGrid
                }
            }
        }
        .navigationTitle("Favorites")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.favoritePhotos.isEmpty {
                    Button {
                        withAnimation(DesignSystem.Animation.quickSpring) {
                            isReorderMode.toggle()
                        }
                        DesignSystem.Haptics.light()
                    } label: {
                        if isReorderMode {
                            Text("Done")
                                .font(DesignSystem.Typography.smallButton)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        } else {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 18))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .accessibilityLabel(isReorderMode ? "Done reordering" : "Reorder favorites")
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPhotoDetail) {
            FullScreenPhotoPreviewView(
                photos: viewModel.favoritePhotos.map { $0.photo },
                startingIndex: $viewModel.detailStartingIndex,
                onDismiss: {
                    viewModel.showPhotoDetail = false
                    viewModel.loadFavorites()
                }
            )
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            // Total Favorites
            statCard(
                title: "Total",
                value: "\(viewModel.favoritePhotos.count)",
                icon: "heart.fill",
                color: DesignSystem.Colors.error
            )

            // Top Platform
            statCard(
                title: "Top Platform",
                value: viewModel.topPlatform?.rawValue ?? "—",
                icon: viewModel.topPlatform?.icon ?? "app.fill",
                color: viewModel.topPlatform?.color ?? DesignSystem.Colors.textSecondary
            )

            // This Week
            statCard(
                title: "This Week",
                value: "+\(viewModel.weeklyAdditions)",
                icon: "sparkles",
                color: DesignSystem.Colors.goldAccent
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surfaceSecondary.opacity(0.5))
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(value)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)

            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Loading Placeholder

    private var loadingPlaceholder: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ForEach(0..<4) { _ in
                ShimmerView()
                    .frame(height: 140)
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
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(
                        DesignSystem.Colors.flameOrange.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .frame(width: 120, height: 100)

                Image(systemName: "trophy")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(DesignSystem.Colors.goldAccent.opacity(0.6))
                    .offset(y: -10)
            }
            .accessibilityHidden(true)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Favorites Yet")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Mark your best photos with a heart to build your collection.")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            NavigationLink {
                GeneratedPhotosGalleryView()
            } label: {
                Text("Go to Gallery")
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

    private var favoritesGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.xs),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.xs),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.xs)
                ],
                spacing: DesignSystem.Spacing.xs
            ) {
                ForEach(viewModel.favoritePhotos) { item in
                    FavoritePhotoCell(
                        item: item,
                        rank: viewModel.rankForPhoto(item.id),
                        isReorderMode: isReorderMode,
                        onTap: {
                            if isReorderMode {
                                // In reorder mode, don't open detail
                            } else {
                                viewModel.openPhotoDetail(item.id)
                            }
                        },
                        onRemoveFavorite: {
                            viewModel.removeFromFavorites(item.id)
                        }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .disabled(isReorderMode)
    }
}

// MARK: - Favorite Photo Cell

struct FavoritePhotoCell: View {
    let item: FavoritePhotoItem
    let rank: Int
    let isReorderMode: Bool
    let onTap: () -> Void
    let onRemoveFavorite: () -> Void

    @State private var isDragging = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Photo thumbnail placeholder
            photoThumbnail

            // Rank Badge (top-left)
            RankBadge(rank: rank)
                .padding(4)

            // Favorite Heart (top-right) - shown when not in reorder mode
            if !isReorderMode {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignSystem.Colors.error)
                            .padding(4)
                    }
                    Spacer()
                }
            }

            // Drag indicator in reorder mode
            if isReorderMode {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "hand.draw")
                            .font(.system(size: 16))
                            .foregroundStyle(DesignSystem.Colors.goldAccent)
                            .padding(6)
                        Spacer()
                    }
                    Spacer()
                }
                .background(DesignSystem.Colors.overlay.opacity(0.3))
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .elevatedShadow()
        .animation(reduceMotion ? .none : DesignSystem.Animation.quickSpring, value: isDragging)
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onRemoveFavorite) {
                Label("Remove", systemImage: "heart.slash.fill")
            }
        }
        .accessibilityLabel("Photo #\(rank), \(item.photo.style)")
        .accessibilityHint("Double tap to view, swipe to remove from favorites")
        .accessibilityAddTraits(.isButton)
    }

    private var photoThumbnail: some View {
        ZStack {
            // Gradient background matching style
            LinearGradient(
                colors: gradientForStyle(item.photo.style),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Placeholder icon
            Image(systemName: "person.fill")
                .font(.system(size: 30, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.3))
                .accessibilityHidden(true)

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
}

// MARK: - Rank Badge

struct RankBadge: View {
    let rank: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.flameOrange)
                .frame(width: 24, height: 24)

            Text("#\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Rank \(rank)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FavoritesGalleryView()
    }
    .preferredColorScheme(.dark)
}