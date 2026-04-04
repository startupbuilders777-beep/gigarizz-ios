import Foundation
import SwiftUI

// MARK: - Favorite Photo Item

/// Wrapper for GeneratedPhoto with favorite-specific state
struct FavoritePhotoItem: Identifiable, Equatable {
    let id: String
    let photo: GeneratedPhoto
    let platformTag: DatingPlatform?
    let addedToFavoritesAt: Date

    init(photo: GeneratedPhoto, platformTag: DatingPlatform? = nil, addedToFavoritesAt: Date = Date()) {
        self.id = photo.id
        self.photo = photo
        self.platformTag = platformTag
        self.addedToFavoritesAt = addedToFavoritesAt
    }
}

// MARK: - Favorites ViewModel

@MainActor
final class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var favoritePhotos: [FavoritePhotoItem] = []
    @Published var favoriteRanks: [String: Int] = [:] // photoId -> rank
    @Published var isLoading: Bool = false
    @Published var showPhotoDetail: Bool = false
    @Published var detailStartingIndex: Int = 0

    // MARK: - Computed Properties

    var topPlatform: DatingPlatform? {
        let platformCounts = Dictionary(grouping: favoritePhotos, by: { $0.platformTag ?? .general })
            .mapValues { $0.count }
        return platformCounts.max(by: { $0.value < $1.value })?.key
    }

    var weeklyAdditions: Int {
        let weekAgo = Date().addingTimeInterval(-7 * 86400)
        return favoritePhotos.filter { $0.addedToFavoritesAt >= weekAgo }.count
    }

    var totalFavorites: Int {
        favoritePhotos.count
    }

    // MARK: - Persistence Keys

    private let photosKey = "gigarizz_generated_photos"
    private let favoritesRanksKey = "gigarizz_favorites_ranks"
    private let favoritesAddedKey = "gigarizz_favorites_added_dates"

    // MARK: - Init

    init() {
        loadFavorites()
    }

    // MARK: - Load Favorites

    func loadFavorites() {
        isLoading = true

        // Load photos from UserDefaults
        if let data = UserDefaults.standard.data(forKey: photosKey),
           let photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data) {
            // Filter favorites
            let favorites = photos.filter { $0.isFavorite }

            // Load ranks
            if let ranksData = UserDefaults.standard.data(forKey: favoritesRanksKey),
               let ranks = try? JSONDecoder().decode([String: Int].self, from: ranksData) {
                favoriteRanks = ranks
            }

            // Load added dates
            var addedDates: [String: Date] = [:]
            if let addedData = UserDefaults.standard.data(forKey: favoritesAddedKey),
               let dates = try? JSONDecoder().decode([String: Date].self, from: addedData) {
                addedDates = dates
            }

            // Create favorite items
            favoritePhotos = favorites.map { photo in
                FavoritePhotoItem(
                    photo: photo,
                    platformTag: inferPlatform(from: photo),
                    addedToFavoritesAt: addedDates[photo.id] ?? photo.createdAt
                )
            }

            // Sort by rank
            sortByRank()
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

    // MARK: - Rank Management

    func rankForPhoto(_ photoId: String) -> Int {
        favoriteRanks[photoId] ?? (favoritePhotos.firstIndex(where: { $0.id == photoId }) ?? 0) + 1
    }

    func sortByRank() {
        // Sort by rank, assign ranks if missing
        var sortedPhotos: [FavoritePhotoItem] = []

        // First, photos with explicit ranks
        let withRanks = favoritePhotos.filter { favoriteRanks[$0.id] != nil }
            .sorted { favoriteRanks[$0.id] ?? 999 < favoriteRanks[$1.id] ?? 999 }

        // Then, photos without ranks (by added date)
        let withoutRanks = favoritePhotos.filter { favoriteRanks[$0.id] == nil }
            .sorted { $0.addedToFavoritesAt > $1.addedToFavoritesAt }

        sortedPhotos = withRanks + withoutRanks

        // Assign ranks if missing
        for (index, item) in sortedPhotos.enumerated() {
            if favoriteRanks[item.id] == nil {
                favoriteRanks[item.id] = index + 1
            }
        }

        favoritePhotos = sortedPhotos
        saveRanks()
    }

    func reorderPhoto(from source: Int, to destination: Int) {
        guard source != destination,
              source >= 0, source < favoritePhotos.count,
              destination >= 0, destination < favoritePhotos.count
        else { return }

        let movedPhoto = favoritePhotos.remove(at: source)
        favoritePhotos.insert(movedPhoto, at: destination)

        // Update all ranks
        for (index, item) in favoritePhotos.enumerated() {
            favoriteRanks[item.id] = index + 1
        }

        saveRanks()
        DesignSystem.Haptics.medium()
    }

    // MARK: - Remove from Favorites

    func removeFromFavorites(_ photoId: String) {
        // Remove from local list
        favoritePhotos.removeAll { $0.id == photoId }
        favoriteRanks.removeValue(forKey: photoId)

        // Update all ranks
        for (index, item) in favoritePhotos.enumerated() {
            favoriteRanks[item.id] = index + 1
        }

        // Update the original photo in storage
        updatePhotoFavoriteStatus(photoId, isFavorite: false)

        saveRanks()
        DesignSystem.Haptics.medium()
    }

    // MARK: - Update Photo Favorite Status

    private func updatePhotoFavoriteStatus(_ photoId: String, isFavorite: Bool) {
        guard var data = UserDefaults.standard.data(forKey: photosKey),
              var photos = try? JSONDecoder().decode([GeneratedPhoto].self, from: data)
        else { return }

        if let index = photos.firstIndex(where: { $0.id == photoId }) {
            let photo = photos[index]
            photos[index] = GeneratedPhoto(
                id: photo.id,
                userId: photo.userId,
                style: photo.style,
                imageURL: photo.imageURL,
                thumbnailURL: photo.thumbnailURL,
                createdAt: photo.createdAt,
                isFavorite: isFavorite
            )

            if let encoded = try? JSONEncoder().encode(photos) {
                UserDefaults.standard.set(encoded, forKey: photosKey)
            }
        }
    }

    // MARK: - Save Ranks

    func saveRanks() {
        if let data = try? JSONEncoder().encode(favoriteRanks) {
            UserDefaults.standard.set(data, forKey: favoritesRanksKey)
        }
    }

    // MARK: - Photo Detail

    func openPhotoDetail(_ photoId: String) {
        if let index = favoritePhotos.firstIndex(where: { $0.id == photoId }) {
            detailStartingIndex = index
            showPhotoDetail = true
            DesignSystem.Haptics.light()
        }
    }
}