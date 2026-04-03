import Photos
import PhotosUI
import SwiftUI

// MARK: - Photo Library Service

/// Handles saving photos to the iOS Photo Library with proper permission handling.
@MainActor
final class PhotoLibraryService: ObservableObject {
    // MARK: - Published State

    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isSaving: Bool = false
    @Published var savedCount: Int = 0
    @Published var totalToSave: Int = 0
    @Published var lastError: PhotoLibraryError?
    @Published var showSuccessConfirmation: Bool = false

    // MARK: - Properties

    private let photoLibrary = PHPhotoLibrary.shared()

    // MARK: - Initialization

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Checks current photo library authorization status.
    func checkAuthorizationStatus() {
        if #available(iOS 14, *) {
            authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            authorizationStatus = PHPhotoLibrary.authorizationStatus()
        }
    }

    /// Requests photo library access permission.
    /// Returns true if permission was granted or already granted.
    func requestAuthorization() async -> Bool {
        checkAuthorizationStatus()

        // Already authorized
        if authorizationStatus == .authorized || authorizationStatus == .limited {
            return true
        }

        // Request permission
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        } else {
            status = PHPhotoLibrary.requestAuthorization()
        }

        authorizationStatus = status
        return status == .authorized || status == .limited
    }

    /// Returns whether the app can save to photo library.
    var canSave: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    /// Returns whether permission was denied (user rejected or restricted).
    var isPermissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // MARK: - Save Operations

    /// Saves a single UIImage to the photo library.
    /// - Parameters:
    ///   - image: The image to save
    ///   - metadata: Optional metadata to include
    /// - Returns: The local identifier of the saved asset
    @discardableResult
    func saveImage(
        _ image: UIImage,
        metadata: [String: Any]? = nil
    ) async throws -> String {
        // Check/request authorization
        guard await requestAuthorization() else {
            throw PhotoLibraryError.permissionDenied
        }

        isSaving = true
        lastError = nil

        do {
            let localIdentifier = try await performSave(image: image, metadata: metadata)
            isSaving = false
            DesignSystem.Haptics.success()
            return localIdentifier
        } catch {
            isSaving = false
            lastError = error as? PhotoLibraryError ?? PhotoLibraryError.saveFailed(error.localizedDescription)
            DesignSystem.Haptics.error()
            throw error
        }
    }

    /// Saves multiple images to the photo library in sequence.
    /// - Parameters:
    ///   - images: The images to save
    ///   - metadata: Optional shared metadata for all images
    /// - Returns: Array of local identifiers for saved assets
    @discardableResult
    func saveImages(
        _ images: [UIImage],
        metadata: [String: Any]? = nil
    ) async throws -> [String] {
        guard !images.isEmpty else { return [] }

        // Check/request authorization
        guard await requestAuthorization() else {
            throw PhotoLibraryError.permissionDenied
        }

        isSaving = true
        savedCount = 0
        totalToSave = images.count
        lastError = nil

        var identifiers: [String] = []

        for (index, image) in images.enumerated() {
            do {
                let identifier = try await performSave(image: image, metadata: metadata)
                identifiers.append(identifier)
                savedCount = index + 1

                // Light haptic for each photo saved
                DesignSystem.Haptics.light()
            } catch {
                isSaving = false
                lastError = error as? PhotoLibraryError ?? PhotoLibraryError.saveFailed(error.localizedDescription)
                DesignSystem.Haptics.error()
                throw error
            }
        }

        isSaving = false
        DesignSystem.Haptics.success()

        // Show success confirmation
        withAnimation(DesignSystem.Animation.smoothSpring) {
            showSuccessConfirmation = true
        }

        // Auto-dismiss confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(DesignSystem.Animation.easeOut) {
                self.showSuccessConfirmation = false
            }
        }

        return identifiers
    }

    /// Performs the actual save operation to photo library.
    private func performSave(
        image: UIImage,
        metadata: [String: Any]? = nil
    ) async throws -> String {
        // Create asset creation request
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                // Create asset from image
                let creationRequest = PHAssetCreationRequest.creationRequestForAsset(from: image)

                // Add metadata if provided
                if let metadata = metadata {
                    creationRequest.metadata = metadata
                }

                // Set creation date
                creationRequest.creationDate = Date()
            } completionHandler: { success, maybeError in
                Task { @MainActor in
                    if success {
                        // Fetch the local identifier
                        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
                        if let lastAsset = fetchResult.lastObject {
                            continuation.resume(returning: lastAsset.localIdentifier)
                        } else {
                            continuation.resume(returning: "")
                        }
                    } else {
                        let error = maybeError ?? NSError(domain: "PhotoLibraryService", code: -1, userInfo: nil)
                        continuation.resume(throwing: PhotoLibraryError.saveFailed(error.localizedDescription))
                    }
                }
            }
        }
    }

    // MARK: - Generated Photo Metadata

    /// Creates metadata dictionary for a GigaRizz generated photo.
    static func metadataForGeneratedPhoto(
        style: String,
        userId: String,
        aspectRatio: String = "1:1"
    ) -> [String: Any] {
        return [
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifUserComment as String: "Generated by GigaRizz - \(style) style"
            ],
            kCGImagePropertyIPTCDictionary as String: [
                kCGImagePropertyIPTCOriginatingProgram as String: "GigaRizz",
                kCGImagePropertyIPTCProgramVersion as String: "1.0"
            ],
            "GigaRizzStyle": style,
            "GigaRizzAspectRatio": aspectRatio,
            "GigaRizzUserId": userId
        ]
    }

    // MARK: - Settings URL

    /// Returns URL to iOS Settings app for photo library permissions.
    static func settingsURL() -> URL? {
        URL(string: "App-Prefs:root=Privacy&path=PHOTOS") ?? URL(string: UIApplication.openSettingsURLString)
    }

    /// Opens iOS Settings for photo library permissions.
    func openSettings() {
        guard let url = Self.settingsURL() else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Photo Library Error

enum PhotoLibraryError: LocalizedError {
    case permissionDenied
    case saveFailed(String)
    case noImagesToSave

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo library access denied. Please enable it in Settings."
        case .saveFailed(let message):
            return "Failed to save photo: \(message)"
        case .noImagesToSave:
            return "No photos to save."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Open Settings and allow GigaRizz to add photos to your library."
        case .saveFailed:
            return "Try saving again or check available storage."
        case .noImagesToSave:
            return "Generate photos first, then save them."
        }
    }
}

