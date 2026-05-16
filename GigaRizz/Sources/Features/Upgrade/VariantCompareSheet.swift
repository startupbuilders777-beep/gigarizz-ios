import SwiftUI
import UIKit

// MARK: - VariantCompareSheet
//
// Side-by-side grid view of every generated variant in the current Photo
// Brief Studio session. Each tile shows the IdentityMatch chip + drift count
// so users can scan the full set in a single glance and pick the strongest
// candidate without flipping through detail sheets.

struct VariantCompareSheet: View {
    let results: [BriefResult]
    let onSelect: (BriefResult) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    header
                    grid
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Compare variants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(results.count) variants")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text("Sorted by Identity Match. Tap any tile to open the receipt + share flow.")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(sortedResults) { result in
                Button {
                    onSelect(result)
                    dismiss()
                } label: {
                    tile(result)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sortedResults: [BriefResult] {
        results.sorted { lhs, rhs in
            let lhsScore = lhs.matchResult?.similarity ?? 0
            let rhsScore = rhs.matchResult?.similarity ?? 0
            if lhsScore != rhsScore { return lhsScore > rhsScore }
            return lhs.driftSignals.count < rhs.driftSignals.count
        }
    }

    private func tile(_ result: BriefResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                Image(uiImage: result.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                if let band = result.matchResult?.band {
                    Label(band.shortLabel, systemImage: band.iconName)
                        .font(DesignSystem.Typography.caption)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(color(for: band))
                        .padding(DesignSystem.Spacing.small)
                }
            }
            HStack(spacing: 6) {
                if let result = result.matchResult {
                    Text("\(Int(result.similarity * 100))% Identity")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
                Spacer()
                if !result.driftSignals.isEmpty {
                    Text("\(result.driftSignals.count) drift")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.warning)
                }
            }
        }
    }

    private func color(for band: IdentityMatchService.Band) -> Color {
        switch band {
        case .excellent, .acceptable: return DesignSystem.Colors.success
        case .borderline: return DesignSystem.Colors.warning
        case .rejected: return DesignSystem.Colors.error
        }
    }
}
