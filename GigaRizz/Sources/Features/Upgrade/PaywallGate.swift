import Foundation

// MARK: - PaywallGate
//
// Decides whether the audit-completion → diagnosis transition should pass
// through a paywall first. Pure decision logic so it's unit-testable without
// mounting any UI.
//
// Inputs come from server-driven feature flags (paywall_mode + threshold) plus
// the local subscription state and a per-device "audits used" counter.
//
// Modes:
//   .none → never blocks
//   .soft → blocks AFTER N free audits, dismissible
//   .hard → blocks immediately on first audit completion, NOT dismissible

enum PaywallGateDecision: Equatable {
    case proceed
    case showSoft   // dismissible
    case showHard   // blocking
}

@MainActor
struct PaywallGate {
    let mode: FeatureFlagManager.PaywallMode
    let softThreshold: Int
    let isSubscribed: Bool
    let auditsUsedSoFar: Int

    func decide() -> PaywallGateDecision {
        if isSubscribed { return .proceed }
        switch mode {
        case .none:
            return .proceed
        case .hard:
            return .showHard
        case .soft:
            return auditsUsedSoFar >= softThreshold ? .showSoft : .proceed
        }
    }
}

// MARK: - AuditUsageCounter

/// Per-device counter for how many audits the user has run. Drives the soft
/// paywall threshold check. Lives in UserDefaults so it survives re-launches.
@MainActor
final class AuditUsageCounter {
    static let shared = AuditUsageCounter()

    private let key = "gigarizz_audit_usage_count"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var count: Int {
        defaults.integer(forKey: key)
    }

    func incrementOnAuditCompleted() {
        defaults.set(count + 1, forKey: key)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
