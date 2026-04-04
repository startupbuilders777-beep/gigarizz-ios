import SwiftUI

// MARK: - Style Preset Manager

/// Tracks user's most-used style presets and surfaces them as defaults.
/// Persists usage counts in UserDefaults for cross-session persistence.
@MainActor
final class StylePresetManager: ObservableObject {
    // MARK: - Singleton

    static let shared = StylePresetManager()

    // MARK: - Published Properties

    /// The most-used preset, surfaced as default for next generation.
    @Published private(set) var mostUsedPreset: StylePreset?

    /// Usage counts for all presets (keyed by preset id).
    @Published private(set) var usageCounts: [String: Int] = [:]

    /// All presets with their usage statistics.
    @Published private(set) var presetStats: [(preset: StylePreset, count: Int)] = []

    // MARK: - AppStorage Keys

    private let usageCountsKey = "stylePresetUsageCounts"
    private let mostUsedKey = "mostUsedStylePresetId"

    // MARK: - UserDefaults

    @AppStorage("stylePresetUsageCounts") private var storedUsageCountsData: String = ""
    @AppStorage("mostUsedStylePresetId") private var storedMostUsedId: String = ""

    // MARK: - Initialization

    private init() {
        loadPersistedData()
        updateMostUsedPreset()
    }

    // MARK: - Public Methods

    /// Records usage of a preset and updates most-used tracking.
    func recordUsage(_ preset: StylePreset) {
        let currentCount = usageCounts[preset.id] ?? 0
        usageCounts[preset.id] = currentCount + 1

        updateMostUsedPreset()
        persistData()

        PostHogManager.shared.track("style_preset_used", properties: [
            "preset_name": preset.name,
            "preset_id": preset.id,
            "total_uses": usageCounts[preset.id] ?? 1
        ])
    }

    /// Returns the recommended preset for the user.
    /// Falls back to free tier presets if no usage history.
    func recommendedPreset(for tier: SubscriptionTier) -> StylePreset? {
        // If we have a most-used preset that's available for this tier, use it
        if let mostUsed = mostUsedPreset {
            let availablePresets = StylePreset.available(for: tier)
            if availablePresets.contains(where: { $0.id == mostUsed.id }) {
                return mostUsed
            }
        }

        // Otherwise, return first available free preset
        return StylePreset.available(for: tier).first
    }

    /// Clears all usage history.
    func resetHistory() {
        usageCounts = [:]
        mostUsedPreset = nil
        presetStats = []
        storedUsageCountsData = ""
        storedMostUsedId = ""

        PostHogManager.shared.track("style_preset_history_reset")
    }

    /// Returns presets sorted by usage (most-used first).
    func presetsSortedByUsage(for tier: SubscriptionTier) -> [StylePreset] {
        let available = StylePreset.available(for: tier)

        return available.sorted { preset1, preset2 in
            let count1 = usageCounts[preset1.id] ?? 0
            let count2 = usageCounts[preset2.id] ?? 0
            return count1 > count2
        }
    }

    // MARK: - Private Methods

    private func updateMostUsedPreset() {
        // Find preset with highest usage count
        var highestCount = 0
        var highestPresetId: String?

        for (presetId, count) in usageCounts where count > highestCount {
            highestCount = count
            highestPresetId = presetId
        }

        if let id = highestPresetId {
            mostUsedPreset = StylePreset.allPresets.first { $0.id == id }
            storedMostUsedId = id
        } else {
            mostUsedPreset = nil
            storedMostUsedId = ""
        }

        // Update preset stats for display
        presetStats = StylePreset.allPresets.map { preset in
            (preset: preset, count: usageCounts[preset.id] ?? 0)
        }.sorted { $0.count > $1.count }
    }

    private func persistData() {
        // Encode usage counts as JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: usageCounts),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            storedUsageCountsData = jsonString
        }
    }

    private func loadPersistedData() {
        // Load usage counts from stored JSON
        if !storedUsageCountsData.isEmpty {
            if let jsonData = storedUsageCountsData.data(using: .utf8),
               let decoded = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Int] {
                usageCounts = decoded
            }
        }

        // Load most-used preset
        if !storedMostUsedId.isEmpty {
            mostUsedPreset = StylePreset.allPresets.first { $0.id == storedMostUsedId }
        }
    }
}
