import PhotosUI
import SwiftUI

// MARK: - Photo Picker View Model

/// View model managing photo selection state and quality analysis.
@MainActor
final class PhotoPickerViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Currently selected photo items with loaded images.
    @Published private(set) var selectedPhotos: [SelectedPhotoItem] = []

    /// PHPicker results pending image loading.
    @Published private(set) var pendingResults: [PHPickerResult] = []

    /// Quality issues detected for each photo (keyed by photo ID).
    @Published private(set) var qualityIssues: [String: [PhotoQualityIssue]] = [:]

    /// Whether images are currently being loaded.
    @Published private(set) var isLoading = false

    /// Whether the picker sheet is presented.
    @Published var showPicker = false

    // MARK: - Constants

    let minimumSelection = 3
    let maximumSelection = 5

    // MARK: - Computed Properties

    /// Whether the Continue button should be enabled.
    var canContinue: Bool {
        selectedPhotos.count >= minimumSelection
    }

    /// Number of currently selected photos.
    var selectedCount: Int {
        selectedPhotos.count
    }

    /// Text showing current selection count.
    var selectionCountText: String {
        "\(selectedPhotos.count)/\(maximumSelection)"
    }

    /// Text for continue button based on selection state.
    var continueButtonTitle: String {
        if selectedPhotos.isEmpty {
            return "Select Photos"
        } else if selectedPhotos.count < minimumSelection {
            let remaining = minimumSelection - selectedPhotos.count
            return "Select \(remaining) more photo\(remaining == 1 ? "" : "s")"
        } else {
            return "Continue"
        }
    }

    // MARK: - Photo Loading

    /// Loads images from PHPicker results.
    /// - Parameter results: Array of PHPickerResult from the picker.
    func loadPhotos(from results: [PHPickerResult]) async {
        pendingResults = results
        isLoading = true
        defer { isLoading = false }

        var loadedPhotos: [SelectedPhotoItem] = []
        var detectedIssues: [String: [PhotoQualityIssue]] = [:]

        for result in results {
            guard let data = try? await loadImageData(from: result),
                  let image = UIImage(data: data) else {
                continue
            }

            let photoItem = SelectedPhotoItem(image: image)
            loadedPhotos.append(photoItem)

            // Analyze photo quality in background
            let issues = await PhotoQualityAnalyzer.analyze(image: image)
            if !issues.isEmpty {
                detectedIssues[photoItem.id] = issues
            }
        }

        selectedPhotos = loadedPhotos
        qualityIssues = detectedIssues
    }

    /// Loads image data from a PHPicker result.
    private func loadImageData(from result: PHPickerResult) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            let itemProvider = result.itemProvider

            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: data)
                    }
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Photo Management

    /// Removes a photo from the selection.
    /// - Parameter photo: The photo item to remove.
    func removePhoto(_ photo: SelectedPhotoItem) {
        selectedPhotos.removeAll { $0.id == photo.id }
        qualityIssues.removeValue(forKey: photo.id)
        DesignSystem.Haptics.light()
    }

    /// Removes photo at the specified index.
    /// - Parameter index: Index of the photo to remove.
    func removePhoto(at index: Int) {
        guard index >= 0 && index < selectedPhotos.count else { return }
        let photo = selectedPhotos[index]
        removePhoto(photo)
    }

    /// Reorders photos by moving one index to another.
    /// - Parameters:
    ///   - source: Source index.
    ///   - destination: Destination index.
    func movePhoto(from source: IndexSet, to destination: Int) {
        selectedPhotos.move(fromOffsets: source, toOffset: destination)
        DesignSystem.Haptics.light()
    }

    /// Returns quality issues for a specific photo.
    /// - Parameter photo: The photo to check.
    /// - Returns: Array of quality issues, or empty array if none.
    func issues(for photo: SelectedPhotoItem) -> [PhotoQualityIssue] {
        qualityIssues[photo.id] ?? []
    }

    /// Checks if a photo has any quality issues.
    /// - Parameter photo: The photo to check.
    /// - Returns: True if the photo has quality issues.
    func hasIssues(_ photo: SelectedPhotoItem) -> Bool {
        !issues(for: photo).isEmpty
    }

    // MARK: - Reset

    /// Clears all selected photos and pending state.
    func reset() {
        selectedPhotos = []
        pendingResults = []
        qualityIssues = [:]
        isLoading = false
        showPicker = false
    }
}
