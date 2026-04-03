import SwiftUI

// MARK: - Bio Strength Meter

/// Analysis of dating profile bio quality with improvement suggestions.
struct BioStrengthMeter: View {
    let bioStrength: BioStrength
    @State private var showSuggestions: Bool = false

    var body: some View {
        GRCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                // Header
                HStack(spacing: DesignSystem.Spacing.s) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 24))
                        .foregroundStyle(DesignSystem.Colors.hinge)
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Bio Strength Analysis")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("How compelling is your bio?")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                    bioScoreBadge
                }

                // Overall Score Bar
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text("Overall Bio Score")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Text("\(bioStrength.overallScore)/100")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(bioScoreColor)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(DesignSystem.Colors.surfaceSecondary)
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(bioScoreColor)
                                .frame(width: geometry.size.width * CGFloat(bioStrength.overallScore) / 100, height: 12)
                        }
                    }
                    .frame(height: 12)
                }

                // Category breakdown
                VStack(spacing: DesignSystem.Spacing.xs) {
                    categoryRow("Voice Consistency", bioStrength.voiceConsistency, icon: "person.crop.circle.fill")
                    categoryRow("Specificity", bioStrength.specificity, icon: "target")
                    categoryRow("Hook Quality", bioStrength.hookQuality, icon: "fishhook.fill")
                    categoryRow("Length", bioStrength.lengthScore, icon: "textformat.size")
                }

                // Suggestions toggle
                Button {
                    withAnimation(DesignSystem.Animation.quickSpring) {
                        showSuggestions.toggle()
                    }
                    DesignSystem.Haptics.light()
                } label: {
                    HStack {
                        Text(showSuggestions ? "Hide Suggestions" : "Show Improvement Tips")
                            .font(DesignSystem.Typography.smallButton)
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                        Spacer()
                        Image(systemName: showSuggestions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.flameOrange)
                    }
                }

                // Suggestions
                if showSuggestions {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        ForEach(bioStrength.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DesignSystem.Colors.goldAccent)
                                    .padding(.top, 2)
                                Text(suggestion)
                                    .font(DesignSystem.Typography.footnote)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var bioScoreBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.chip)
                .fill(bioScoreColor.opacity(0.2))
                .frame(width: 52, height: 28)
            Text("\(bioStrength.overallScore)")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(bioScoreColor)
        }
    }

    private var bioScoreColor: Color {
        if bioStrength.overallScore >= 80 { return DesignSystem.Colors.success }
        if bioStrength.overallScore >= 60 { return DesignSystem.Colors.flameOrange }
        if bioStrength.overallScore >= 40 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }

    private func categoryRow(_ name: String, _ score: Int, icon: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(categoryColor(score))
            Text(name)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Spacer()
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(categoryColor(score))
                        .frame(width: geometry.size.width * CGFloat(score) / 100, height: 6)
                }
            }
            .frame(width: 60, height: 6)
            Text("\(score)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(categoryColor(score))
                .frame(width: 24, alignment: .trailing)
        }
    }

    private func categoryColor(_ score: Int) -> Color {
        if score >= 80 { return DesignSystem.Colors.success }
        if score >= 60 { return DesignSystem.Colors.flameOrange }
        if score >= 40 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }
}

// MARK: - Preview

#Preview("Bio Strength Meter") {
    VStack(spacing: 20) {
        BioStrengthMeter(bioStrength: BioStrength.demo)
        BioStrengthMeter(bioStrength: BioStrength(
            overallScore: 85,
            voiceConsistency: 90,
            specificity: 88,
            hookQuality: 82,
            lengthScore: 78,
            suggestions: ["Your bio is strong! Keep it fresh with monthly updates."]
        ))
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}
