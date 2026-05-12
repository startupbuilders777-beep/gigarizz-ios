import SwiftUI
import UIKit

// MARK: - ProfileKitView (V2 hero artifact)
//
// The user's exportable dating profile, assembled. Photo strips toggle by
// platform via a pill selector at the top. Bio + prompts + openers all live
// in one scroll view above a sticky export action bar.

struct ProfileKitView: View {
    @StateObject private var viewModel: ProfileKitViewModel
    @State private var showShareSheet = false
    @State private var toast: String?
    @State private var selectedPlatform: DatingPlatform

    init(kit: ProfileKit) {
        _viewModel = StateObject(wrappedValue: ProfileKitViewModel(kit: kit))
        _selectedPlatform = State(initialValue: kit.targetPlatforms.first ?? .hinge)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    headerHero
                    if !viewModel.platformOrders.isEmpty {
                        platformSelector
                        photoStripSection
                    }
                    bioSection
                    promptsSection
                    openersSection
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.top, DesignSystem.Spacing.medium)
                .padding(.bottom, 120) // leave room for sticky bar
            }
            stickyExportBar
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Your Profile Kit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .overlay(alignment: .top) {
            if let toast {
                V2ToastBanner(toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let kit = viewModel.kit {
                ShareSheet(items: ProfileKitExporter.shareItems(kit))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toast)
    }

    // MARK: - Header

    private var headerHero: some View {
        V2HeroCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(DesignSystem.Colors.success)
                    Text("READY TO UPLOAD")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(DesignSystem.Colors.success)
                        .tracking(0.8)
                }
                Text(headerTitle)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                if let kit = viewModel.kit {
                    Text(headerSubtitle(for: kit))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }

    private var headerTitle: String {
        guard let count = viewModel.kit?.targetPlatforms.count else { return "Your Profile Kit" }
        return count == 1 ? "Your Hinge-ready kit" : "Your \(count)-app profile kit"
    }

    private func headerSubtitle(for kit: ProfileKit) -> String {
        let total = kit.totalPhotos
        let suffix = total == 1 ? "photo" : "photos"
        return "\(total) \(suffix) · \(kit.prompts.count) prompts · \(kit.openers.count) openers"
    }

    // MARK: - Platform selector

    private var platformSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.platformOrders, id: \.platform.id) { order in
                    V2PlatformPill(
                        platform: order.platform,
                        isSelected: order.platform == selectedPlatform
                    ) {
                        withAnimation(DesignSystem.Animation.smoothSpring) {
                            selectedPlatform = order.platform
                        }
                    }
                }
            }
        }
    }

    private var currentOrder: PlatformPhotoOrder? {
        viewModel.platformOrders.first { $0.platform == selectedPlatform }
    }

    // MARK: - Photo strip (per platform)

    private var photoStripSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader(
                "Photo order",
                subtitle: currentOrder.map { "\($0.photos.count)-photo \($0.platform.rawValue) layout" }
            )
            if let order = currentOrder, !order.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(order.photos.enumerated()), id: \.element.id) { idx, photo in
                            photoTile(index: idx, photo: photo)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                V2EmptyState(
                    icon: "photo.on.rectangle",
                    title: "No photos yet",
                    subtitle: "Run an audit to fill the slot order."
                )
            }
        }
    }

    private func photoTile(index: Int, photo: OrderedPhoto) -> some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: photo.url)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.surface)
            }
            .frame(width: 116, height: 174)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("\(index + 1)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(.black.opacity(0.65))
                .clipShape(Circle())
                .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
        )
    }

    // MARK: - Bio

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader(
                "Bio",
                trailing: AnyView(
                    V2TextButton(
                        viewModel.isBusyBio ? "Writing…" : "Regenerate",
                        systemImage: viewModel.isBusyBio ? nil : "arrow.clockwise"
                    ) {
                        Task { await viewModel.regenerateBio() }
                    }
                    .disabled(viewModel.isBusyBio)
                )
            )
            V2Card(padding: DesignSystem.Spacing.large) {
                if let bio = viewModel.kit?.bio, !bio.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\u{201C}")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundStyle(DesignSystem.Colors.flameOrange.opacity(0.6))
                        Text(bio)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        HStack {
                            Spacer()
                            V2TextButton("Copy bio", systemImage: "doc.on.doc") {
                                ProfileKitExporter.copy(bio)
                                flashToast("Bio copied")
                            }
                        }
                    }
                } else {
                    Button {
                        Task { await viewModel.regenerateBio() }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(viewModel.isBusyBio ? "Generating…" : "Generate bio")
                        }
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    // MARK: - Prompts

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader(
                "Hinge Prompts",
                trailing: AnyView(
                    V2TextButton(
                        viewModel.isBusyPrompts ? "Writing…" : "Regenerate",
                        systemImage: viewModel.isBusyPrompts ? nil : "arrow.clockwise"
                    ) {
                        Task { await viewModel.regeneratePrompts() }
                    }
                    .disabled(viewModel.isBusyPrompts)
                )
            )
            if let prompts = viewModel.kit?.prompts, !prompts.isEmpty {
                VStack(spacing: 8) {
                    ForEach(prompts) { prompt in
                        promptRow(prompt)
                    }
                }
            } else {
                V2Card {
                    Button {
                        Task { await viewModel.regeneratePrompts() }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(viewModel.isBusyPrompts ? "Generating…" : "Generate prompts")
                        }
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private func promptRow(_ item: PromptKitItem) -> some View {
        V2Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.label.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                    .tracking(0.6)
                Text(item.content)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                HStack {
                    Spacer()
                    V2TextButton("Copy", systemImage: "doc.on.doc") {
                        ProfileKitExporter.copy("\(item.label)\n\(item.content)")
                        flashToast("Prompt copied")
                    }
                }
            }
        }
    }

    // MARK: - Openers

    private var openersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            V2SectionHeader(
                "First Messages",
                trailing: AnyView(
                    V2TextButton(
                        viewModel.isBusyOpeners ? "Writing…" : "Regenerate",
                        systemImage: viewModel.isBusyOpeners ? nil : "arrow.clockwise"
                    ) {
                        Task { await viewModel.regenerateOpeners() }
                    }
                    .disabled(viewModel.isBusyOpeners)
                )
            )
            if let openers = viewModel.kit?.openers, !openers.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(openers.enumerated()), id: \.offset) { _, line in
                        openerRow(line)
                    }
                }
            } else {
                V2Card {
                    Button {
                        Task { await viewModel.regenerateOpeners() }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(viewModel.isBusyOpeners ? "Generating…" : "Generate first messages")
                        }
                        .font(DesignSystem.Typography.button)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private func openerRow(_ line: String) -> some View {
        V2Card {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                Text(line)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer(minLength: 0)
                Button {
                    ProfileKitExporter.copy(line)
                    flashToast("Opener copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
        }
    }

    // MARK: - Sticky export bar

    private var stickyExportBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                V2SecondaryButton("Copy all", systemImage: "doc.on.doc") {
                    if let kit = viewModel.kit {
                        ProfileKitExporter.copyKitText(kit)
                        flashToast("Kit text copied")
                    }
                }
                V2SecondaryButton(
                    viewModel.isBusySave ? "Saving…" : "Save photos",
                    systemImage: "square.and.arrow.down"
                ) {
                    Task { await savePhotos() }
                }
            }
            V2PrimaryButton("Share kit", systemImage: "square.and.arrow.up") {
                showShareSheet = true
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(
            LinearGradient(
                colors: [DesignSystem.Colors.background.opacity(0), DesignSystem.Colors.background],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Helpers

    private func savePhotos() async {
        viewModel.isBusySave = true
        defer { viewModel.isBusySave = false }
        let urls = (viewModel.kit?.currentPhotoUrls ?? []) + (viewModel.kit?.generatedPhotoUrls ?? [])
        let resolved = urls.compactMap(URL.init(string:))
        let saved = await ProfileKitExporter.savePhotos(remoteURLs: resolved)
        flashToast(saved > 0 ? "Saved \(saved) photo\(saved == 1 ? "" : "s")" : "Couldn't save photos")
    }

    private func flashToast(_ msg: String) {
        toast = msg
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await MainActor.run { if toast == msg { toast = nil } }
        }
    }
}

// MARK: - View Model

@MainActor
final class ProfileKitViewModel: ObservableObject {
    @Published var kit: ProfileKit?
    @Published var platformOrders: [PlatformPhotoOrder] = []
    @Published var isBusyBio = false
    @Published var isBusyPrompts = false
    @Published var isBusyOpeners = false
    @Published var isBusySave = false

    private let store = ProfileKitStore.shared

    init(kit: ProfileKit) {
        self.kit = kit
        recomputeOrders()
    }

    private func recomputeOrders() {
        guard let kit else { return }
        platformOrders = kit.targetPlatforms.map { platform in
            ProfileKitOrderer.order(
                for: platform,
                audit: kit.audit,
                currentPhotoUrls: kit.currentPhotoUrls,
                generatedPhotoUrls: kit.generatedPhotoUrls
            )
        }
    }

    // MARK: - Coach calls (write back into kit)

    func regenerateBio() async {
        guard var current = kit else { return }
        isBusyBio = true
        defer { isBusyBio = false }
        let platform = current.targetPlatforms.first?.rawValue.lowercased() ?? "hinge"
        do {
            let response = try await GigaRizzAPIClient.shared.generateBio(
                interests: ["dating", "lifestyle", "photography"],
                tone: "witty",
                platform: platform
            )
            current.bio = response.bio
            kit = current
            store.save(current)
        } catch {
            // ignored — UI keeps prior value
        }
    }

    func regeneratePrompts() async {
        guard var current = kit else { return }
        isBusyPrompts = true
        defer { isBusyPrompts = false }
        let platform = current.targetPlatforms.first ?? .hinge
        do {
            let response = try await GigaRizzAPIClient.shared.generatePrompts()
            current.prompts = response.prompts.map {
                PromptKitItem(
                    platform: platform.rawValue.lowercased(),
                    label: $0.prompt,
                    content: $0.answer
                )
            }
            kit = current
            store.save(current)
        } catch {}
    }

    func regenerateOpeners() async {
        guard var current = kit else { return }
        isBusyOpeners = true
        defer { isBusyOpeners = false }
        let context = current.bio ?? "Dating profile, looking to make a great first impression."
        do {
            let response = try await GigaRizzAPIClient.shared.generateOpeners(
                profileContext: context,
                count: 4
            )
            current.openers = response.openers
            kit = current
            store.save(current)
        } catch {}
    }
}
