import SwiftUI
import PhotosUI

// MARK: - Photo Comparison View

/// Full-screen before/after photo comparison with slider, flip, and side-by-side modes.
struct PhotoComparisonView: View {
    // MARK: - Properties

    let sourcePhotos: [UIImage]
    let generatedPhotos: [GeneratedPhoto]
    let styleName: String

    @State private var selectedSourceIndex = 0
    @State private var selectedGeneratedIndex = 0
    @State private var comparisonMode: ComparisonMode = .slider
    @State private var sliderPosition: CGFloat = 0.5
    @State private var isFlipped = false
    @State private var showShareSheet = false
    @State private var showSaveConfirmation = false
    @State private var hasRevealed = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Comparison Modes

    enum ComparisonMode: String, CaseIterable, Identifiable {
        case slider = "Slider"
        case flip = "Flip"
        case sideBySide = "Split"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .slider: return "slider.horizontal.3"
            case .flip: return "rotate.3d"
            case .sideBySide: return "rectangle.split.2x1"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: DesignSystem.Spacing.l) {
                    headerView
                    if sourcePhotos.count > 1 || generatedPhotos.count > 1 { pairingSelector }
                    comparisonDisplay
                    modePicker
                    actionButtons
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.bottom, DesignSystem.Spacing.l)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { DesignSystem.Haptics.light(); showShareSheet = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let comparisonImage = createComparisonImage() {
                    ShareSheet(items: [comparisonImage])
                }
            }
            .overlay {
                if showSaveConfirmation { saveConfirmationOverlay }
            }
        }
        .onAppear { performRevealAnimation() }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: DesignSystem.Spacing.micro) {
            Text("Before & After")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text("See the transformation")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.top, DesignSystem.Spacing.s)
    }

    // MARK: - Pairing Selector

    private var pairingSelector: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                Text("Original").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(0..<min(sourcePhotos.count, 4), id: \.self) { index in
                        thumbnailButton(image: sourcePhotos[index], isSelected: index == selectedSourceIndex) {
                            withAnimation(DesignSystem.Animation.quickSpring) {
                                selectedSourceIndex = index
                                DesignSystem.Haptics.light()
                            }
                        }
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.micro) {
                Text("Generated").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(0..<min(generatedPhotos.count, 4), id: \.self) { index in
                        generatedThumbnailButton(index: index, isSelected: index == selectedGeneratedIndex) {
                            withAnimation(DesignSystem.Animation.quickSpring) {
                                selectedGeneratedIndex = index
                                DesignSystem.Haptics.light()
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.s)
    }

    private func thumbnailButton(image: UIImage, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .strokeBorder(isSelected ? DesignSystem.Colors.flameOrange : Color.clear, lineWidth: 2))
        }
    }

    private func generatedThumbnailButton(index: Int, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(LinearGradient(colors: gradientForIndex(index), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles").font(.system(size: 16)).foregroundStyle(.white.opacity(0.8))
            }
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .strokeBorder(isSelected ? DesignSystem.Colors.goldAccent : Color.clear, lineWidth: 2))
        }
    }

    // MARK: - Comparison Display

    @ViewBuilder private var comparisonDisplay: some View {
        ZStack {
            switch comparisonMode {
            case .slider: sliderComparison
            case .flip: flipComparison
            case .sideBySide: sideBySideComparison
            }
        }
        .frame(height: 380)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .cardShadow()
    }

    private var sliderComparison: some View {
        GeometryReader { geometry in
            ZStack {
                generatedPhotoPlaceholder
                sourcePhotoView.frame(width: geometry.size.width * sliderPosition).clipped()
                Rectangle().fill(Color.white).frame(width: 4)
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                sliderHandle(geometry: geometry)
            }
        }
        .gesture(DragGesture().onChanged { value in
            let geometryWidth = UIScreen.main.bounds.width - DesignSystem.Spacing.m * 2
            sliderPosition = min(max(value.location.x / geometryWidth, 0.05), 0.95)
        })
        .contentShape(Rectangle())
    }

    private func sliderHandle(geometry: GeometryProxy) -> some View {
        ZStack {
            Circle().fill(DesignSystem.Colors.surface).frame(width: 36, height: 36)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
            HStack(spacing: 2) {
                Image(systemName: "chevron.left").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
            }
        }
        .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var flipComparison: some View {
        ZStack {
            if isFlipped {
                generatedPhotoPlaceholder.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                sourcePhotoView
            }
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .animation(DesignSystem.Animation.cardSpring, value: isFlipped)
        .onTapGesture {
            withAnimation(DesignSystem.Animation.cardSpring) {
                isFlipped.toggle()
                DesignSystem.Haptics.medium()
            }
        }
    }

    private var sideBySideComparison: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            VStack(spacing: DesignSystem.Spacing.micro) {
                sourcePhotoView.frame(maxWidth: .infinity)
                Text("Original").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            Rectangle().fill(DesignSystem.Colors.divider).frame(width: 1)
            VStack(spacing: DesignSystem.Spacing.micro) {
                generatedPhotoPlaceholder.frame(maxWidth: .infinity)
                Text("AI Generated").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.flameOrange)
            }
        }
    }

    private var sourcePhotoView: some View {
        Group {
            if sourcePhotos.indices.contains(selectedSourceIndex) {
                Image(uiImage: sourcePhotos[selectedSourceIndex]).resizable().scaledToFill()
            } else {
                placeholderView(title: "Original", gradient: [.gray, .gray.opacity(0.5)])
            }
        }
    }

    private var generatedPhotoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(LinearGradient(colors: gradientForIndex(selectedGeneratedIndex), startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(spacing: DesignSystem.Spacing.m) {
                Image(systemName: "sparkles").font(.system(size: 48, weight: .light)).foregroundStyle(.white.opacity(0.8))
                Text("AI Enhanced").font(DesignSystem.Typography.callout).foregroundStyle(.white.opacity(0.9))
                Text(styleName).font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.goldAccent)
            }
        }
    }

    private func placeholderView(title: String, gradient: [Color]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(title).font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            ForEach(ComparisonMode.allCases) { mode in
                Button {
                    withAnimation(DesignSystem.Animation.quickSpring) {
                        comparisonMode = mode
                        DesignSystem.Haptics.light()
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.micro) {
                        Image(systemName: mode.icon).font(.system(size: 14))
                        Text(mode.rawValue).font(DesignSystem.Typography.smallButton)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.s).padding(.vertical, DesignSystem.Spacing.xs)
                    .background(comparisonMode == mode ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surfaceSecondary)
                    .foregroundStyle(comparisonMode == mode ? .white : DesignSystem.Colors.textSecondary)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.s)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            GRButton(title: "Save Comparison", icon: "square.and.arrow.down") { saveComparisonToPhotos() }
            GRButton(title: "Share", icon: "square.and.arrow.up", style: .outline) {
                DesignSystem.Haptics.light()
                showShareSheet = true
            }
        }
    }

    private var saveConfirmationOverlay: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 48)).foregroundStyle(DesignSystem.Colors.success)
            Text("Saved to Photos!").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .cardShadow()
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(DesignSystem.Animation.quickSpring) { showSaveConfirmation = false }
            }
        }
    }

    private func gradientForIndex(_ index: Int) -> [Color] {
        let gradients: [[Color]] = [
            [DesignSystem.Colors.flameOrange, .orange],
            [.purple, .blue],
            [.teal, .cyan],
            [.pink, .red],
        ]
        return gradients[index % gradients.count]
    }

    private func performRevealAnimation() {
        if !hasRevealed {
            hasRevealed = true
            sliderPosition = 0.0
            withAnimation(.easeInOut(duration: 0.5)) { sliderPosition = 0.5 }
            DesignSystem.Haptics.medium()
        }
    }

    private func createComparisonImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 400))
        return renderer.image { _ in
            if sourcePhotos.indices.contains(selectedSourceIndex) {
                sourcePhotos[selectedSourceIndex].draw(in: CGRect(x: 0, y: 0, width: 400, height: 400))
            }
            let dividerPath = UIBezierPath(rect: CGRect(x: 398, y: 0, width: 4, height: 400))
            UIColor.white.setFill()
            dividerPath.fill()
            UIColor(gradientForIndex(selectedGeneratedIndex)[0]).setFill()
            UIRectFill(CGRect(x: 402, y: 0, width: 398, height: 400))
            let watermarkText = "GigaRizz AI"
            let watermarkFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
            let watermarkAttrs: [NSAttributedString.Key: Any] = [.font: watermarkFont, .foregroundColor: UIColor.white.withAlphaComponent(0.8)]
            let watermarkSize = watermarkText.size(withAttributes: watermarkAttrs)
            watermarkText.draw(at: CGPoint(x: 800 - watermarkSize.width - 16, y: 400 - watermarkSize.height - 16), withAttributes: watermarkAttrs)
        }
    }

    private func saveComparisonToPhotos() {
        guard let image = createComparisonImage() else { return }
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                try? PHPhotoLibrary.shared().performChangesAndWait {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                DispatchQueue.main.async {
                    withAnimation(DesignSystem.Animation.quickSpring) { showSaveConfirmation = true }
                    DesignSystem.Haptics.success()
                }
            }
        }
    }
}

#Preview {
    PhotoComparisonView(
        sourcePhotos: [],
        generatedPhotos: [GeneratedPhoto(userId: "demo", style: "Confident")],
        styleName: "Confident"
    ).preferredColorScheme(.dark)
}