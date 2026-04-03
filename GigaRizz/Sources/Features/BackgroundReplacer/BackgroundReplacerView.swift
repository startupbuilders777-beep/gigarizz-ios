import SwiftUI
import PhotosUI

// MARK: - Background Scene

struct BackgroundScene: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let gradient: [Color]
    let description: String
    let prompt: String
}

// MARK: - Background Replacer View

struct BackgroundReplacerView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = BackgroundReplacerViewModel()
    @State private var showPaywall = false

    private let scenes: [BackgroundScene] = [
        BackgroundScene(name: "Beach Sunset", icon: "sun.horizon.fill", gradient: [.orange, .pink], description: "Golden hour on the beach", prompt: "beach sunset golden hour"),
        BackgroundScene(name: "City Rooftop", icon: "building.2.fill", gradient: [.purple, .blue], description: "Urban skyline at night", prompt: "city rooftop night skyline"),
        BackgroundScene(name: "Mountain Trail", icon: "mountain.2.fill", gradient: [.green, .teal], description: "Scenic mountain hike", prompt: "mountain trail scenic view"),
        BackgroundScene(name: "Coffee Shop", icon: "cup.and.saucer.fill", gradient: [.brown, DesignSystem.Colors.goldAccent], description: "Cozy cafe vibes", prompt: "cozy coffee shop interior"),
        BackgroundScene(name: "Art Gallery", icon: "photo.artframe", gradient: [.gray, .white], description: "Sophisticated art space", prompt: "modern art gallery white walls"),
        BackgroundScene(name: "Sports Car", icon: "car.fill", gradient: [.red, .orange], description: "Luxury car backdrop", prompt: "luxury sports car sunset"),
        BackgroundScene(name: "Travel Exotic", icon: "airplane", gradient: [.cyan, .blue], description: "Exotic destination vibes", prompt: "exotic travel destination tropical"),
        BackgroundScene(name: "Dog Park", icon: "dog.fill", gradient: [DesignSystem.Colors.goldAccent, .orange], description: "With a cute dog", prompt: "dog park sunny day golden retriever"),
        BackgroundScene(name: "Concert", icon: "music.note", gradient: [.pink, .purple], description: "VIP festival energy", prompt: "concert festival vip area lights"),
    ]

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    headerSection
                    photoSection
                    if viewModel.selectedPhoto != nil { sceneGridSection }
                    if viewModel.isProcessing { processingOverlay }
                    if viewModel.resultImage != nil { resultSection }
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Background Replacer")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: viewModel.photosPickerItem) {
            Task { await viewModel.loadPhoto() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.m) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Scene Selector")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Upload a photo, pick a scene, get magic")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.m)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Your Photo")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let image = viewModel.selectedPhoto {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))

                    Button {
                        viewModel.clearPhoto()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.6)))
                    }
                    .padding(DesignSystem.Spacing.s)
                }
            } else {
                PhotosPicker(
                    selection: $viewModel.photosPickerItem,
                    matching: .images
                ) {
                    VStack(spacing: DesignSystem.Spacing.m) {
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)

                        Text("Upload a Photo")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("Works best with a clear selfie or portrait")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .strokeBorder(DesignSystem.Colors.flameOrange.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
            }
        }
    }

    // MARK: - Scene Grid

    private var sceneGridSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Choose a Scene")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.s),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.s),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.s),
            ], spacing: DesignSystem.Spacing.s) {
                ForEach(scenes) { scene in
                    sceneCard(scene)
                }
            }
        }
    }

    private func sceneCard(_ scene: BackgroundScene) -> some View {
        let isSelected = viewModel.selectedScene?.id == scene.id
        return Button {
            withAnimation(DesignSystem.Animation.quickSpring) {
                viewModel.selectedScene = scene
            }
            DesignSystem.Haptics.light()
        } label: {
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(
                            LinearGradient(
                                colors: scene.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)

                    Image(systemName: scene.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(isSelected ? DesignSystem.Colors.flameOrange : .clear, lineWidth: 2)
                )

                Text(scene.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                ProgressView()
                    .tint(DesignSystem.Colors.flameOrange)
                    .scaleEffect(1.5)

                Text("Replacing background...")
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                ProgressView(value: viewModel.progress)
                    .tint(DesignSystem.Colors.flameOrange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Text("Result")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Placeholder for result
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: viewModel.selectedScene?.gradient ?? [DesignSystem.Colors.flameOrange, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 300)

                VStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("AI Background Replaced")
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .cardShadow()

            HStack(spacing: DesignSystem.Spacing.s) {
                GRButton(title: "Save", icon: "square.and.arrow.down") {
                    DesignSystem.Haptics.success()
                }
                GRButton(title: "Try Another", icon: "arrow.counterclockwise", style: .secondary) {
                    viewModel.clearResult()
                }
            }
        }
    }
}

// MARK: - Background Replacer ViewModel

@MainActor
final class BackgroundReplacerViewModel: ObservableObject {
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var selectedPhoto: UIImage?
    @Published var selectedScene: BackgroundScene? {
        didSet {
            if selectedScene != nil && selectedPhoto != nil {
                processImage()
            }
        }
    }
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var progress: Double = 0

    func loadPhoto() async {
        guard let item = photosPickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedPhoto = image
        }
    }

    func clearPhoto() {
        selectedPhoto = nil
        photosPickerItem = nil
        selectedScene = nil
        resultImage = nil
    }

    func clearResult() {
        resultImage = nil
        selectedScene = nil
        progress = 0
    }

    private func processImage() {
        isProcessing = true
        progress = 0

        // Simulate AI processing
        Task {
            for i in 0..<10 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                progress = Double(i + 1) / 10.0
            }
            resultImage = selectedPhoto // Placeholder: return same image
            isProcessing = false
            DesignSystem.Haptics.success()
        }
    }
}

#Preview {
    NavigationStack {
        BackgroundReplacerView()
    }
    .environmentObject(SubscriptionManager())
    .preferredColorScheme(.dark)
}
