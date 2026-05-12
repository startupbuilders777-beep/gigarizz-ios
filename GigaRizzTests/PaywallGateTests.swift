@testable import GigaRizz
import XCTest

@MainActor
final class PaywallGateTests: XCTestCase {

    func testProceed_whenSubscribed_regardlessOfMode() {
        for mode in [FeatureFlagManager.PaywallMode.none, .soft, .hard] {
            let gate = PaywallGate(mode: mode, softThreshold: 1, isSubscribed: true, auditsUsedSoFar: 99)
            XCTAssertEqual(gate.decide(), .proceed, "Subscribed user should never see paywall (mode=\(mode))")
        }
    }

    func testProceed_whenModeNone() {
        let gate = PaywallGate(mode: .none, softThreshold: 0, isSubscribed: false, auditsUsedSoFar: 100)
        XCTAssertEqual(gate.decide(), .proceed)
    }

    func testHard_whenModeHardAndNotSubscribed() {
        let gate = PaywallGate(mode: .hard, softThreshold: 0, isSubscribed: false, auditsUsedSoFar: 0)
        XCTAssertEqual(gate.decide(), .showHard)
    }

    func testSoft_proceedsBeforeThreshold() {
        let gate = PaywallGate(mode: .soft, softThreshold: 3, isSubscribed: false, auditsUsedSoFar: 2)
        XCTAssertEqual(gate.decide(), .proceed)
    }

    func testSoft_triggersAtThreshold() {
        let gate = PaywallGate(mode: .soft, softThreshold: 3, isSubscribed: false, auditsUsedSoFar: 3)
        XCTAssertEqual(gate.decide(), .showSoft)
    }

    func testSoft_triggersAfterThreshold() {
        let gate = PaywallGate(mode: .soft, softThreshold: 1, isSubscribed: false, auditsUsedSoFar: 5)
        XCTAssertEqual(gate.decide(), .showSoft)
    }

    // MARK: - AuditUsageCounter

    func testAuditUsageCounter_incrementsAndPersists() {
        let suite = "com.gigarizz.audit-counter.test"
        let defaults = UserDefaults(suiteName: suite)!
        defer { UserDefaults().removePersistentDomain(forName: suite) }

        let c1 = AuditUsageCounter(defaults: defaults)
        XCTAssertEqual(c1.count, 0)
        c1.incrementOnAuditCompleted()
        c1.incrementOnAuditCompleted()
        XCTAssertEqual(c1.count, 2)

        // Re-instantiate; persistence should survive.
        let c2 = AuditUsageCounter(defaults: defaults)
        XCTAssertEqual(c2.count, 2)

        c2.reset()
        XCTAssertEqual(c2.count, 0)
    }
}
