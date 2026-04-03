import Foundation

// MARK: - AI API Config

/// Configuration for AI generation limits per tier.
enum AIAPIConfig {
    static let freeGenerationsPerDay = 10
    static let proGenerationsPerDay = 100
    static let generationsCooldownSeconds: TimeInterval = 5
}

/// Rate limiter with sliding window and persistent daily tracking.
/// Prevents abuse across photo generation, API calls, and feature usage.
@MainActor
final class RateLimiter: ObservableObject {
    static let shared = RateLimiter()

    struct RateLimit {
        let action: String
        let maxCount: Int
        let windowSeconds: TimeInterval
        let cooldownSeconds: TimeInterval

        static let photoGeneration = RateLimit(action: "photo_generation", maxCount: 50, windowSeconds: 86400, cooldownSeconds: 30)
        static let apiCall = RateLimit(action: "api_call", maxCount: 100, windowSeconds: 3600, cooldownSeconds: 1)
        static let feedbackSubmission = RateLimit(action: "feedback", maxCount: 5, windowSeconds: 86400, cooldownSeconds: 60)
        static let shareAction = RateLimit(action: "share", maxCount: 20, windowSeconds: 3600, cooldownSeconds: 5)
        static let matchAdd = RateLimit(action: "match_add", maxCount: 50, windowSeconds: 86400, cooldownSeconds: 2)
    }

    private var usageLog: [String: [Date]] = [:]
    private var cooldowns: [String: Date] = [:]
    private let storageKey = "com.gigarizz.ratelimiter.usage"

    init() {
        loadPersistedUsage()
        cleanupExpiredEntries()
    }

    func canPerform(_ action: String, limit: Int, windowSeconds: TimeInterval = 86400) -> Bool {
        cleanupExpiredEntries()
        if let cooldownEnd = cooldowns[action], Date() < cooldownEnd { return false }
        let now = Date()
        let windowStart = now.addingTimeInterval(-windowSeconds)
        let recentActions = (usageLog[action] ?? []).filter { $0 > windowStart }
        return recentActions.count < limit
    }

    func recordUsage(_ action: String, cooldownSeconds: TimeInterval = 0) {
        var entries = usageLog[action] ?? []
        entries.append(Date())
        usageLog[action] = entries
        if cooldownSeconds > 0 { cooldowns[action] = Date().addingTimeInterval(cooldownSeconds) }
        persistUsage()
    }

    func todayCount(for action: String) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return (usageLog[action] ?? []).filter { $0 >= startOfDay }.count
    }

    func remaining(for action: String, limit: Int) -> Int { max(0, limit - todayCount(for: action)) }

    func cooldownRemaining(for action: String) -> TimeInterval? {
        guard let cooldownEnd = cooldowns[action] else { return nil }
        let remaining = cooldownEnd.timeIntervalSince(Date())
        return remaining > 0 ? remaining : nil
    }

    func resetAll() { usageLog.removeAll(); cooldowns.removeAll(); persistUsage() }
    func reset(action: String) { usageLog[action] = nil; cooldowns[action] = nil; persistUsage() }

    private func persistUsage() {
        var serialized: [String: [TimeInterval]] = [:]
        for (key, dates) in usageLog { serialized[key] = dates.map { $0.timeIntervalSince1970 } }
        if let data = try? JSONEncoder().encode(serialized) { UserDefaults.standard.set(data, forKey: storageKey) }
    }

    private func loadPersistedUsage() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let serialized = try? JSONDecoder().decode([String: [TimeInterval]].self, from: data) else { return }
        for (key, timestamps) in serialized { usageLog[key] = timestamps.map { Date(timeIntervalSince1970: $0) } }
    }

    private func cleanupExpiredEntries() {
        let cutoff = Date().addingTimeInterval(-86400 * 2)
        for (key, dates) in usageLog { usageLog[key] = dates.filter { $0 > cutoff } }
        cooldowns = cooldowns.filter { $0.value > Date() }
    }

    func checkPhotoGeneration(isPro: Bool) -> (allowed: Bool, message: String?) {
        let limit = isPro ? AIAPIConfig.proGenerationsPerDay : AIAPIConfig.freeGenerationsPerDay
        let used = todayCount(for: "photo_generation")
        if used >= limit {
            if isPro { return (false, "You\u{2019}ve used all \(limit) pro generations today. Resets at midnight.") } else { return (false, "Free tier limit reached (\(limit)/day). Upgrade to Pro for \(AIAPIConfig.proGenerationsPerDay) generations/day!") }
        }
        if let cooldown = cooldownRemaining(for: "photo_generation") {
            return (false, "Please wait \(Int(cooldown))s before generating again.")
        }
        return (true, nil)
    }
}
