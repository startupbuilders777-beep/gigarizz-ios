import SwiftUI

// MARK: - Match Inbox View

/// Main inbox view showing all matches sorted by conversation activity.
/// Sorted: unread first → new matches → active conversations → archived.
struct MatchInboxView: View {
    @StateObject private var viewModel = MatchInboxViewModel()
    @State private var searchText = ""
    @State private var selectedMatch: Match?
    @Namespace private var namespace

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredMatches(searchText: searchText).isEmpty {
                if searchText.isEmpty {
                    emptyInboxView
                } else {
                    noResultsView
                }
            } else {
                matchListView
            }
        }
        .navigationTitle("Match Inbox")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search matches...")
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(item: $selectedMatch) { match in
            InboxChatPreview(match: match, namespace: namespace)
                .environmentObject(viewModel)
        }
    }

    // MARK: - Match List

    private var matchListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredMatches(searchText: searchText)) { match in
                    MatchConversationCell(match: match, namespace: namespace) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedMatch = match
                            DesignSystem.Haptics.light()
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.archiveMatch(match)
                            }
                        } label: {
                            Label("Archive", systemImage: "archivebox.fill")
                        }
                        .tint(DesignSystem.Colors.textSecondary)

                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.unmatch(match)
                            }
                        } label: {
                            Label("Unmatch", systemImage: "person.badge.minus")
                        }
                        .tint(DesignSystem.Colors.error)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    Divider()
                        .background(DesignSystem.Colors.divider)
                        .padding(.leading, 76)
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    // MARK: - Empty State

    private var emptyInboxView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Spacer()

            ZStack {
                Circle().fill(DesignSystem.Colors.flameOrange.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "heart.text.square")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .modifier(ScaleSpringAnimation())

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Matches Yet")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Your conversations will appear here.\nGenerate better photos to get more matches!")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            GRButton(
                title: "Generate Better Photos",
                icon: "wand.and.stars"
            ) {
                DesignSystem.Haptics.medium()
                // Navigate to generate view — handled by tab switching
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .frame(width: 280)

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }

    private var noResultsView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("No matches found")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Try a different search term")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: DesignSystem.Spacing.m) {
                    ShimmerView().frame(width: 48, height: 48).clipShape(Circle())
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        ShimmerView().frame(width: 120, height: 16)
                        ShimmerView().frame(width: 180, height: 12)
                    }
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.vertical, DesignSystem.Spacing.s)
            }
        }
    }
}

// MARK: - Match Conversation Cell

struct MatchConversationCell: View {
    let match: Match
    let namespace: Namespace.ID
    let onTap: () -> Void

