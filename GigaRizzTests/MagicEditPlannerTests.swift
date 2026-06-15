@testable import GigaRizz
import XCTest

/// Locks the Magic Studio planner — the V5 flagship "complex operations" brain.
/// A regression here silently breaks the FaceApp/Facetune differentiator
/// (compound, transparent, identity-aware edits from one sentence).
final class MagicEditPlannerTests: XCTestCase {

    func testCompoundRequest_decomposesIntoOrderedSteps() {
        let plan = MagicEditPlanner.plan(
            from: "Put me on a rooftop bar at golden hour, change my hoodie to a white linen shirt, and fix the harsh lighting"
        )
        let kinds = plan.steps.map(\.kind)
        XCTAssertTrue(kinds.contains(.scene))
        XCTAssertTrue(kinds.contains(.outfit))
        XCTAssertTrue(kinds.contains(.lighting))
        // Canonical order: scene before outfit before lighting.
        XCTAssertEqual(kinds.firstIndex(of: .scene)! , 0)
        XCTAssertLessThan(kinds.firstIndex(of: .outfit)!, kinds.firstIndex(of: .lighting)!)
    }

    func testStepsAreSortedByCanonicalOrder_regardlessOfInputOrder() {
        // User types retouch first, scene last — plan must still run scene first.
        let plan = MagicEditPlanner.plan(from: "smooth my skin, then put me at the beach")
        let orders = plan.steps.map { $0.kind.canonicalOrder }
        XCTAssertEqual(orders, orders.sorted(), "Steps must be in canonical order")
    }

    func testEmptyRequest_producesEmptyPlan() {
        XCTAssertTrue(MagicEditPlanner.plan(from: "   ").isEmpty)
    }

    func testUnknownRequest_neverBlocksUser_fallsBackToScene() {
        let plan = MagicEditPlanner.plan(from: "make it look amazing somehow")
        XCTAssertFalse(plan.isEmpty)
        XCTAssertEqual(plan.steps.first?.kind, .scene)
    }

    func testComposedPrompt_carriesIdentityLockAndUserRequest() {
        let plan = MagicEditPlanner.plan(from: "navy blazer, warm cinematic color grade")
        XCTAssertTrue(plan.composedPrompt.lowercased().contains("same person"),
                      "Composed prompt must assert identity lock")
        XCTAssertTrue(plan.composedPrompt.contains("navy blazer"),
                      "Composed prompt must echo the user request")
    }

    func testIdentityImpact_sceneAndLightingDoNotTouchFace() {
        XCTAssertEqual(MagicEditStep.Kind.scene.identityImpact, .none)
        XCTAssertEqual(MagicEditStep.Kind.lighting.identityImpact, .none)
        XCTAssertEqual(MagicEditStep.Kind.retouch.identityImpact, .medium)
    }
}
