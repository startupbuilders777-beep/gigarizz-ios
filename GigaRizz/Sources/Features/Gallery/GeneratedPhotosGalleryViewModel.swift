import Foundation
import SwiftUI

// MARK: - Gallery Organization Mode

enum GalleryOrganizationMode: String, CaseIterable, Identifiable {
    case all = "All"
    case byDate = "By Date"
    case byPlatform = "By Platform"
    case byStyle = "By Style"
    case favorites = "Favorites"
    case albums = "Albums"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "photo.on.rectangle.angled"
        case .byDate: return "calendar"
        case .byPlatform: return "app.badge.fill"
        case .byStyle: return "wand.and.stars"
        case .favorites: return "heart.fill"
        case .albums: return "folder.fill"
        }
    }
}

// MARK: - Photo Album

struct PhotoAlbum: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var createdAt: Date
    var photoIds: [String]

    init(
        id: String = UUID().uuidString,
        name: String,
        createdAt: Date = Date(),
        photoIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.photoIds = photoIds
    }

    var photoCount: Int { photoIds.count }
}

// MARK: - Gallery Photo Item

/// Wrapper for GeneratedPhoto with gallery-specific state
struct GalleryPhotoItem: Identifiable, Equatable {
    let id: String
    let photo: GeneratedPhoto
    var isSelected: Bool = false
    var platformTag: DatingPlatform?
    let monthYear: String

    init(photo: GeneratedPhoto, platformTag: DatingPlatform? = nil) {
        self.id = photo.id
        self.photo = photo
        self.platformTag = platformTag
        self.monthYear = Self.formatMonthYear(photo.createdAt)
    }

    static func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Generated Photos Gallery ViewModel

@MainActor
final class GeneratedPhotosGalleryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var allPhotos: [GalleryPhotoItem] = []
    @Published var displayedPhotos: [GalleryPhotoItem] = []
    @Published var albums: [PhotoAlbum] = []
    @Published var selectedOrganizationMode: GalleryOrganizationMode = .all
    @Published var selectedPlatformFilter: DatingPlatform?
    @Published var selectedStyleFilter: String?
    @Published var selectedAlbum: PhotoAlbum?
    @Published var searchText: String = ""
    @Published var isSelectionMode: Bool = false
    @Published var selectedPhotoIds: Set<String> = []
    @Published var columnCount: Int = 3
    @Published var showPhotoDetail: Bool = false
    @Published var detailStartingIndex: Int = 0
    @Published var showCreateAlbum: Bool = false
    @Published var newAlbumName: String = ""
    @Published var showAddToAlbum: Bool = false
    @Published var totalStorageBytes: Int64 = 0
    @Published var isLoading: Bool = false

    // MARK: - Computed Properties

    var groupedByDate: [(String, [GalleryPhotoItem])] {
        let sorted = allPhotos.sorted { $0.photo.createdAt > $1.photo.createdAt }
        let grouped = Dictionary(grouping: sorted, by: { $0.monthYear })
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }

    var groupedByPlatform: [(DatingPlatform, [GalleryPhotoItem])] {
        let sorted = allPhotos.sorted { $0.photo.createdAt > $1.photo.createdAt }
        let grouped = Dictionary(grouping: sorted, by: { $0.platformTag ?? .general })
        return DatingPlatform.allCases.compactMap { platform in
            let photos = grouped[platform] ?? []
            return photos.isEmpty ? nil : (platform, photos)
        }
    }

