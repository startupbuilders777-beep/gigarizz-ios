import SwiftUI

// MARK: - Generated Photos Gallery View

struct GeneratedPhotosGalleryView: View {
    @StateObject private var viewModel = GeneratedPhotosGalleryViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showStorageWarning = false
    @GestureState private var magnificationScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Search bar
                searchBarSection

                // Organization tabs
                organizationTabsSection

                // Platform filter (when in By Platform mode)
                if viewModel.selectedOrganizationMode == .byPlatform {
                    platformFilterBar
                }

                // Style filter (when in By Style mode)
                if viewModel.selectedOrganizationMode == .byStyle {
                    styleFilterBar
                }

                // Album selector (when in Albums mode)
                if viewModel.selectedOrganizationMode == .albums {
                    albumSelectorBar
                }

                // Main content
                if viewModel.isLoading {
                    loadingPlaceholder
                } else if viewModel.filteredPhotos.isEmpty {
                    emptyStateView
                } else {
                    photoGridSection
                }

                // Storage footer
                storageFooter
            }
        }
        .navigationTitle("Gallery")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.isSelectionMode {
                    Button("Cancel") {
                        viewModel.toggleSelectionMode()
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isSelectionMode {
                    selectionToolbar
                } else {
                    defaultToolbar
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPhotoDetail) {
            FullScreenPhotoPreviewView(
                photos: viewModel.filteredPhotos.map { $0.photo },
                startingIndex: $viewModel.detailStartingIndex,
                onDismiss: {
                    viewModel.showPhotoDetail = false
                    viewModel.loadFromStorage() // Refresh to pick up favorite changes
                }
            )
        }
        .alert("Create Album", isPresented: $viewModel.showCreateAlbum) {
            TextField("Album name", text: $viewModel.newAlbumName)
            Button("Cancel", role: .cancel) {
                viewModel.newAlbumName = ""
            }
            Button("Create") {
                if !viewModel.newAlbumName.isEmpty {
                    viewModel.createAlbum(name: viewModel.newAlbumName)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddToAlbum) {
            AddToAlbumSheet(viewModel: viewModel)
        }
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .accessibilityHidden(true)

            TextField("Search by date, style, platform...", text: $viewModel.searchText)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .textFieldStyle(.plain)
                .accessibilityLabel("Search photos")
                .accessibilityHint("Enter search terms to filter photos by date, style, or platform")

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .accessibilityLabel("Clear search")
                .accessibilityHint("Double tap to clear search text")
            }
        }
        .padding(DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.top, DesignSystem.Spacing.small)
    }

    // MARK: - Organization Tabs

    private var organizationTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.micro) {
                ForEach(GalleryOrganizationMode.allCases) { mode in
                    organizationTab(mode)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surfaceSecondary.opacity(0.5))
    }

    private func organizationTab(_ mode: GalleryOrganizationMode) -> some View {
        let isSelected = viewModel.selectedOrganizationMode == mode
        let count: Int? = {
            switch mode {
            case .all: return viewModel.allPhotosCount
            case .favorites: return viewModel.favoriteCount
            case .albums: return viewModel.albums.count
            default: return nil
            }
        }()

        // Favorites tab links to dedicated FavoritesGalleryView
        if mode == .favorites {
            return AnyView(
                NavigationLink {
                    FavoritesGalleryView()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.micro) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))

                        Text(mode.rawValue)
                            .font(DesignSystem.Typography.smallButton)

                        if let count, count > 0 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(DesignSystem.Colors.goldAccent)
                                )
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.flameOrange)
                    )
                }
                .accessibilityLabel("Favorites tab, \(count ?? 0) favorite photos")
                .accessibilityHint("Double tap to view favorites gallery with ranking")
            )
        } else {
            return AnyView(
                Button {
                    viewModel.selectOrganizationMode(mode)
                } label: {
                    HStack(spacing: DesignSystem.Spacing.micro) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))

                        Text(mode.rawValue)
                            .font(DesignSystem.Typography.smallButton)

                        if let count, count > 0 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? DesignSystem.Colors.goldAccent : DesignSystem.Colors.textSecondary.opacity(0.5))
                                )
                        }
                    }
                    .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
                    )
                }
                .accessibilityLabel("\(mode.rawValue) tab\(count != nil ? ", \(count!) items" : "")")
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
                .accessibilityHint("Double tap to select")
            )
        }
    }

    // MARK: - Platform Filter Bar

    private var platformFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                platformFilterChip(nil, name: "All Platforms", icon: "square.grid.2x2.fill")

                ForEach(DatingPlatform.allCases.filter { $0 != .other }) { platform in
                    platformFilterChip(platform, name: platform.rawValue, icon: platform.icon)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private func platformFilterChip(_ platform: DatingPlatform?, name: String, icon: String) -> some View {
        let isSelected = viewModel.selectedPlatformFilter == platform
        return Button {
            viewModel.selectPlatform(platform)
        } label: {
            HStack(spacing: DesignSystem.Spacing.micro) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(name)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, DesignSystem.Spacing.micro)
            .background(
                Capsule()
                    .fill(isSelected ? (platform?.color ?? DesignSystem.Colors.flameOrange) : DesignSystem.Colors.surface)
            )
        }
        .accessibilityLabel("\(name) platform filter")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    // MARK: - Style Filter Bar

    private var styleFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                styleFilterChip(nil, name: "All Styles")

                ForEach(viewModel.groupedByStyle.map { $0.0 }, id: \.self) { style in
                    styleFilterChip(style, name: style)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private func styleFilterChip(_ style: String?, name: String) -> some View {
        let isSelected = viewModel.selectedStyleFilter == style
        return Button {
            viewModel.selectStyle(style)
        } label: {
            Text(name)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .padding(.vertical, DesignSystem.Spacing.micro)
                .background(
                    Capsule()
                        .fill(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
                )
        }
        .accessibilityLabel("\(name) style filter")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    // MARK: - Album Selector Bar

    private var albumSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // Create new album button
                Button {
                    viewModel.showCreateAlbum = true
                } label: {
                    HStack(spacing: DesignSystem.Spacing.micro) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                        Text("New Album")
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .padding(.vertical, DesignSystem.Spacing.micro)
                    .background(
                        Capsule()
                            .strokeBorder(DesignSystem.Colors.flameOrange, lineWidth: 1)
                    )
                }

                ForEach(viewModel.albums) { album in
                    albumChip(album)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private func albumChip(_ album: PhotoAlbum) -> some View {
        let isSelected = viewModel.selectedAlbum?.id == album.id
        return Button {
            viewModel.selectAlbum(album)
        } label: {
            HStack(spacing: DesignSystem.Spacing.micro) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                Text(album.name)
                    .font(DesignSystem.Typography.caption)
                Text("\(album.photoCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(DesignSystem.Colors.goldAccent.opacity(0.6)))
            }
            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, DesignSystem.Spacing.micro)
            .background(
                Capsule()
                    .fill(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
            )
        }
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteAlbum(album)
            } label: {
                Label("Delete Album", systemImage: "trash")
            }
        }
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
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(emptyStateTitle)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(emptyStateSubtitle)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if viewModel.selectedOrganizationMode == .all {
                NavigationLink {
                    GenerateView()
                } label: {
                    Text("Generate Photos")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.vertical, DesignSystem.Spacing.small)
                        .background(DesignSystem.Colors.flameOrange)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }

    private var emptyStateTitle: String {
        switch viewModel.selectedOrganizationMode {
        case .all: return "No Photos Yet"
        case .favorites: return "No Favorites"
        case .albums: return viewModel.selectedAlbum == nil ? "Select an Album" : "Empty Album"
        case .byPlatform: return viewModel.selectedPlatformFilter == nil ? "No Photos" : "No \(viewModel.selectedPlatformFilter?.rawValue ?? "") Photos"
        case .byStyle: return viewModel.selectedStyleFilter == nil ? "No Photos" : "No \(viewModel.selectedStyleFilter ?? "") Photos"
        case .byDate: return "No Photos"
        }
    }

    private var emptyStateSubtitle: String {
        switch viewModel.selectedOrganizationMode {
        case .all: return "Generate your first AI dating photos to get started."
        case .favorites: return "Tap the heart on any photo to mark it as a favorite."
        case .albums: return viewModel.selectedAlbum == nil ? "Create an album to organize your best photos." : "Add photos to this album."
        default: return "Try a different filter or generate more photos."
        }
    }

    // MARK: - Photo Grid Section

    private var photoGridSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if viewModel.selectedOrganizationMode == .byDate {
                    // Sectioned by month/year
                    ForEach(viewModel.groupedByDate, id: \.0) { section in
                        dateSectionHeader(section.0)
                        photoGrid(section.1)
                    }
                } else if viewModel.selectedOrganizationMode == .byPlatform && viewModel.selectedPlatformFilter == nil {
                    // Sectioned by platform
                    ForEach(viewModel.groupedByPlatform, id: \.0) { section in
                        platformSectionHeader(section.0, count: section.1.count)
                        photoGrid(section.1)
                    }
                } else if viewModel.selectedOrganizationMode == .byStyle && viewModel.selectedStyleFilter == nil {
                    // Sectioned by style
                    ForEach(viewModel.groupedByStyle, id: \.0) { section in
                        styleSectionHeader(section.0, count: section.1.count)
                        photoGrid(section.1)
                    }
                } else {
                    // Simple grid
                    photoGrid(viewModel.filteredPhotos)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.large)
        }
    }

    private func dateSectionHeader(_ date: String) -> some View {
        HStack {
            Text(date)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .padding(.top, DesignSystem.Spacing.medium)
    }

    private func platformSectionHeader(_ platform: DatingPlatform, count: Int) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: platform.icon)
                .font(.system(size: 14))
                .foregroundStyle(platform.color)

            Text(platform.rawValue)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text("\(count)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .padding(.top, DesignSystem.Spacing.medium)
    }

    private func styleSectionHeader(_ style: String, count: Int) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.flameOrange)

            Text(style)
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text("\(count)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .padding(.top, DesignSystem.Spacing.medium)
    }

    private func photoGrid(_ photos: [GalleryPhotoItem]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: viewModel.columnCount)

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(photos) { item in
                photoCell(item, index: photos.firstIndex(where: { $0.id == item.id }) ?? 0)
            }
        }
    }

    private func photoCell(_ item: GalleryPhotoItem, index: Int) -> some View {
        let isSelected = viewModel.selectedPhotoIds.contains(item.id)
        let totalPhotos = viewModel.filteredPhotos.count
        let favoriteText = item.photo.isFavorite ? " favorited" : ""

        return ZStack(alignment: .topTrailing) {
            // Photo thumbnail placeholder
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
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        isSelected ? DesignSystem.Colors.flameOrange : .clear,
                        lineWidth: 2
                    )
            )
            .overlay(
                Group {
                    if viewModel.isSelectionMode {
                        // Selection checkbox
                        VStack {
                            HStack {
                                Spacer()
                                selectionCheckbox(isSelected)
                                    .padding(4)
                            }
                            Spacer()
                        }
                    } else if item.photo.isFavorite {
                        // Favorite heart and rank badge
                        ZStack(alignment: .topLeading) {
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

                            // Rank badge if photo has a rank
                            if let rank = item.photo.favoriteRank {
                                RankBadge(rank: rank)
                                    .padding(4)
                            }
                        }
                    }
                }
            )
            .onTapGesture {
                if viewModel.isSelectionMode {
                    viewModel.togglePhotoSelection(item.id)
                } else {
                    viewModel.openPhotoDetail(index)
                }
            }
            .onLongPressGesture {
                if !viewModel.isSelectionMode {
                    viewModel.toggleSelectionMode()
                    viewModel.togglePhotoSelection(item.id)
                }
            }

            // Platform tag badge
            if let platform = item.platformTag, viewModel.selectedOrganizationMode == .all {
                VStack {
                    HStack {
                        Image(systemName: platform.icon)
                            .font(.system(size: 8))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(platform.color)
                            .clipShape(Circle())
                        Spacer()
                    }
                    Spacer()
                }
                .padding(4)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Photo \(index + 1) of \(totalPhotos), \(item.photo.style)\(favoriteText)")
        .accessibilityHint("Double tap to view full size, long press to select")
        .accessibilityAddTraits(.isButton)
    }

    private func selectionCheckbox(_ isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
                .frame(width: 24, height: 24)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to toggle selection")
        .accessibilityAddTraits(.isButton)
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

    // MARK: - Storage Footer

    private var storageFooter: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "internaldrive")
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Storage: \(viewModel.storageSizeText)")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("\(viewModel.allPhotosCount) photos")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.7))
            }

            Spacer()

            if viewModel.totalStorageBytes > 50_000_000 { // > 50MB
                Button {
                    showStorageWarning = true
                } label: {
                    Text("Clear Old")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.warning)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surfaceSecondary.opacity(0.5))
        .alert("Clear Old Photos?", isPresented: $showStorageWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Clear 30+ Days") {
                viewModel.clearOldPhotos(olderThanDays: 30)
            }
            Button("Clear 60+ Days", role: .destructive) {
                viewModel.clearOldPhotos(olderThanDays: 60)
            }
        } message: {
            Text("This will permanently delete photos older than the selected period.")
        }
    }

    // MARK: - Toolbars

    private var defaultToolbar: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Button {
                viewModel.toggleSelectionMode()
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .accessibilityLabel("Select photos")

            Menu {
                Button {
                    viewModel.setColumnCount(2)
                } label: {
                    Label("2 Columns", systemImage: viewModel.columnCount == 2 ? "checkmark" : "")
                }

                Button {
                    viewModel.setColumnCount(3)
                } label: {
                    Label("3 Columns", systemImage: viewModel.columnCount == 3 ? "checkmark" : "")
                }

                Button {
                    viewModel.setColumnCount(4)
                } label: {
                    Label("4 Columns", systemImage: viewModel.columnCount == 4 ? "checkmark" : "")
                }
            } label: {
                Image(systemName: "rectangle.grid.3x2")
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .accessibilityLabel("Grid layout")
        }
    }

    private var selectionToolbar: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Button {
                viewModel.selectAll()
            } label: {
                Text("All")
                    .font(DesignSystem.Typography.smallButton)
            }

            if viewModel.hasSelection {
                Menu {
                    Button {
                        viewModel.bulkFavorite()
                    } label: {
                        Label("Add to Favorites", systemImage: "heart.fill")
                    }

                    Button {
                        viewModel.showAddToAlbum = true
                    } label: {
                        Label("Add to Album", systemImage: "folder.fill.badge.plus")
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.bulkDelete()
                    } label: {
                        Label("Delete Selected", systemImage: "trash")
                    }
                } label: {
                    Text("\(viewModel.selectionCount)")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.flameOrange)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Add to Album Sheet

struct AddToAlbumSheet: View {
    @ObservedObject var viewModel: GeneratedPhotosGalleryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                List {
                    ForEach(viewModel.albums) { album in
                        Button {
                            viewModel.addToAlbum(album)
                            dismiss()
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.medium) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(DesignSystem.Colors.goldAccent)
                                    .frame(width: 32, height: 32)
                                    .background(DesignSystem.Colors.goldAccent.opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(album.name)
                                        .font(DesignSystem.Typography.callout)
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                                    Text("\(album.photoCount) photos")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                }

                                Spacer()

                                Text("+\(viewModel.selectionCount)")
                                    .font(DesignSystem.Typography.smallButton)
                                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                            }
                            .padding(.vertical, DesignSystem.Spacing.small)
                        }
                        .listRowBackground(DesignSystem.Colors.surface)
                    }
                }
                .listStyle(.plain)

                if viewModel.albums.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        Text("No Albums Yet")
                            .font(DesignSystem.Typography.title)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("Create an album first to organize your photos.")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .padding(DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Add to Album")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateAlbum = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GeneratedPhotosGalleryView()
    }
    .preferredColorScheme(.dark)
}