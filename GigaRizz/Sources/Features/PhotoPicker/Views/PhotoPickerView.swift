import PhotosUI
import SwiftUI

// MARK: - Photo Picker View

/// Main view for selecting 3-5 photos with quality preview.
/// Provides a grid of selected photos with quality indicators and a picker button.
struct PhotoPickerView: View {
    /// Callback when user completes photo selection.
    let onContinue: ([SelectedPhotoItem]) -> Void

    /// Optional callback when user cancels.
    var onCancel: (() -> Void)?

    @StateObject private var viewModel = PhotoPickerViewModel()
    @State private var selectedPhotoForRemoval: SelectedPhotoItem?
    @State private var showRemovalConfirmation = false

    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Content
                if viewModel.selectedPhotos.isEmpty {
                    emptyStateView
                } else {
                    photoGridView
                }

                Spacer()

                // Continue Button
                continueButtonView
            }
        }
        .sheet(isPresented: $viewModel.showPicker) {
            PHPickerSheet(
                minimumSelection: viewModel.minimumSelection,
                maximumSelection: viewModel.maximumSelection,
                onDismiss: { results in
                    Task { await viewModel.loadPhotos(from: results) }
                },
                onCancel: {
                    // User cancelled, no action needed
                },
                isPresented: $viewModel.showPicker
            )
        }
        .alert("Remove Photo", isPresented: $showRemovalConfirmation) {
            Button("Remove", role: .destructive) {
                if let photo = selectedPhotoForRemoval {
                    withAnimation(DesignSystem.Animation.cardSpring) {
                        viewModel.removePhoto(photo)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                selectedPhotoForRemoval = nil
            }
        } message: {
            Text("Remove this photo from your selection?")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            if let onCancel {
                Button {
                    DesignSystem.Haptics.light()
                    onCancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            Text("Select Photos")
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            // Selection count badge
            selectionBadge
                .opacity(viewModel.selectedPhotos.isEmpty ? 0 : 1)
                .scaleEffect(viewModel.selectedPhotos.isEmpty ? 0.8 : 1.0)
                .animation(DesignSystem.Animation.quickSpring, value: viewModel.selectedCount)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
    }

    // MARK: - Selection Badge

    private var selectionBadge: some View {
        HStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: "checkmark.circle.fill")
                .font(DesignSystem.Typography.caption)

            Text(viewModel.selectionCountText)
                .font(DesignSystem.Typography.caption)
        }
        .foregroundStyle(DesignSystem.Colors.flameOrange)
        .padding(.horizontal, DesignSystem.Spacing.small)
        .padding(.vertical, DesignSystem.Spacing.micro)
        .background(DesignSystem.Colors.flameOrange.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "photo.on.rectangle.angled",
            title: "No Photos Selected",
            subtitle: "Pick 3-5 photos to get started.\nWe'll analyze their quality for you.",
            ctaTitle: "Choose Photos"
        ) {
            DesignSystem.Haptics.medium()
            viewModel.showPicker = true
        }
    }

    // MARK: - Photo Grid View

    private var photoGridView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Add more photos button (if under max)
                if viewModel.selectedCount < viewModel.maximumSelection {
                    addPhotosButton
                }

                // Photo grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.small)
                    ],
                    spacing: DesignSystem.Spacing.small
                ) {
                    ForEach(Array(viewModel.selectedPhotos.enumerated()), id: \.element.id) { index, photo in
                        PhotoGridItem(
                            photo: photo,
                            orderNumber: index + 1,
                            issues: viewModel.issues(for: photo),
                            isRemovable: true,
                            onRemove: {
                                selectedPhotoForRemoval = photo
                                showRemovalConfirmation = true
                                DesignSystem.Haptics.medium()
                            }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)

                // Quality hints section
                if !viewModel.selectedPhotos.isEmpty {
                    qualityHintsSection
                }
            }
            .padding(.top, DesignSystem.Spacing.medium)
        }
    }

    // MARK: - Add Photos Button

    private var addPhotosButton: some View {
        Button {
            DesignSystem.Haptics.medium()
            viewModel.showPicker = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(DesignSystem.Typography.callout)

                Text("Add More Photos")
                    .font(DesignSystem.Typography.callout)

                Text("(\(viewModel.selectedCount)/\(viewModel.maximumSelection))")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .foregroundStyle(DesignSystem.Colors.flameOrange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.showPicker)
    }

    // MARK: - Quality Hints Section

    private var qualityHintsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Photo Quality Tips")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                qualityHintRow(icon: "sun.max.fill", text: "Good lighting helps AI create better results")
                qualityHintRow(icon: "person.fill", text: "Clear face shots work best")
                qualityHintRow(icon: "aqi.medium", text: "Sharp, in-focus photos preferred")
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .padding(.horizontal, DesignSystem.Spacing.medium)
    }

    private func qualityHintRow(icon: String, text: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .frame(width: 16)

            Text(text)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Continue Button

    private var continueButtonView: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            GRButton(
                title: viewModel.continueButtonTitle,
                icon: viewModel.canContinue ? "arrow.right" : nil,
                isDisabled: !viewModel.canContinue
            ) {
                DesignSystem.Haptics.medium()
                onContinue(viewModel.selectedPhotos)
            }
            .disabled(!viewModel.canContinue)

            // Selection hint
            if viewModel.selectedCount < viewModel.minimumSelection {
                Text("Select at least \(viewModel.minimumSelection) photos to continue")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(
            DesignSystem.Colors.background
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
        .animation(DesignSystem.Animation.quickSpring, value: viewModel.selectedCount)
    }
}

// MARK: - Photo Grid Item

/// Individual photo thumbnail in the selection grid.
struct PhotoGridItem: View {
    let photo: SelectedPhotoItem
    let orderNumber: Int
    let issues: [PhotoQualityIssue]
    let isRemovable: Bool
    let onRemove: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo thumbnail
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(DesignSystem.Animation.quickSpring, value: isPressed)

            // Quality issue indicator
            if !issues.isEmpty {
                qualityBadge
                    .transition(.scale.combined(with: .opacity))
            }

            // Order number badge
            orderNumberBadge
                .opacity(issues.isEmpty ? 1 : 0.3)

            // Remove button
            if isRemovable {
                removeButton
            }
        }
        .animation(DesignSystem.Animation.cardSpring, value: issues.count)
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed)
    }

    // MARK: - Quality Badge

    private var qualityBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.caption)

            Text("\(issues.count)")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(DesignSystem.Colors.warning)
        .padding(DesignSystem.Spacing.micro)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .padding(DesignSystem.Spacing.xs)
    }

    // MARK: - Order Number Badge

    private var orderNumberBadge: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                // Order number circle badge
                Text("\(orderNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: DesignSystem.Colors.flameOrange.opacity(0.4), radius: 3, x: 0, y: 2)
                    .padding(DesignSystem.Spacing.xs)
            }
        }
    }

    // MARK: - Remove Button

    private var removeButton: some View {
        Button {
            onRemove()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .background(Circle().fill(Color.black.opacity(0.6)))
        }
        .padding(DesignSystem.Spacing.xs)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Previews

#Preview("Photo Picker - Empty") {
    PhotoPickerView(
        onContinue: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("Photo Picker - With Photos") {
    PhotoPickerView(
        onContinue: { _ in }
    )
    .preferredColorScheme(.dark)
}