// MARK: - Save Progress View

struct SaveProgressView: View {
    let savedCount: Int
    let totalToSave: Int

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.surfaceSecondary, lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignSystem.Animation.quickSpring, value: progress)

                Text("\(savedCount)/\(totalToSave)")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            Text("Saving to Photos...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var progress: Double {
        guard totalToSave > 0 else { return 0 }
        return Double(savedCount) / Double(totalToSave)
    }
}

// MARK: - Save Success View

struct SaveSuccessView: View {
    let savedCount: Int
    @State private var showCheckmark = false
    @State private var scale: CGFloat = 0.5

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            // Animated checkmark
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.success)
                    .frame(width: 28, height: 28)
                    .scaleEffect(scale)
                    .onAppear {
                        withAnimation(DesignSystem.Animation.cardSpring) {
                            scale = 1.0
                        }
                        withAnimation(DesignSystem.Animation.cardSpring.delay(0.2)) {
                            showCheckmark = true
                        }
                    }

                if showCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Text("\(savedCount) photos saved to library!")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.surface)
        .clipShape(Capsule())
        .cardShadow()
    }
}

// MARK: - Permission Denied View

struct PermissionDeniedView: View {
    let onOpenSettings: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: "photo.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(DesignSystem.Colors.error)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Photo Library Access Required")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Enable photo library access in Settings to save your generated photos.")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                GRButton(
                    title: "Open Settings",
                    icon: "gear",
                    action: onOpenSettings
                )

                Button(action: onRetry) {
                    Text("Try Again")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
        }
        .padding(DesignSystem.Spacing.l)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .cardShadow()
    }
}

#Preview("SaveProgressView") {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()
        SaveProgressView(savedCount: 2, totalToSave: 4)
    }
    .preferredColorScheme(.dark)
}

#Preview("SaveSuccessView") {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()
        VStack {
            Spacer()
            SaveSuccessView(savedCount: 4)
            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("PermissionDeniedView") {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()
        PermissionDeniedView(
            onOpenSettings: {},
            onRetry: {}
        )
    }
    .preferredColorScheme(.dark)
}