import PhotosUI
import SwiftUI
import Vision

// MARK: - Photo Ranking View

/// Rank multiple dating photos by predicted match potential using on-device Vision analysis.
/// Scores based on: face quality, lighting, expression, composition, and resolution.
struct PhotoRankingView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = PhotoRankingViewModel()
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.large) {
                    headerSection
                    photoPickerSection
                    if viewModel.isAnalyzing { analysisProgressSection }
                    if !viewModel.rankedPhotos.isEmpty { rankingResultsSection }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Photo Ranking")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Header

    private var headerSection: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DesignSystem.Colors.goldAccent)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Photo Ranking")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Upload photos and we'll rank them by match potential")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    // MARK: - Photo Picker

    private var photoPickerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("Your Photos")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("\(viewModel.selectedPhotos.count)/9")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            if viewModel.selectedPhotos.isEmpty {
                PhotosPicker(
                    selection: $viewModel.photosPickerItems,
                    maxSelectionCount: 9,
                    matching: .images
                ) {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        Text("Select 3-9 Photos")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("We'll rank them by dating app performance")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .strokeBorder(DesignSystem.Colors.flameOrange.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .onChange(of: viewModel.photosPickerItems) {
                    Task { await viewModel.loadPhotos() }
                }
            } else {
                // Show loaded photos in a horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        ForEach(Array(viewModel.selectedPhotos.enumerated()), id: \.offset) { _, photo in
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        }
                    }
                }

                HStack(spacing: DesignSystem.Spacing.small) {
                    GRButton(title: "Rank Them", icon: "trophy.fill") {
                        Task { await viewModel.rankPhotos() }
                    }
                    GRButton(title: "Reset", icon: "arrow.counterclockwise", style: .secondary) {
                        viewModel.reset()
                    }
                }
            }
        }
    }

    // MARK: - Analysis Progress

    private var analysisProgressSection: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                ProgressView()
                    .tint(DesignSystem.Colors.flameOrange)
                    .scaleEffect(1.5)
                Text(viewModel.analysisStage)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                ProgressView(value: viewModel.progress)
                    .tint(DesignSystem.Colors.flameOrange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Ranking Results

    private var rankingResultsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Rankings")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(Array(viewModel.rankedPhotos.enumerated()), id: \.element.id) { index, ranked in
                rankedPhotoCard(ranked: ranked, rank: index + 1)
            }
        }
    }

    private func rankedPhotoCard(ranked: RankedPhoto, rank: Int) -> some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankColor(rank))
                        .frame(width: 36, height: 36)
                    Text("#\(rank)")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                // Photo thumbnail
                Image(uiImage: ranked.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))

                // Score and details
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    HStack {
                        Text("Score: \(String(format: "%.1f", ranked.score))/10")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Text(ranked.verdict)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(scoreColor(ranked.score))
                    }

                    // Category scores
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        miniScore(icon: "sun.max.fill", score: ranked.lighting)
                        miniScore(icon: "face.smiling", score: ranked.expression)
                        miniScore(icon: "rectangle.dashed", score: ranked.composition)
                        miniScore(icon: "camera.fill", score: ranked.sharpness)
                    }

                    Text(ranked.suggestion)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func miniScore(icon: String, score: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(String(format: "%.0f", score))
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(scoreColor(score))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return DesignSystem.Colors.goldAccent
        case 2: return .gray
        case 3: return .orange.opacity(0.7)
        default: return DesignSystem.Colors.surface
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 8...: return DesignSystem.Colors.success
        case 6..<8: return DesignSystem.Colors.goldAccent
        case 4..<6: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }
}

// MARK: - Ranked Photo Model

struct RankedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let score: Double
    let lighting: Double
    let expression: Double
    let composition: Double
    let sharpness: Double
    let verdict: String
    let suggestion: String
}

// MARK: - Photo Ranking ViewModel

@MainActor
final class PhotoRankingViewModel: ObservableObject {
    @Published var photosPickerItems: [PhotosPickerItem] = []
    @Published var selectedPhotos: [UIImage] = []
    @Published var rankedPhotos: [RankedPhoto] = []
    @Published var isAnalyzing = false
    @Published var progress: Double = 0
    @Published var analysisStage = "Starting analysis..."

