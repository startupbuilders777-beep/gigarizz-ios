@preconcurrency import FirebaseStorage
import Foundation
import UIKit

/// Manages Firebase Storage operations for photo upload/download.
@MainActor
final class StorageManager: ObservableObject {
    // MARK: - Singleton

    static let shared = StorageManager()

    // MARK: - Published Properties

    @Published var uploadProgress: Double = 0
    @Published var isUploading = false
    @Published var isDownloading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let storage = Storage.storage()
    private let maxDimension: CGFloat = 2048
    private let compressionQuality: CGFloat = 0.85

    // MARK: - Init

    init() {}

    // MARK: - Upload

    func uploadPhoto(
        image: UIImage,
        userId: String,
        photoId: String
    ) async throws -> URL {
        isUploading = true
        uploadProgress = 0
        errorMessage = nil
        defer { isUploading = false }

        let compressed = try compressImage(image)
        guard let data = compressed.jpegData(compressionQuality: compressionQuality)
            ?? compressed.pngData() else {
            throw NSError(domain: "StorageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let path = "users/\(userId)/photos/\(photoId)_original.jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "uid": userId,
            "photoId": photoId,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        _ = try await ref.putDataAsync(data, metadata: metadata)

        let downloadURL = try await ref.downloadURL()
        DesignSystem.Haptics.success()
        return downloadURL
    }

    // MARK: - Download

    func downloadPhoto(url: URL) async throws -> Data {
        isDownloading = true
        errorMessage = nil
        defer { isDownloading = false }

        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    // MARK: - Delete

    func deletePhoto(userId: String, photoId: String) async throws {
        let path = "users/\(userId)/photos/\(photoId)_original.jpg"
        let ref = storage.reference().child(path)
        try await ref.delete()
    }

    // MARK: - Private Helpers

    private func compressImage(_ image: UIImage) throws -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = size.width / size.height
        let newSize: CGSize

        if ratio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized
    }
}
