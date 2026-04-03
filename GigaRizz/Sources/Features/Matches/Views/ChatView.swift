import SwiftUI

// MARK: - Chat View

/// Full conversation view with message bubbles and suggestion bar.
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    let match: Match

    init(match: Match, messages: [ChatMessage] = []) {
        self.match = match
        self._viewModel = StateObject(wrappedValue: ChatViewModel(match: match, messages: messages))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    messageList
                    suggestionBar
                    inputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    chatHeader
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.markMessagesAsRead()
        }
        .preferredColorScheme(.dark)
    }

    private var chatHeader: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            ZStack {
                Circle()
                    .fill(match.platform.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                Text(String(match.name.prefix(1)))
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(match.platform.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(match.name)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: match.platform.icon)
                        .font(.system(size: 10))
                    Text(match.platform.rawValue)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(match.platform.color)
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message, matchName: match.name)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.large)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(DesignSystem.Animation.easeOut) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var suggestionBar: some View {
        ChatSuggestionBar(viewModel: viewModel)
    }

    private var inputBar: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            TextField("Type a message...", text: $viewModel.inputText, axis: .vertical)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .focused($isInputFocused)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .lineLimit(1...5)

            sendButton
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.surface)
    }

    private var sendButton: some View {
        Button {
            Task { await viewModel.sendMessage() }
        } label: {
            Image(systemName: viewModel.inputText.isEmpty ? "circle" : "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    viewModel.inputText.isEmpty
                        ? DesignSystem.Colors.textSecondary
                        : DesignSystem.Colors.flameOrange
                )
        }
        .disabled(viewModel.inputText.isEmpty)
        .animation(DesignSystem.Animation.quickSpring, value: viewModel.inputText.isEmpty)
    }
}

// MARK: - Message Bubble

/// Individual message bubble in the conversation.
struct MessageBubble: View {
    let message: ChatMessage
    let matchName: String

    var body: some View {
        HStack(alignment: .bottom, spacing: DesignSystem.Spacing.xs) {
            if !message.isFromUser {
                matchAvatar
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                bubbleContent
                timestampLabel
            }

            if message.isFromUser {
                Spacer(minLength: 40)
            }
        }
    }

    private var matchAvatar: some View {
        Spacer(minLength: 40)
    }

    private var bubbleContent: some View {
        Text(message.content)
            .font(DesignSystem.Typography.body)
            .foregroundStyle(message.isFromUser ? .white : DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(message.isFromUser ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.surface)
            )
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
    }

    private var timestampLabel: some View {
        HStack(spacing: 4) {
            if !message.isRead && !message.isFromUser {
                Circle()
                    .fill(DesignSystem.Colors.flameOrange)
                    .frame(width: 6, height: 6)
            }
            Text(message.timeAgo)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Previews

#Preview("Chat View") {
    ChatView(match: Match.demoMatches[0])
}

#Preview("Message Bubbles") {
    VStack(spacing: 16) {
        MessageBubble(
            message: ChatMessage(content: "Hey! How's your day going?", isFromUser: false),
            matchName: "Sarah"
        )
        MessageBubble(
            message: ChatMessage(content: "Pretty good! Just got back from a hike", isFromUser: true),
            matchName: "Sarah"
        )
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}
