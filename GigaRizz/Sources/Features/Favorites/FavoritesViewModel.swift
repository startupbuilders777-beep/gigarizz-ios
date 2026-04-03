import Foundation
import SwiftUI

// MARK: - Favorite Photo Item

/// Wrapper for GeneratedPhoto with favorites-specific state.
struct FavoritePhotoItem: Identifiable, Equatable {
    let id: String
    let photo: GeneratedPhoto
    var platformTag: DatingPlatform?
    let addedAt: Date

    init(photo: GeneratedPhoto, platformTag: DatingPlatform? = nil, addedAt: Date = Date()) {
        self.id = photo.id
        self.photo = photo
        self.platformTag = platformTag
        self.addedAt = addedAt
    }

    static func == (lhs: FavoritePhotoItem, rhs: FavoritePhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Favorites ViewModel

@MainActor
final class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var favorites: [FavoritePhotoItem] = []
    @Published var isLoading: Bool = false
    @Published var showPhotoDetail: Bool = false
    @Published var detailStartingIndex: Int = 0

    // MARK: - Computed Properties

    var totalFavorites: Int { favorites.count }

    var topPlatform: DatingPlatform? {
        let platformCounts = Dictionary(grouping: favorites, by: { $0.platformTag ?? .general })
        let sorted = platformCounts.sorted { $0.value.count > $1.value.count }
        return sorted.first?.key
    }

    var weeklyAdditions: Int {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 86400)
        return favorites.filter { $0.addedAt >= oneWeekAgo }.count
    }

    // MARK: - Persistence Keys

    private let photosKey = "gigarizz_generated_photos"
    private let favoritesRanksKey = "gigarizz_favorites_ranks"
    private let favoritesAddedAtKey = "gigarizz_favorites_added_at"

    // MARK: - Init

    init() {
        loadFavorites()
    }

    // MARK: - Load Favorites

    func loadFavorites() {
        isLoading = true

        // Load all photos from storage
        if let data = UserDefaults.standard.data(forKey: photosKey),
           let photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data) {
            // Filter favorites and create items
            let favoritePhotos = photos.filter { $0.isFavorite }

            // Load rank data
            var ranks: [String: Int] = [:]
            if let ranksData = UserDefaults.standard.data(forKey: favoritesRanksKey),
               let loadedRanks = try? JSONDecoder().decode([String: Int].self, from: ranksData) {
                ranks = loadedRanks
            }

            // Load added timestamps
            var addedAt: [String: Date] = [:]
            if let addedData = UserDefaults.standard.data(forKey: favoritesAddedAtKey),
               let loadedAdded = try? JSONDecoder().decode([String: Date].self, from: addedData) {
                addedAt = loadedAdded
            }

            // Create favorite items, sorted by rank
            let items = favoritePhotos.map { photo -> FavoritePhotoItem in
                let platform = inferPlatform(from: photo)
                let added = addedAt[photo.id] ?? photo.createdAt
                return FavoritePhotoItem(photo: photo, platformTag: platform, addedAt: added)
            }

            // Sort by rank (favorites with rank first, then by addedAt)
            favorites = items.sorted { itemA, itemB in
                let rankA = itemA.photo.favoriteRank ?? ranks[itemA.id] ?? Int.max
                let rankB = itemB.photo.favoriteRank ?? ranks[itemB.id] ?? Int.max
                if rankA == rankB {
                    return itemA.addedAt > itemB.addedAt
                }
                return rankA < rankB
            }
        }

        isLoading = false
    }

    // MARK: - Infer Platform

    private func inferPlatform(from photo: GeneratedPhoto) -> DatingPlatform? {
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

    // MARK: - Save Favorites

    func saveFavorites() {
        // Update ranks
        var ranks: [String: Int] = [:]
        for (index, item) in favorites.enumerated() {
            ranks[item.id] = index + 1
        }

        if let ranksData = try? JSONEncoder().encode(ranks) {
            UserDefaults.standard.set(ranksData, forKey: favoritesRanksKey)
        }

        // Update added timestamps
        var addedAt: [String: Date] = [:]
        for item in favorites {
            addedAt[item.id] = item.addedAt
        }

        if let addedData = try? JSONEncoder().encode(addedAt) {
            UserDefaults.standard.set(addedData, forKey: favoritesAddedAtKey)
        }

        // Update the GeneratedPhoto objects with new ranks
        if let data = UserDefaults.standard.data(forKey: photosKey),
           var photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data) {
            for (index, item) in favorites.enumerated() {
                if let photoIndex = photos.firstIndex(where: { $0.id == item.id }) {
                    let photo = photos[photoIndex]
                    photos[photoIndex] = GeneratedPhoto(
                        id: photo.id,
                        userId: photo.userId,
                        style: photo.style,
                        imageURL: photo.imageURL,
                        thumbnailURL: photo.thumbnailURL,
                        createdAt: photo.createdAt,
                        isFavorite: true,
                        favoriteRank: index + 1
                    )
                }
            }

            if let updatedData = try? JSONEncoder().encode(photos) {
                UserDefaults.standard.set(updatedData, forKey: photosKey)
            }
        }
    }

    // MARK: - Reorder Favorites

    func reorderFavorites(from: FavoritePhotoItem, to: FavoritePhotoItem) {
        guard let fromIndex = favorites.firstIndex(where: { $0.id == from.id }),
              let toIndex = favorites.firstIndex(where: { $0.id == to.id }) else { return }

        withAnimation(DesignSystem.Animation.cardSpring) {
            favorites.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }

        saveFavorites()
        DesignSystem.Haptics.medium()
    }

    // MARK: - Remove from Favorites

    func removeFromFavorites(_ item: FavoritePhotoItem) {
        favorites.removeAll { $0.id == item.id }

        // Update the photo in storage
        if let data = UserDefaults.standard.data(forKey: photosKey),
           var photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data) {
            if let photoIndex = photos.firstIndex(where: { $0.id == item.id }) {
                let photo = photos[photoIndex]
                photos[photoIndex] = GeneratedPhoto(
                    id: photo.id,
                    userId: photo.userId,
                    style: photo.style,
                    imageURL: photo.imageURL,
                    thumbnailURL: photo.thumbnailURL,
                    createdAt: photo.createdAt,
                    isFavorite: false,
                    favoriteRank: nil
                )

                if let updatedData = try? JSONEncoder().encode(photos) {
                    UserDefaults.standard.set(updatedData, forKey: photosKey)
                }
            }
        }

        saveFavorites()
    }

    // MARK: - Photo Detail

    func openPhotoDetail(_ item: FavoritePhotoItem) {
        if let index = favorites.firstIndex(where: { $0.id == item.id }) {
            detailStartingIndex = index
            showPhotoDetail = true
            DesignSystem.Haptics.light()
        }
    }

    // MARK: - Get Ranked Favorites (for share flow)

    /// Returns favorites sorted by rank for share prioritization.
    static func getRankedFavorites() -> [GeneratedPhoto] {
        guard let data = UserDefaults.standard.data(forKey: "gigarizz_generated_photos"),
              let photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data) else {
            return []
        }

        return photos
            .filter { $0.isFavorite }
            .sorted { photoA, photoB in
                let rankA = photoA.favoriteRank ?? Int.max
                let rankB = photoB.favoriteRank ?? Int.max
                return rankA < rankB
            }
    }
}