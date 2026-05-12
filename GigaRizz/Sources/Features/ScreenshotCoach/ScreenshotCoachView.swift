import PhotosUI
import SwiftUI
import UIKit

// MARK: - ScreenshotCoachView
//
// V2 Sprint 5 — competitive parity with CupidAI / YourMove. Three flows in one
// surface, each starting from a screenshot the user already has:
//
//   1. Profile Opener — paste their profile, get 4 unique openers
//   2. Reply Suggestion — paste a chat, get 4 reply options
//   3. Revive Dead Chat — paste a stalled chat, get 4 re-engagement options
//
// On-device Vision OCR keeps screenshot pixels off the network. Only the
// extracted text is sent to /api/v1/coach.

enum ScreenshotCoachMode: String, CaseIterable, Identifiable {
    case opener
    case reply
    case revive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .opener: return "Profile Opener"
        case .reply: return "Reply Suggestion"
        case .revive: return "Revive Dead Chat"
        }
    }

    var subtitle: String {
        switch self {
        case .opener: return "Paste their profile screenshot, get 4 unique openers."
        case .reply: return "Paste a chat screenshot, get reply options that fit the vibe."
        case .revive: return "Stalled chat? Get 4 angles to re-engage without being weird."
        }
    }

    var icon: String {
        switch self {
        case .opener: return "bubble.left.and.text.bubble.right.fill"
        case .reply: return "arrowshape.turn.up.left.fill"
        case .revive: return "arrow.clockwise.heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .opener: return DesignSystem.Colors.flameOrange
        case .reply: return DesignSystem.Colors.hinge
        case .revive: return .purple
        }
    }
}

struct ScreenshotCoachView: View {
    @StateObject private var viewModel = ScreenshotCoachViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var toast: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                modePicker
                if let image = viewModel.screenshot {
                    screenshotPreview(image)
                    if !viewModel.extractedText.isEmpty {
                        extractedTextCard
                    }
                    actionButton
                } else {
                    importPrompt
                }
                if !viewModel.suggestions.isEmpty {
                    suggestionsSection
                }
                disclaimer
            }
            .padding(DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Screenshot Coach")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .photosPicker(isPresented: $viewModel.showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            Task { await viewModel.loadScreenshot(from: newItem) }
        }
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toast)
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What do you need?")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            HStack(spacing: 8) {
                ForEach(ScreenshotCoachMode.allCases) { mode in
                    Button {
                        viewModel.mode = mode
                        viewModel.suggestions = []
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18))
                            Text(mode.title)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(viewModel.mode == mode ? .white : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.mode == mode ? mode.color : DesignSystem.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                    }
                }
            }
            Text(viewModel.mode.subtitle)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Import prompt

    private var importPrompt: some View {
        Button {
            viewModel.showPicker = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                Text("Import a screenshot")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Pick from Photos. We'll read the text on-device — pixels never leave your phone.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.large)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        }
    }

    // MARK: - Screenshot preview + extracted

    private func screenshotPreview(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Imported")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
                Button("Replace") { viewModel.showPicker = true }
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
            }
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 360)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        }
    }

    private var extractedTextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What we read")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(viewModel.extractedText)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private var actionButton: some View {
        Button {
            Task { await viewModel.requestSuggestions() }
        } label: {
            HStack {
                if viewModel.isBusy {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isBusy ? "Thinking…" : actionLabel)
            }
            .font(DesignSystem.Typography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.mode.color)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
        }
        .disabled(viewModel.isBusy || viewModel.extractedText.isEmpty)
    }

    private var actionLabel: String {
        switch viewModel.mode {
        case .opener: return "Get 4 openers"
        case .reply: return "Suggest 4 replies"
        case .revive: return "Revive this chat"
        }
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggestions")
                .font(DesignSystem.Typography.title)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            ForEach(Array(viewModel.suggestions.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .top) {
                    Image(systemName: viewModel.mode.icon)
                        .foregroundStyle(viewModel.mode.color)
                    Text(line)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = line
                        flashToast("Copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(viewModel.mode.color)
                    }
                }
                .padding(DesignSystem.Spacing.medium)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            }
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.success)
            Text("OCR runs on your device. Only extracted text — never the screenshot — is sent to our coach.")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private func flashToast(_ msg: String) {
        toast = msg
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run { if toast == msg { toast = nil } }
        }
    }
}

// MARK: - View Model

@MainActor
final class ScreenshotCoachViewModel: ObservableObject {
    @Published var mode: ScreenshotCoachMode = .opener
    @Published var screenshot: UIImage?
    @Published var extractedText: String = ""
    @Published var suggestions: [String] = []
    @Published var isBusy = false
    @Published var showPicker = false
    @Published var error: String?

    func loadScreenshot(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            error = "Couldn't read that photo."
            return
        }
        screenshot = image
        suggestions = []
        do {
            extractedText = try await ScreenshotOCRService.extractText(from: image)
        } catch {
            extractedText = ""
            self.error = error.localizedDescription
        }
    }

    func requestSuggestions() async {
        guard !extractedText.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            switch mode {
            case .opener:
                let response = try await GigaRizzAPIClient.shared.generateOpeners(
                    profileContext: extractedText,
                    count: 4
                )
                suggestions = response.openers
            case .reply:
                let response = try await GigaRizzAPIClient.shared.suggestReplies(
                    theirMessage: extractedText,
                    conversationContext: []
                )
                suggestions = response.replies
            case .revive:
                let context = "This chat has gone cold. Suggest 4 ways to revive it without being weird, needy, or formulaic. Vary energy from playful to direct."
                let response = try await GigaRizzAPIClient.shared.suggestReplies(
                    theirMessage: extractedText,
                    conversationContext: [context]
                )
                suggestions = response.replies
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
