import SwiftUI

// MARK: - Full Screen Photo Preview View

/// Immersive full-screen photo viewer with swipe, pinch-to-zoom, and action bar.
/// Feels like Apple Photos — familiar, responsive, zero friction.
struct FullScreenPhotoPreviewView: View {
    let photos: [GeneratedPhoto]
    @Binding var startingIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showOverlays: Bool = true
    @State private var showSwipeHint: Bool = true
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    @Environment(\.dismiss) private var dismiss

    private let maxScale: CGFloat = 3.0
    private let zoomThreshold: CGFloat = 0.9
    private let dismissThreshold: CGFloat = 120

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pure black background
                Color.black
                    .ignoresSafeArea()
                    .gesture(dismissDragGesture(in: geometry))

                // Photo pages with zoom
                TabView(selection: $currentIndex) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        ZoomablePhotoView(
                            photo: photo,
                            scale: $scale,
                            lastScale: $lastScale,
                            offset: $offset,
                            lastOffset: $lastOffset,
                            maxScale: maxScale,
                            geometry: geometry
                        )
                        .tag(index)
                        .onChange(of: currentIndex) { _, _ in
                            // Reset zoom when page changes
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                            DesignSystem.Haptics.light()
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Swipe hint (first open only)
                if showSwipeHint && photos.count > 1 {
                    swipeHintOverlay
                }

                // Overlays
                if showOverlays {
                    VStack {
                        // Top info overlay
                        infoOverlay
                            .transition(.move(edge: .top).combined(with: .opacity))

                        Spacer()

                        // Page indicator
                        if photos.count > 1 {
                            pageIndicatorDots
                        }

                        Spacer()

                        // Bottom action bar
                        actionBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .padding(.top, geometry.safeAreaInsets.top)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(!showOverlays)
        .ignoresSafeArea()
        .onAppear {
            currentIndex = startingIndex
            // Hide swipe hint after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showSwipeHint = false
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showOverlays.toggle()
            }
        }
        .onChange(of: currentIndex) { _, newIndex in
            startingIndex = newIndex
        }
    }

    // MARK: - Info Overlay

    private var infoOverlay: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
            HStack(spacing: DesignSystem.Spacing.small) {
                // Style preset badge
                styleBadge

                // Aspect ratio badge
                aspectRatioBadge

                Spacer()

                // Close button
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close preview")
            }

            // Date
            Text(formatDate(photos[currentIndex].createdAt))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.top, DesignSystem.Spacing.small)
    }

    private var styleBadge: some View {
        HStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 10))
            Text(photos[currentIndex].style)
                .font(DesignSystem.Typography.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, DesignSystem.Spacing.small)
        .padding(.vertical, DesignSystem.Spacing.micro)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.flameOrange.opacity(0.8))
        )
        .accessibilityLabel("\(photos[currentIndex].style) style")
    }

    private var aspectRatioBadge: some View {
        HStack(spacing: DesignSystem.Spacing.micro) {
            Image(systemName: "aspectratio")
                .font(.system(size: 10))
            Text("4:5")
                .font(DesignSystem.Typography.caption)
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, DesignSystem.Spacing.small)
        .padding(.vertical, DesignSystem.Spacing.micro)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .accessibilityLabel("Photo aspect ratio 4 to 5")
    }

    // MARK: - Page Indicator

    private var pageIndicatorDots: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<photos.count, id: \.self) { index in
                pageIndicatorDot(for: index)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .accessibilityLabel("Photo \(currentIndex + 1) of \(photos.count)")
        .accessibilityHint("Swipe left or right to change photos")
    }

    @ViewBuilder
    private func pageIndicatorDot(for index: Int) -> some View {
        Circle()
            .fill(index == currentIndex ? DesignSystem.Colors.flameOrange : Color.white.opacity(0.4))
            .frame(width: 6, height: 6)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentIndex)
            .accessibilityLabel("Photo \(index + 1), \(index == currentIndex ? "current" : "not current")")
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 0) {
            // Save
            actionButton(icon: "square.and.arrow.down", label: "Save") {
                savePhoto()
            }

            Spacer()

            // Share
            actionButton(icon: "square.and.arrow.up", label: "Share") {
                sharePhoto()
            }

            Spacer()

            // Favorite
            actionButton(
                icon: photos[currentIndex].isFavorite ? "heart.fill" : "heart",
                label: "Favorite",
                isActive: photos[currentIndex].isFavorite
            ) {
                toggleFavorite()
            }

            Spacer()

            // Delete
            actionButton(icon: "trash", label: "Delete", isDestructive: true) {
                deletePhoto()
            }

            Spacer()

            // More
            actionButton(icon: "ellipsis", label: "More") {
                showMoreOptions()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
        )
    }

    private func actionButton(
        icon: String,
        label: String,
        isActive: Bool = false,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            DesignSystem.Haptics.medium()
            action()
        } label: {
            VStack(spacing: DesignSystem.Spacing.micro) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isDestructive ? DesignSystem.Colors.error : (isActive ? DesignSystem.Colors.flameOrange : .white))
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(width: 60)
        }
        .accessibilityLabel(accessibilityLabelForAction(label, isActive: isActive, isDestructive: isDestructive))
        .accessibilityHint(accessibilityHintForAction(label))
        .accessibilityAddTraits(.isButton)
    }

    private func accessibilityLabelForAction(_ label: String, isActive: Bool, isDestructive: Bool) -> String {
        switch label {
        case "Save": return "Save photo"
        case "Share": return "Share photo"
        case "Favorite": return isActive ? "Remove from favorites" : "Add to favorites"
        case "Delete": return "Delete photo"
        case "More": return "More options"
        default: return "\(label) photo"
        }
    }

    private func accessibilityHintForAction(_ label: String) -> String {
        switch label {
        case "Save": return "Double tap to save to your photo library"
        case "Share": return "Double tap to share this photo"
        case "Favorite": return "Double tap to toggle favorite"
        case "Delete": return "Double tap to delete this photo"
        case "More": return "Double tap to see more options"
        default: return ""
        }
    }

    // MARK: - Swipe Hint

    private var swipeHintOverlay: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .semibold))
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .transition(.opacity)
        .accessibilityHidden(true)
    }

    // MARK: - Gestures

    private func dismissDragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow dismiss when not zoomed and dragging down
                if scale < zoomThreshold && value.translation.height > 0 {
                    isDragging = true
                    dragOffset = value.translation

                    // Dim background based on drag distance
                    let progress = min(value.translation.height / dismissThreshold, 1.0)
                }
            }
            .onEnded { value in
                isDragging = false
                if scale < zoomThreshold && value.translation.height > dismissThreshold {
                    // Dismiss with spring animation
                    onDismiss()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    // MARK: - Actions

    private func savePhoto() {
        DesignSystem.Haptics.success()
        // Save logic would go here
    }

    private func sharePhoto() {
        DesignSystem.Haptics.light()
        // Share logic would go here
    }

    private func toggleFavorite() {
        DesignSystem.Haptics.medium()
        // Toggle favorite logic would go here
    }

    private func deletePhoto() {
        DesignSystem.Haptics.heavy()
        // Delete logic would go here
    }

    private func showMoreOptions() {
        DesignSystem.Haptics.light()
        // More options would go here
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Zoomable Photo View

struct ZoomablePhotoView: View {
    let photo: GeneratedPhoto
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    let maxScale: CGFloat
    let geometry: GeometryProxy

    @State private var doubleTapScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Photo placeholder (replace with actual image loading)
                photoPlaceholder
                    .scaleEffect(scale * doubleTapScale)
                    .offset(x: offset.width, y: offset.height)
                    .gesture(magnificationGesture)
                    .gesture(doubleTapGesture(in: geo))
                    .gesture(dragGesture)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            // Gradient background matching the photo style
            LinearGradient(
                colors: gradientForStyle(photo.style),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "person.fill")
                    .font(.system(size: 100, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.4))

                if let imageURL = photo.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
        }
    }

    private func gradientForStyle(_ style: String) -> [Color] {
        switch style.lowercased() {
        case "confident":
            return [DesignSystem.Colors.flameOrange, .orange]
        case "mysterious":
            return [.purple, .blue]
        case "playful":
            return [.pink, .yellow]
        case "professional":
            return [DesignSystem.Colors.deepNight, .indigo]
        default:
            return [DesignSystem.Colors.flameOrange, .orange]
        }
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                let newScale = scale * delta
                scale = min(max(newScale, 1.0), maxScale)
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1.0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 1.0
                        offset = .zero
                    }
                }
            }
    }

    private func doubleTapGesture(in geo: GeometryProxy) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                DesignSystem.Haptics.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if doubleTapScale > 1.0 {
                        doubleTapScale = 1.0
                        offset = .zero
                    } else {
                        doubleTapScale = 2.0
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1.0 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                if scale > 1.0 {
                    lastOffset = offset
                }
            }
    }
}

#Preview {
    FullScreenPhotoPreviewView(
        photos: [
            GeneratedPhoto(userId: "demo", style: "Confident"),
            GeneratedPhoto(userId: "demo", style: "Mysterious"),
            GeneratedPhoto(userId: "demo", style: "Playful")
        ],
        startingIndex: .constant(0),
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
