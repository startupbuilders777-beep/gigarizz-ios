import SwiftUI

// MARK: - ScenePickerSheet
//
// Visual scene catalog organized by category. Surfaced from
// PhotoBriefStudioView as the "what kind of photo do you want" picker. Each
// scene maps to a backend `scene_*` GenerationStyle and seeds the brief field.

struct ScenePickerSheet: View {
    let selected: PhotoScene?
    let onPick: (PhotoScene) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                header
                ForEach(PhotoScene.grouped(), id: \.0) { (category, scenes) in
                    section(category: category, scenes: scenes)
                }
                Color.clear.frame(height: 32)
            }
            .padding(DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Pick a scene")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Built to beat ReGen")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(DesignSystem.Colors.flameOrange)
                .tracking(0.8)
            Text("Curated dating environments")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text("Pick a starting scene. We'll seed the brief — you can rewrite it.")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private func section(category: PhotoScene.Category, scenes: [PhotoScene]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .foregroundStyle(DesignSystem.Colors.flameOrange)
                Text(category.displayName)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(category.subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(scenes) { scene in
                    Button {
                        onPick(scene)
                    } label: {
                        sceneTile(scene)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sceneTile(_ scene: PhotoScene) -> some View {
        let isActive = selected?.id == scene.id
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: scene.iconName)
                    .foregroundStyle(isActive ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textPrimary)
                Text(scene.displayName)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
            }
            Text(scene.blurb)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? DesignSystem.Colors.flameOrange.opacity(0.10) : DesignSystem.Colors.surfaceSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isActive ? DesignSystem.Colors.flameOrange : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}
