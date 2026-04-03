import SwiftUI

// MARK: - Chat Suggestion Bar

/// Horizontal scrollable bar with reply suggestions above the keyboard.
struct ChatSuggestionBar: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showSuggestionBar && !viewModel.suggestions.isEmpty {
                suggestionContent
            } else if viewModel.isLoadingSuggestions {
                loadingIndicator
            }
        }
        .frame(height: viewModel.showSuggestionBar || viewModel.isLoadingSuggestions ? 60 : 0)
        .background(DesignSystem.Colors.surface)
    }

    private var suggestionContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            headerRow
            suggestionChips
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private var headerRow: some View {
        HStack {
            Label("Reply Suggestions", systemImage: "sparkles")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            if viewModel.canGenerateSuggestions {
                Button {
                    Task { await viewModel.refreshSuggestions() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            } else {
                Text("\(viewModel.dailySuggestionCount)/\(viewModel.maxFreeSuggestionsPerDay)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.warning)
            }
        }
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.suggestions) { suggestion in
                    SuggestionChip(suggestion: suggestion) {
                        viewModel.applySuggestion(suggestion)
                    }
                }
            }
        }
    }

    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(DesignSystem.Colors.flameOrange)
                .scaleEffect(0.8)
            Text("Generating suggestions...")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
        }
        .frame(height: 44)
    }
}

// MARK: - Suggestion Chip

/// Individual pill-shaped suggestion button.
struct SuggestionChip: View {
    let suggestion: ChatSuggestion
    let onTap: () -> Void

    @State private var isPressed: Bool = false
    @State private var showFeedback: Bool = false

    var body: some View {
        Button {
            onTap()
            withAnimation(DesignSystem.Animation.quickSpring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: suggestion.type.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.flameOrange.opacity(0.8))

                Text(suggestion.text)
                    .font(DesignSystem.Typography.smallButton)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.chip)
                    .fill(isPressed ? DesignSystem.Colors.flameOrange : chipBackgroundColor)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.quickSpring, value: isPressed)
        }
        .contextMenu {
            Button {
                showFeedback = true
            } label: {
                Label("Feedback", systemImage: "hand.thumbsup")
            }
        }
        .sheet(isPresented: $showFeedback) {
            SuggestionFeedbackSheet(suggestion: suggestion)
        }
    }

    private var chipBackgroundColor: Color {
        switch suggestion.type {
        case .continueTopic:
            Color(hex: "2A2A3E")
        case .flirty:
            DesignSystem.Colors.flameOrange.opacity(0.15)
        case .changeSubject:
            DesignSystem.Colors.surfaceSecondary
        }
    }
}

// MARK: - Suggestion Feedback Sheet

/// Sheet for collecting user feedback on suggestions.
struct SuggestionFeedbackSheet: View {
    let suggestion: ChatSuggestion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.large) {
                suggestionPreview
                feedbackButtons
            }
            .padding()
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var suggestionPreview: some View {
        GRCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Label(suggestion.type.rawValue, systemImage: suggestion.type.icon)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)

                Text(suggestion.text)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
    }

    private var feedbackButtons: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Text("Was this suggestion helpful?")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.large) {
                feedbackButton(icon: "hand.thumbsup.fill", label: "Great", color: DesignSystem.Colors.success)
                feedbackButton(icon: "hand.thumbsdown.fill", label: "Not helpful", color: DesignSystem.Colors.error)
            }
        }
    }

    private func feedbackButton(icon: String, label: String, color: Color) -> some View {
        Button {
            DesignSystem.Haptics.light()
            dismiss()
        } label: {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(width: 100, height: 80)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }
}

// MARK: - Previews

#Preview("Chat Suggestion Bar") {
    VStack {
        ChatSuggestionBar(viewModel: ChatViewModel(match: Match.demoMatches[0]))
        Spacer()
    }
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("Suggestion Chip") {
    HStack(spacing: 12) {
        SuggestionChip(
            suggestion: ChatSuggestion(text: "That sounds amazing! Tell me more", type: .continueTopic),
            onTap: {}
        )
        SuggestionChip(
            suggestion: ChatSuggestion(text: "You're making me jealous 😄", type: .flirty),
            onTap: {}
        )
        SuggestionChip(
            suggestion: ChatSuggestion(text: "By the way, what's your favorite...", type: .changeSubject),
            onTap: {}
        )
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}
