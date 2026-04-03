import SwiftUI

// MARK: - App Rating Prompt View

struct AppRatingView: View {
    @StateObject private var ratingManager = AppRatingManager.shared
    @State private var selectedRating = 0
    @State private var showThankYou = false
    @State private var feedbackText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                if showThankYou {
                    thankYouView
                } else {
                    ratingContent
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Rating Content

    private var ratingContent: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Emoji based on rating
            Text(emojiForRating)
                .font(.system(size: 72))
                .scaleEffect(selectedRating > 0 ? 1.1 : 1.0)
                .animation(DesignSystem.Animation.cardSpring, value: selectedRating)

            VStack(spacing: DesignSystem.Spacing.s) {
                Text("How's GigaRizz?")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Your feedback helps us build a better app")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Star rating
            HStack(spacing: DesignSystem.Spacing.m) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(DesignSystem.Animation.quickSpring) {
                            selectedRating = star
                        }
                        DesignSystem.Haptics.light()
                    } label: {
                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                star <= selectedRating
                                    ? DesignSystem.Colors.goldAccent
                                    : DesignSystem.Colors.surfaceSecondary
                            )
                            .scaleEffect(star == selectedRating ? 1.2 : 1.0)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.m)

            // Contextual message
            if selectedRating > 0 {
                Text(messageForRating)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Optional feedback for low ratings
            if selectedRating > 0 && selectedRating <= 3 {
                TextField("Tell us how we can improve...", text: $feedbackText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.m)
                    .frame(minHeight: 80)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            // Submit button
            if selectedRating > 0 {
                GRButton(
                    title: selectedRating >= 4 ? "Rate on App Store" : "Send Feedback",
                    icon: selectedRating >= 4 ? "star.fill" : "paperplane.fill"
                ) {
                    submitRating()
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.bottom, DesignSystem.Spacing.xl)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(DesignSystem.Animation.smoothSpring, value: selectedRating)
    }

    // MARK: - Thank You View

    private var thankYouView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            VStack(spacing: DesignSystem.Spacing.l) {
                Text("\u{2764}\u{FE0F}")
                    .font(.system(size: 80))

                Text("Thank You!")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(selectedRating >= 4
                     ? "Your support means the world to us.\nKeep rizzing!"
                     : "We hear you. We're working hard\nto make GigaRizz even better.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            GRButton(title: "Done", icon: "checkmark") {
                dismiss()
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }

    // MARK: - Helpers

    private var emojiForRating: String {
        switch selectedRating {
        case 0: return "\u{1F914}"
        case 1: return "\u{1F614}"
        case 2: return "\u{1F615}"
        case 3: return "\u{1F642}"
        case 4: return "\u{1F60A}"
        case 5: return "\u{1F929}"
        default: return "\u{1F525}"
        }
    }

    private var messageForRating: String {
        switch selectedRating {
        case 1...2: return "We're sorry to hear that.\nTell us what went wrong."
        case 3: return "Thanks! How can we do better?"
        case 4: return "Great! A review would help us a lot."
        case 5: return "You're amazing! Rate us on the App Store?"
        default: return ""
        }
    }

    private func submitRating() {
        DesignSystem.Haptics.success()
        if selectedRating >= 4 {
            ratingManager.promptForReviewAfterDelay(seconds: 0.5)
            ratingManager.markAsRated()
        }
        // Track in analytics
        PostHogManager.shared.trackOnboardingCompleted() // Reuse event for now
        withAnimation(DesignSystem.Animation.smoothSpring) {
            showThankYou = true
        }
    }
}

#Preview {
    AppRatingView()
        .preferredColorScheme(.dark)
}