    private var inboxBadge: InboxBadge { InboxBadge.from(match: match) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.m) {
                profilePhoto
                contentStack
                Spacer()
                rightStack
            }
            .frame(height: 72)
            .padding(.horizontal, DesignSystem.Spacing.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(CellPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to open conversation")
    }

    private var profilePhoto: some View {
        ZStack(alignment: .bottomTrailing) {
            // Photo or initial avatar
            if let photoName = match.photoName {
                Image(systemName: photoName)
                    .font(.system(size: 20))
                    .foregroundStyle(match.platform.color)
                    .frame(width: 48, height: 48)
                    .background(match.platform.color.opacity(0.15))
                    .clipShape(Circle())
            } else {
                Text(String(match.name.prefix(1)).uppercased())
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(match.platform.color)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [match.platform.color.opacity(0.3), match.platform.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
            }

            // Unread dot
            if match.hasUnread {
                Circle()
                    .fill(DesignSystem.Colors.flameOrange)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle()
                            .stroke(DesignSystem.Colors.deepNight, lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text(match.name)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(match.hasUnread ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textPrimary.opacity(0.85))
                    .lineLimit(1)

                Image(systemName: match.platform.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(match.platform.color)
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text(lastMessageText)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(match.hasUnread ? DesignSystem.Colors.textPrimary.opacity(0.7) : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var lastMessageText: String {
        if let msg = match.lastMessage, !msg.isEmpty {
            return msg
        }
        if match.status == .new && match.lastMessage == nil {
            return "👋 Say hello!"
        }
        return "No messages yet"
    }

    private var rightStack: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.micro) {
            if let date = match.lastMessageDate {
                Text(timeAgo(date))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(match.hasUnread ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textSecondary)
            } else {
                Text(timeAgo(match.matchedDate))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            InboxBadgeView(badge: inboxBadge)
        }
    }

    private var accessibilityLabel: String {
        let unreadText = match.hasUnread ? "Unread. " : ""
        let badgeText = inboxBadge.label
        let messageText = match.lastMessage ?? "No messages"
        let timeText = match.lastMessageDate.map { timeAgo($0) } ?? timeAgo(match.matchedDate)
        return "\(match.name). \(unreadText)\(badgeText). \(messageText). \(timeText)"
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        if days < 7 { return "\(days)d" }
        let weeks = days / 7
        if weeks < 4 { return "\(weeks)w" }
        return "\(days / 30)mo"
    }
}

// MARK: - Inbox Badge View

struct InboxBadgeView: View {
    let badge: InboxBadge

    var body: some View {
        HStack(spacing: 3) {
            if badge == .unread {
                Circle()
                    .fill(badge.color)
                    .frame(width: 6, height: 6)
            } else {
                Image(systemName: badge.icon)
                    .font(.system(size: 9))
                    .foregroundStyle(badge.color)
            }
            Text(badge.label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(badge.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(badge.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Inbox Chat Preview

/// Simplified chat preview for inbox conversations.
struct InboxChatPreview: View {
    let match: Match
    let namespace: Namespace.ID
    @EnvironmentObject var viewModel: MatchInboxViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Match header
                    matchHeader

                    // Messages
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.s) {
                            ForEach(viewModel.messages(for: match.id)) { message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding(DesignSystem.Spacing.m)
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(match.name)
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(match.platform.rawValue)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .toolbarBackground(DesignSystem.Colors.surface, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.markAsRead(match)
        }
    }

    private var matchHeader: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Text(String(match.name.prefix(1)).uppercased())
                .font(DesignSystem.Typography.title)
                .foregroundStyle(match.platform.color)
                .frame(width: 40, height: 40)
                .background(match.platform.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(match.name)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                HStack(spacing: DesignSystem.Spacing.micro) {
                    Image(systemName: match.platform.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(match.platform.color)
                    Text(match.platform.rawValue)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            Spacer()

            InboxBadgeView(badge: InboxBadge.from(match: match))
        }
        .padding(DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.surface)
    }

    private var inputBar: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            TextField("Message...", text: $messageText)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.vertical, DesignSystem.Spacing.s)
                .background(DesignSystem.Colors.surfaceSecondary)
                .clipShape(Capsule())
                .focused($isInputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        messageText.isEmpty
                        ? DesignSystem.Colors.textSecondary
                        : DesignSystem.Colors.flameOrange
                    )
            }
            .disabled(messageText.isEmpty)
            .sensoryFeedback(.impact(weight: .medium), trigger: messageText.isEmpty == false)
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.s)
        .background(DesignSystem.Colors.surface)
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        DesignSystem.Haptics.medium()
        viewModel.sendMessage(messageText, to: match)
        messageText = ""
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ConversationMessage

    var body: some View {
        HStack {
            if message.isFromMe { Spacer() }

            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: DesignSystem.Spacing.micro) {
                Text(message.text)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(message.isFromMe ? .white : DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(
                        message.isFromMe
                        ? DesignSystem.Colors.flameOrange
                        : DesignSystem.Colors.surfaceSecondary
                    )
                    .clipShape(MessageBubbleShape(isFromMe: message.isFromMe))

                Text(message.formattedTime)
                    .font(.system(size: 10))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            if !message.isFromMe { Spacer() }
        }
    }
}

struct MessageBubbleShape: Shape {
    let isFromMe: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        var path = Path()

        if isFromMe {
            path.addRoundedRect(
                in: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: radius,
                    bottomLeading: radius,
                    bottomTrailing: 4,
                    topTrailing: radius
                )
            )
        } else {
            path.addRoundedRect(
                in: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: 4,
                    bottomLeading: radius,
                    bottomTrailing: radius,
                    topTrailing: radius
                )
            )
        }
        return path
    }
}

// MARK: - Supporting Types

struct ConversationMessage: Identifiable, Equatable {
    let id: String
    let text: String
    let isFromMe: Bool
    let timestamp: Date

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Cell Press Style

struct CellPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .background(configuration.isPressed ? DesignSystem.Colors.surfaceSecondary.opacity(0.5) : .clear)
    }
}

// MARK: - Scale Spring Animation

struct ScaleSpringAnimation: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                    isAnimating = true
                }
            }
    }
}

#Preview("Match Inbox") {
    NavigationStack {
        MatchInboxView()
            .environmentObject(MatchInboxViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("Inbox Chat Preview") {
    InboxChatPreview(match: Match.demoMatches[0], namespace: Namespace().wrappedValue)
        .environmentObject(MatchInboxViewModel())
}
