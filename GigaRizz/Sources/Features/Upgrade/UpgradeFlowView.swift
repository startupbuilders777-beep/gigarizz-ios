import PhotosUI
import SwiftUI

// MARK: - UpgradeFlowView (V2 root)
//
// Audit-first first-run flow. State machine:
//   1. pickGoal → 2. pickPlatforms → 3. pickPhotos → 4. auditing → 5. diagnosis
//
// Composed from V2Components for unified visual language.

struct UpgradeFlowView: View {
    @StateObject private var viewModel = UpgradeFlowViewModel()
    @StateObject private var subscription = SubscriptionManager.shared
    @StateObject private var featureFlags = FeatureFlagManager.shared
    @State private var paywallGateActive = false

    var body: some View {
        NavigationStack {
            content
                .background(DesignSystem.Colors.background.ignoresSafeArea())
                .navigationTitle(stageTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .sheet(isPresented: $paywallGateActive) {
                    PaywallView()
                }
                .onChange(of: viewModel.stage) { _, newStage in
                    if case .diagnosis = newStage {
                        evaluatePaywallGate()
                    }
                }
        }
    }

    private var stageTitle: String {
        switch viewModel.stage {
        case .pickGoal: return "Upgrade"
        case .pickPlatforms: return "Apps"
        case .pickPhotos: return "Your Photos"
        case .auditing: return "Auditing"
        case .diagnosis: return "Diagnosis"
        case .error: return "Try Again"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.stage {
        case .pickGoal:
            UpgradeGoalPicker(viewModel: viewModel)
        case .pickPlatforms:
            UpgradePlatformPicker(viewModel: viewModel)
        case .pickPhotos:
            UpgradePhotoPicker(viewModel: viewModel)
        case .auditing:
            UpgradeAuditingView(viewModel: viewModel)
        case .diagnosis(let audit):
            ProfileDiagnosisView(audit: audit, photoUrls: viewModel.uploadedURLs.map { $0.absoluteString })
        case .error(let message):
            UpgradeErrorView(message: message, onRetry: viewModel.reset)
        }
    }

    private func evaluatePaywallGate() {
        let isSubscribed = subscription.currentTier != .free
        let gate = PaywallGate(
            mode: featureFlags.paywallMode,
            softThreshold: featureFlags.softPaywallAfterUses,
            isSubscribed: isSubscribed,
            auditsUsedSoFar: AuditUsageCounter.shared.count
        )
        switch gate.decide() {
        case .proceed:
            return
        case .showSoft, .showHard:
            paywallGateActive = true
        }
    }
}

// MARK: - Stage

enum UpgradeStage: Equatable {
    case pickGoal
    case pickPlatforms
    case pickPhotos
    case auditing
    case diagnosis(ProfileAuditResult)
    case error(String)
}

// MARK: - View Model

@MainActor
final class UpgradeFlowViewModel: ObservableObject {
    let minimumAuditPhotos = 3

    @Published var stage: UpgradeStage = .pickGoal
    @Published var selectedGoal: UpgradeGoal?
    @Published var selectedPlatforms: Set<DatingPlatform> = [.hinge]
    @Published var pickerItems: [PhotosPickerItem] = []
    @Published var pickedImages: [UIImage] = []
    @Published var uploadProgress: Double = 0
    @Published var uploadedURLs: [URL] = []
    @Published var roastMode: Bool = false

    private let store = ProfileKitStore.shared

    var canStartAudit: Bool { pickedImages.count >= minimumAuditPhotos }

    var remainingAuditPhotoCount: Int {
        max(0, minimumAuditPhotos - pickedImages.count)
    }

    func confirmGoal() {
        guard let goal = selectedGoal else { return }
        if store.current == nil {
            _ = store.startNewKit(userId: "current-user")
        }
        store.setPrimaryGoal(goal)
        // Pre-seed platforms when the goal implies one — saves a tap.
        switch goal {
        case .betterHinge: selectedPlatforms = [.hinge]
        case .betterTinderBumble: selectedPlatforms = [.tinder, .bumble]
        default: break
        }
        stage = .pickPlatforms
    }

    func loadPickedImages() async {
        var images: [UIImage] = []
        for item in pickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        pickedImages = images
    }

    func confirmPlatforms() {
        guard !selectedPlatforms.isEmpty else { return }
        if store.current == nil {
            _ = store.startNewKit(userId: "current-user")
        }
        store.setTargetPlatforms(Array(selectedPlatforms))
        stage = .pickPhotos
    }

    func startAudit() async {
        guard canStartAudit else {
            stage = .error("Add at least \(minimumAuditPhotos) photos to audit your profile.")
            return
        }
        stage = .auditing
        uploadProgress = 0
        uploadedURLs = []

        for (i, image) in pickedImages.enumerated() {
            if let url = await PhotoUploadService.shared.tryUpload(image, purpose: "source") {
                uploadedURLs.append(url)
            }
            uploadProgress = Double(i + 1) / Double(pickedImages.count)
        }

        guard !uploadedURLs.isEmpty else {
            stage = .error("Couldn't upload your photos. Check your connection and try again.")
            return
        }

        store.setCurrentPhotos(uploadedURLs.map { $0.absoluteString })

        do {
            let audit = try await GigaRizzAPIClient.shared.runAudit(
                photoUrls: uploadedURLs.map { $0.absoluteString },
                targetPlatforms: Array(selectedPlatforms),
                roastMode: roastMode
            )
            store.updateAudit(audit)
            AuditUsageCounter.shared.incrementOnAuditCompleted()
            stage = .diagnosis(audit)
        } catch {
            stage = .error("Audit failed: \(error.localizedDescription)")
        }
    }

    func reset() {
        stage = .pickGoal
        selectedGoal = nil
        pickerItems = []
        pickedImages = []
        uploadedURLs = []
        uploadProgress = 0
    }
}

// MARK: - Stage 0 — Goal

private struct UpgradeGoalPicker: View {
    @ObservedObject var viewModel: UpgradeFlowViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                V2HeroCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STEP 1 OF 4")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                            .tracking(0.8)
                        Text("What do you want to improve?")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Pick the outcome that matters most. We'll tune the audit and the kit around it.")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(UpgradeGoal.upgradeFlowCases) { goal in
                        goalRow(goal)
                    }
                }

            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, 112)
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.selectedGoal != nil {
                V2BottomActionBar {
                    V2PrimaryButton(
                        "Continue",
                        systemImage: "arrow.right"
                    ) {
                        viewModel.confirmGoal()
                    }
                }
            }
        }
    }

    private func goalRow(_ goal: UpgradeGoal) -> some View {
        let isSelected = viewModel.selectedGoal == goal
        return Button {
            DesignSystem.Haptics.selection()
            withAnimation(DesignSystem.Animation.quickSpring) {
                viewModel.selectedGoal = goal
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.flameOrange.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: goal.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    Text(goal.subtitle)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                isSelected
                ? DesignSystem.Colors.surface
                : DesignSystem.Colors.surface.opacity(0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .strokeBorder(
                        isSelected ? DesignSystem.Colors.flameOrange.opacity(0.6) : DesignSystem.Colors.divider,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.displayName). \(goal.subtitle)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("upgrade_goal_\(goal.rawValue)")
    }
}

// MARK: - Stage 1 — Platforms

private struct UpgradePlatformPicker: View {
    @ObservedObject var viewModel: UpgradeFlowViewModel
    private let platforms: [DatingPlatform] = [.hinge, .tinder, .bumble, .raya, .other]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                V2HeroCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STEP 2 OF 4")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                            .tracking(0.8)
                        Text("Where are you trying to match?")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("We'll tune your audit and Profile Kit for the apps you actually use.")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(platforms) { platform in
                        platformRow(platform)
                    }
                }

                V2TrustBadge()

            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, 112)
        }
        .safeAreaInset(edge: .bottom) {
            V2BottomActionBar {
                V2PrimaryButton(
                    "Continue",
                    systemImage: "arrow.right",
                    isEnabled: !viewModel.selectedPlatforms.isEmpty
                ) {
                    viewModel.confirmPlatforms()
                }
            }
        }
    }

    private func platformRow(_ platform: DatingPlatform) -> some View {
        let isSelected = viewModel.selectedPlatforms.contains(platform)
        return Button {
            DesignSystem.Haptics.selection()
            withAnimation(DesignSystem.Animation.quickSpring) {
                if isSelected {
                    viewModel.selectedPlatforms.remove(platform)
                } else {
                    viewModel.selectedPlatforms.insert(platform)
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(platform.color.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: platform.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(platform.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(platform.rawValue)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                isSelected
                ? DesignSystem.Colors.surface.opacity(0.95)
                : DesignSystem.Colors.surface.opacity(0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .strokeBorder(
                        isSelected ? DesignSystem.Colors.flameOrange.opacity(0.6) : DesignSystem.Colors.divider,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(platform.rawValue)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("upgrade_platform_\(platform.rawValue.lowercased())")
    }
}

// MARK: - Stage 2 — Photos

private struct UpgradePhotoPicker: View {
    @ObservedObject var viewModel: UpgradeFlowViewModel

    var body: some View {
        let photoPickerTitle = viewModel.pickedImages.isEmpty
            ? "Add photos"
            : "Edit selection (\(viewModel.pickedImages.count))"
        let photoPickerAccessibilityLabel = viewModel.pickedImages.isEmpty
            ? "Add photos"
            : "Edit photo selection"
        let photoPickerAccessibilityValue = "\(viewModel.pickedImages.count) selected"

        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                V2HeroCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STEP 3 OF 4")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                            .tracking(0.8)
                        Text("Upload your current photos")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("4–8 works best. Mix face shots, full body, and any candids.")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                PhotosPicker(
                    selection: $viewModel.pickerItems,
                    maxSelectionCount: 8,
                    matching: .images
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(photoPickerTitle)
                            .font(DesignSystem.Typography.button)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(DesignSystem.Colors.hinge)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }
                .accessibilityLabel(photoPickerAccessibilityLabel)
                .accessibilityValue(photoPickerAccessibilityValue)
                .accessibilityIdentifier("upgrade_add_photos")
                .onChange(of: viewModel.pickerItems) { _, _ in
                    Task { await viewModel.loadPickedImages() }
                }

                if !viewModel.pickedImages.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(Array(viewModel.pickedImages.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 110)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                                )
                        }
                    }

                    // V3 Sprint 8 — Roast Mode toggle. Direct counter to
                    // Roast.dating: same audit engine, brutally honest voice.
                    Toggle(isOn: $viewModel.roastMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Roast Mode")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("Audit voice swap — brutally honest mentor.")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .tint(DesignSystem.Colors.flameOrange)
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))

                    V2TrustBadge()

                    if !viewModel.canStartAudit {
                        V2Card {
                            Label(
                                "Add \(viewModel.remainingAuditPhotoCount) more photo\(viewModel.remainingAuditPhotoCount == 1 ? "" : "s") for a useful audit",
                                systemImage: "info.circle.fill"
                            )
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }

                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, 112)
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.pickedImages.isEmpty {
                V2BottomActionBar {
                    V2PrimaryButton(
                        "Audit my profile",
                        systemImage: "wand.and.stars",
                        isEnabled: viewModel.canStartAudit
                    ) {
                        Task { await viewModel.startAudit() }
                    }
                }
            }
        }
    }
}

// MARK: - Stage 3 — Auditing

private struct UpgradeAuditingView: View {
    @ObservedObject var viewModel: UpgradeFlowViewModel

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.divider, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0.05, viewModel.uploadProgress))
                    .stroke(
                        AngularGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.hinge,
                                     DesignSystem.Colors.flameOrange],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.4), value: viewModel.uploadProgress)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
            .frame(width: 132, height: 132)

            VStack(spacing: 6) {
                Text(viewModel.uploadProgress < 1 ? "Uploading your photos…" : "Reading the room…")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Reviewing your set the way a senior dating photographer would.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
            V2TrustBadge()
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.large)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error stage

private struct UpgradeErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            V2PrimaryButton("Start over", systemImage: "arrow.counterclockwise", action: onRetry)
                .padding(.horizontal, DesignSystem.Spacing.medium)
            Spacer()
        }
    }
}

#Preview {
    UpgradeFlowView()
        .preferredColorScheme(.dark)
}
