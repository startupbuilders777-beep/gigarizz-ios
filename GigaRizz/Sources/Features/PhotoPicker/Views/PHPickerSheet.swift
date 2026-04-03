import PhotosUI
import SwiftUI

// MARK: - PHPicker Sheet

/// UIViewControllerRepresentable wrapper for PHPickerViewController.
/// Provides privacy-respecting photo library access with multi-selection support.
struct PHPickerSheet: UIViewControllerRepresentable {
    /// Minimum number of photos required.
    let minimumSelection: Int

    /// Maximum number of photos allowed.
    let maximumSelection: Int

    /// Callback when picker is dismissed with results.
    let onDismiss: ([PHPickerResult]) -> Void

    /// Callback when picker is cancelled.
    let onCancel: () -> Void

    /// Whether the picker is currently shown.
    @Binding var isPresented: Bool

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = maximumSelection
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }

    // MARK: - Coordinator

    /// Coordinator handles PHPickerViewControllerDelegate callbacks.
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerSheet

        init(_ parent: PHPickerSheet) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            if results.isEmpty {
                parent.onCancel()
            } else {
                parent.onDismiss(results)
            }
        }
    }
}