    var groupedByStyle: [(String, [GalleryPhotoItem])] {
        let sorted = allPhotos.sorted { $0.photo.createdAt > $1.photo.createdAt }
        let grouped = Dictionary(grouping: sorted, by: { $0.photo.style })
        return grouped.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    var favoritePhotos: [GalleryPhotoItem] {
        allPhotos.filter { $0.photo.isFavorite }.sorted { $0.photo.createdAt > $1.photo.createdAt }
    }

    var filteredPhotos: [GalleryPhotoItem] {
        if searchText.isEmpty {
            return displayedPhotos
        }
        return displayedPhotos.filter { item in
            item.photo.style.localizedCaseInsensitiveContains(searchText) ||
            item.monthYear.localizedCaseInsensitiveContains(searchText) ||
            (item.platformTag?.rawValue.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var selectionCount: Int { selectedPhotoIds.count }
    var hasSelection: Bool { !selectedPhotoIds.isEmpty }
    var allPhotosCount: Int { allPhotos.count }
    var favoriteCount: Int { favoritePhotos.count }
    var storageSizeText: String {
        let mb = Double(totalStorageBytes) / 1_048_576
        if mb < 1 {
            let kb = Double(totalStorageBytes) / 1024
            return String(format: "%.0f KB", kb)
        }
        return String(format: "%.1f MB", mb)
    }

    // MARK: - Persistence Keys

    private let photosKey = "gigarizz_generated_photos"
    private let albumsKey = "gigarizz_photo_albums"
    private let favoritesKey = "gigarizz_favorites"

    // MARK: - Init

    init() {
        loadFromStorage()
    }

    // MARK: - Load From Storage

    func loadFromStorage() {
        isLoading = true

        // Load photos from UserDefaults (replace with FileManager/Documents for production)
        if let data = UserDefaults.standard.data(forKey: photosKey),
           let photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data) {
            allPhotos = photos.map { GalleryPhotoItem(photo: $0, platformTag: inferPlatform(from: $0)) }
        } else {
            // Load demo photos for preview
            loadDemoPhotos()
        }

        // Load albums
        if let data = UserDefaults.standard.data(forKey: albumsKey),
           let loadedAlbums = try? JSONDecoder().decode([PhotoAlbum].self, from: data) {
            albums = loadedAlbums
        }

        // Calculate storage
        calculateStorage()

        updateDisplayedPhotos()
        isLoading = false
    }

    // MARK: - Demo Photos

    private func loadDemoPhotos() {
        // Create demo photos for preview/testing - REAL local storage simulation
        let styles = ["Confident", "Adventurous", "Mysterious", "Golden Hour", "Urban Moody", "Casual Chic"]
        let platforms: [DatingPlatform?] = [.tinder, .hinge, .bumble, .tinder, nil, .general]

        var demoPhotos: [GeneratedPhoto] = []
        for i in 0..<12 {
            let date = Date().addingTimeInterval(-Double(i) * 86400 * 3) // Spread across weeks
            let photo = GeneratedPhoto(
                id: "demo-\(i)",
                userId: "demo-user",
                style: styles[i % styles.count],
                createdAt: date,
                isFavorite: i % 4 == 0 // Mark every 4th as favorite
            )
            demoPhotos.append(photo)
        }
        for (i, photo) in demoPhotos.enumerated() {
            let platform = platforms[i % platforms.count]
            allPhotos.append(GalleryPhotoItem(photo: photo, platformTag: platform))
        }
        saveToStorage()
    }

    // MARK: - Infer Platform

    private func inferPlatform(from photo: GeneratedPhoto) -> DatingPlatform? {
        // In production, this would be stored metadata from generation
        let style = photo.style.lowercased()
        if style.contains("confident") || style.contains("bold") {
            return .tinder
        } else if style.contains("warm") || style.contains("casual") {
            return .hinge
        } else if style.contains("friendly") || style.contains("approachable") {
            return .bumble
        }
        return .general
    }

    // MARK: - Save To Storage

    func saveToStorage() {
        let photos = allPhotos.map { $0.photo }
        if let data = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(data, forKey: photosKey)
        }

        if let data = try? JSONEncoder().encode(albums) {
            UserDefaults.standard.set(data, forKey: albumsKey)
        }
    }

    // MARK: - Calculate Storage

    func calculateStorage() {
        // Estimate storage based on photo count (production would scan Documents directory)
        let estimatedBytesPerPhoto: Int64 = 500_000 // ~500KB per photo
        totalStorageBytes = Int64(allPhotos.count) * estimatedBytesPerPhoto
    }

    // MARK: - Update Displayed Photos

    func updateDisplayedPhotos() {
        switch selectedOrganizationMode {
        case .all:
            displayedPhotos = allPhotos.sorted { $0.photo.createdAt > $1.photo.createdAt }
        case .byDate:
            displayedPhotos = allPhotos.sorted { $0.photo.createdAt > $1.photo.createdAt }
        case .byPlatform:
            if let platform = selectedPlatformFilter {
                displayedPhotos = allPhotos.filter { $0.platformTag == platform }
            } else {
                displayedPhotos = allPhotos
            }
        case .byStyle:
            if let style = selectedStyleFilter {
                displayedPhotos = allPhotos.filter { $0.photo.style == style }
            } else {
                displayedPhotos = allPhotos
            }
        case .favorites:
            displayedPhotos = favoritePhotos
        case .albums:
            if let album = selectedAlbum {
                displayedPhotos = allPhotos.filter { album.photoIds.contains($0.id) }
            } else {
                displayedPhotos = []
            }
        }
    }

    // MARK: - Organization Mode Change

    func selectOrganizationMode(_ mode: GalleryOrganizationMode) {
        withAnimation(DesignSystem.Animation.quickSpring) {
            selectedOrganizationMode = mode
            selectedPlatformFilter = nil
            selectedStyleFilter = nil
            selectedAlbum = nil
            isSelectionMode = false
            selectedPhotoIds.removeAll()
            updateDisplayedPhotos()
        }
        DesignSystem.Haptics.light()
    }

    // MARK: - Platform Filter

    func selectPlatform(_ platform: DatingPlatform?) {
        withAnimation(DesignSystem.Animation.quickSpring) {
            selectedPlatformFilter = platform
            updateDisplayedPhotos()
        }
        DesignSystem.Haptics.light()
    }

    // MARK: - Style Filter

    func selectStyle(_ style: String?) {
        withAnimation(DesignSystem.Animation.quickSpring) {
            selectedStyleFilter = style
            updateDisplayedPhotos()
        }
        DesignSystem.Haptics.light()
    }

    // MARK: - Album Selection

    func selectAlbum(_ album: PhotoAlbum?) {
        withAnimation(DesignSystem.Animation.quickSpring) {
            selectedAlbum = album
            updateDisplayedPhotos()
        }
        DesignSystem.Haptics.light()
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(_ itemId: String) {
        if let index = allPhotos.firstIndex(where: { $0.id == itemId }) {
            let photo = allPhotos[index].photo
            let updatedPhoto = GeneratedPhoto(
                id: photo.id,
                userId: photo.userId,
                style: photo.style,
                imageURL: photo.imageURL,
                thumbnailURL: photo.thumbnailURL,
                createdAt: photo.createdAt,
                isFavorite: !photo.isFavorite
            )
            allPhotos[index] = GalleryPhotoItem(photo: updatedPhoto, platformTag: allPhotos[index].platformTag)
            saveToStorage()
            updateDisplayedPhotos()
            DesignSystem.Haptics.medium()
        }
    }

    // MARK: - Selection Mode

    func toggleSelectionMode() {
        withAnimation(DesignSystem.Animation.quickSpring) {
            isSelectionMode.toggle()
            if !isSelectionMode {
                selectedPhotoIds.removeAll()
            }
        }
        DesignSystem.Haptics.light()
    }

    func togglePhotoSelection(_ itemId: String) {
        withAnimation(DesignSystem.Animation.quickSpring) {
            if selectedPhotoIds.contains(itemId) {
                selectedPhotoIds.remove(itemId)
            } else {
                selectedPhotoIds.insert(itemId)
            }
        }
        DesignSystem.Haptics.light()
    }

    func selectAll() {
        selectedPhotoIds = Set(filteredPhotos.map { $0.id })
        DesignSystem.Haptics.medium()
    }

    func clearSelection() {
        selectedPhotoIds.removeAll()
        DesignSystem.Haptics.light()
    }

    // MARK: - Bulk Operations

    func bulkFavorite() {
        for id in selectedPhotoIds {
            toggleFavorite(id)
        }
        clearSelection()
        isSelectionMode = false
        DesignSystem.Haptics.success()
    }

    func bulkDelete() {
        allPhotos.removeAll { selectedPhotoIds.contains($0.id) }
        // Remove from albums
        for i in albums.indices {
            albums[i].photoIds.removeAll { selectedPhotoIds.contains($0) }
        }
        saveToStorage()
        calculateStorage()
        clearSelection()
        isSelectionMode = false
        updateDisplayedPhotos()
        DesignSystem.Haptics.heavy()
    }

    // MARK: - Albums

    func createAlbum(name: String) {
        let album = PhotoAlbum(name: name)
        albums.append(album)
        saveToStorage()
        showCreateAlbum = false
        newAlbumName = ""
        DesignSystem.Haptics.success()
    }

    func addToAlbum(_ album: PhotoAlbum) {
        if let index = albums.firstIndex(where: { $0.id == album.id }) {
            albums[index].photoIds.append(contentsOf: selectedPhotoIds)
            saveToStorage()
        }
        clearSelection()
        showAddToAlbum = false
        DesignSystem.Haptics.success()
    }

    func deleteAlbum(_ album: PhotoAlbum) {
        albums.removeAll { $0.id == album.id }
        if selectedAlbum?.id == album.id {
            selectedAlbum = nil
        }
        saveToStorage()
        updateDisplayedPhotos()
        DesignSystem.Haptics.medium()
    }

    // MARK: - Column Count (Pinch to Zoom)

    func setColumnCount(_ count: Int) {
        let clamped = max(2, min(4, count))
        withAnimation(DesignSystem.Animation.quickSpring) {
            columnCount = clamped
        }
    }

    // MARK: - Photo Detail

    func openPhotoDetail(_ index: Int) {
        detailStartingIndex = index
        showPhotoDetail = true
        DesignSystem.Haptics.light()
    }

    // MARK: - Search

    func updateSearch(_ text: String) {
        searchText = text
    }

    // MARK: - Clear Old Photos

    func clearOldPhotos(olderThanDays: Int = 30) {
        let cutoff = Date().addingTimeInterval(-Double(olderThanDays) * 86400)
        allPhotos.removeAll { $0.photo.createdAt < cutoff }
        saveToStorage()
        calculateStorage()
        updateDisplayedPhotos()
        DesignSystem.Haptics.success()
    }
}