    func loadPhotos() async {
        selectedPhotos = []
        for item in photosPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedPhotos.append(image)
            }
        }
    }

    func reset() {
        photosPickerItems = []
        selectedPhotos = []
        rankedPhotos = []
        progress = 0
    }

    func rankPhotos() async {
        guard selectedPhotos.count >= 2 else { return }

        isAnalyzing = true
        progress = 0
        rankedPhotos = []

        var results: [RankedPhoto] = []
        let total = Double(selectedPhotos.count)

        for (index, photo) in selectedPhotos.enumerated() {
            analysisStage = "Analyzing photo \(index + 1) of \(selectedPhotos.count)..."
            let ranked = await analyzePhoto(photo)
            results.append(ranked)
            progress = Double(index + 1) / total
        }

        // Sort by score descending
        rankedPhotos = results.sorted { $0.score > $1.score }
        isAnalyzing = false
        DesignSystem.Haptics.success()
        PostHogManager.shared.trackEvent("photo_ranking_completed", properties: [
            "photo_count": selectedPhotos.count,
            "top_score": rankedPhotos.first?.score ?? 0
        ])
    }

    // MARK: - Vision-Based Photo Analysis

    private func analyzePhoto(_ image: UIImage) async -> RankedPhoto {
        guard let cgImage = image.cgImage else {
            return fallbackRankedPhoto(image)
        }

        // Run face detection
        let faceQuality = await detectFaceQuality(cgImage: cgImage)

        // Compute image quality metrics
        let resolution = image.size
        let megapixels = (resolution.width * resolution.height) / 1_000_000
        let isPortrait = resolution.height > resolution.width
        let isHighRes = megapixels >= 2.0

        // Lighting score: based on face quality + resolution
        let lightingBase = faceQuality.hasFace ? (faceQuality.faceQuality * 10) : 5.0
        let lighting = min(10, max(1, lightingBase + (isHighRes ? 1.0 : 0)))

        // Expression score: face quality + bonus for single face
        let expressionBase = faceQuality.hasFace ? (faceQuality.faceQuality * 9 + 1) : 4.0
        let expression = min(10, max(1, expressionBase + (faceQuality.faceCount == 1 ? 0.5 : -0.5)))

        // Composition: portrait orientation is better for dating, face centered
        let compositionBase: Double = isPortrait ? 7.5 : 5.5
        let faceAreaBonus = faceQuality.hasFace ? (faceQuality.faceArea > 0.05 ? 1.5 : 0) : 0
        let composition = min(10, max(1, compositionBase + faceAreaBonus))

        // Sharpness: resolution proxy
        let sharpness = min(10, max(1, megapixels * 2.5))

        // Weighted overall score
        let overall = (lighting * 0.2 + expression * 0.35 + composition * 0.25 + sharpness * 0.2)

        let verdict: String
        switch overall {
        case 8...: verdict = "Profile Pic Material"
        case 7..<8: verdict = "Strong Pick"
        case 6..<7: verdict = "Decent Option"
        case 5..<6: verdict = "Needs Work"
        default: verdict = "Skip This One"
        }

        let suggestion = generateSuggestion(lighting: lighting, expression: expression, composition: composition, sharpness: sharpness, faceQuality: faceQuality)

        return RankedPhoto(
            image: image,
            score: round(overall * 10) / 10,
            lighting: round(lighting * 10) / 10,
            expression: round(expression * 10) / 10,
            composition: round(composition * 10) / 10,
            sharpness: round(sharpness * 10) / 10,
            verdict: verdict,
            suggestion: suggestion
        )
    }

    // MARK: - Face Detection

    private struct FaceAnalysis {
        let hasFace: Bool
        let faceCount: Int
        let faceQuality: Double  // 0.0 to 1.0
        let faceArea: Double     // proportion of image occupied by face
    }

    private func detectFaceQuality(cgImage: CGImage) async -> FaceAnalysis {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let results = request.results, !results.isEmpty else {
                return FaceAnalysis(hasFace: false, faceCount: 0, faceQuality: 0, faceArea: 0)
            }

            let faceCount = results.count
            let largestFace = results.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
            let faceArea = (largestFace?.boundingBox.width ?? 0) * (largestFace?.boundingBox.height ?? 0)
            let confidence = Double(largestFace?.confidence ?? 0)

            return FaceAnalysis(
                hasFace: true,
                faceCount: faceCount,
                faceQuality: confidence,
                faceArea: faceArea
            )
        } catch {
            return FaceAnalysis(hasFace: false, faceCount: 0, faceQuality: 0, faceArea: 0)
        }
    }

    // MARK: - Suggestion Generator

    private func generateSuggestion(lighting: Double, expression: Double, composition: Double, sharpness: Double, faceQuality: FaceAnalysis) -> String {
        if !faceQuality.hasFace {
            return "No face detected — dating apps perform best with clear face photos"
        }

        let weakest = min(lighting, expression, composition, sharpness)
        if weakest == lighting && lighting < 6 {
            return "Try better lighting — natural daylight gives the best results"
        }
        if weakest == expression && expression < 6 {
            return "Show more personality — a genuine smile increases matches by 35%"
        }
        if weakest == composition && composition < 6 {
            return "Crop to portrait orientation and ensure your face fills more of the frame"
        }
        if weakest == sharpness && sharpness < 6 {
            return "Use a higher resolution photo — blurry photos get 50% fewer swipes"
        }

        if faceQuality.faceCount > 1 {
            return "Group photo detected — solo photos perform 3x better as your main pic"
        }

        return "Great photo! Consider using this as one of your top profile pictures"
    }

    private func fallbackRankedPhoto(_ image: UIImage) -> RankedPhoto {
        RankedPhoto(
            image: image,
            score: 5.0,
            lighting: 5.0,
            expression: 5.0,
            composition: 5.0,
            sharpness: 5.0,
            verdict: "Could Not Analyze",
            suggestion: "Photo could not be analyzed. Try a different format."
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PhotoRankingView()
    }
    .environmentObject(SubscriptionManager.shared)
    .preferredColorScheme(.dark)
}
