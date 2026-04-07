@testable import GigaRizz
import XCTest

// MARK: - CoachService Model Tests

final class CoachServiceTests: XCTestCase {

    // MARK: - BioTone

    func testBioTone_allCases() {
        let cases = CoachService.BioTone.allCases
        XCTAssertEqual(cases.count, 3)
        XCTAssertTrue(cases.contains(.witty))
        XCTAssertTrue(cases.contains(.sincere))
        XCTAssertTrue(cases.contains(.bold))
    }

    func testBioTone_idMatchesRawValue() {
        for tone in CoachService.BioTone.allCases {
            XCTAssertEqual(tone.id, tone.rawValue)
        }
    }

    func testBioTone_rawValues() {
        XCTAssertEqual(CoachService.BioTone.witty.rawValue, "Witty & Playful")
        XCTAssertEqual(CoachService.BioTone.sincere.rawValue, "Sincere & Genuine")
        XCTAssertEqual(CoachService.BioTone.bold.rawValue, "Bold & Confident")
    }

    // MARK: - ChatMessage

    func testChatMessage_init() {
        let msg = CoachService.ChatMessage(role: .user, content: "Hello")
        XCTAssertFalse(msg.id.isEmpty)
        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.content, "Hello")
    }

    func testChatMessage_roles() {
        let roles: [CoachService.ChatMessage.Role] = [.user, .assistant, .system]
        XCTAssertEqual(roles.count, 3)
        XCTAssertEqual(CoachService.ChatMessage.Role.user.rawValue, "user")
        XCTAssertEqual(CoachService.ChatMessage.Role.assistant.rawValue, "assistant")
        XCTAssertEqual(CoachService.ChatMessage.Role.system.rawValue, "system")
    }

    func testChatMessage_equatable() {
        let date = Date()
        let msg1 = CoachService.ChatMessage(id: "same", role: .user, content: "Hi", timestamp: date)
        let msg2 = CoachService.ChatMessage(id: "same", role: .user, content: "Hi", timestamp: date)
        let msg3 = CoachService.ChatMessage(id: "diff", role: .user, content: "Hi", timestamp: date)
        XCTAssertEqual(msg1, msg2)
        XCTAssertNotEqual(msg1, msg3)
    }
}

// MARK: - Match Status Tests

final class MatchStatusTests: XCTestCase {

    func testMatchStatus_allCases() {
        // Verify Match.MatchStatus has expected values
        let match = Match(name: "Test", status: .new)
        XCTAssertEqual(match.status, .new)

        let active = Match(name: "Test", status: .active)
        XCTAssertEqual(active.status, .active)

        let archived = Match(name: "Test", status: .archived)
        XCTAssertEqual(archived.status, .archived)
    }

    func testMatch_codableRoundTrip() throws {
        let match = Match(
            id: "m1",
            name: "Alice",
            platform: .hinge,
            status: .active,
            notes: "Great match",
            lastMessageDate: Date(timeIntervalSince1970: 1700000000),
            matchedDate: Date(timeIntervalSince1970: 1699000000)
        )
        let data = try JSONEncoder().encode(match)
        let decoded = try JSONDecoder().decode(Match.self, from: data)
        XCTAssertEqual(match.id, decoded.id)
        XCTAssertEqual(match.name, decoded.name)
        XCTAssertEqual(match.platform, decoded.platform)
        XCTAssertEqual(match.status, decoded.status)
        XCTAssertEqual(match.notes, decoded.notes)
    }
}

// MARK: - DatingPlatform Extended Tests

final class DatingPlatformExtendedTests: XCTestCase {

    func testAllPlatforms_haveNonEmptyDisplayData() {
        for platform in DatingPlatform.allCases {
            XCTAssertFalse(platform.rawValue.isEmpty, "\(platform) should have a raw value")
            XCTAssertFalse(platform.icon.isEmpty, "\(platform) should have an icon")
            XCTAssertNotNil(platform.color, "\(platform) should have a color")
        }
    }

    func testPlatform_identifiable() {
        for platform in DatingPlatform.allCases {
            XCTAssertEqual(platform.id, platform.rawValue)
        }
    }
}

// MARK: - UserDefaults Persistence Tests

final class PersistenceTests: XCTestCase {

    let testSuiteName = "com.gigarizz.test.suite"
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: testSuiteName)!
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        super.tearDown()
    }

    func testFeatureFlags_persistAndRestore() throws {
        let key = "gigarizz_feature_flags"
        var flags = FeatureFlagManager.FeatureFlags.defaults
        flags = FeatureFlagManager.FeatureFlags(
            enableGeneration: false,
            enableCoach: true,
            enableFaceSwap: true,
            enableBackgroundReplacer: false,
            enableExpressionCoach: true,
            enablePhotoRanking: false,
            enableColorGrade: true,
            enablePoseLibrary: false,
            enableIntroOffer: true,
            enableBatchGeneration: false,
            enablePremiumModels: true,
            enablePhotorealisticModels: true,
            enableArtisticModels: false,
            maxFreeGenerations: 10,
            maxPlusGenerations: 100,
            maxGoldGenerations: 5000,
            maxBatchModels: 2,
            showPromoBanner: true,
            minAppVersion: "3.0.0"
        )
        let data = try JSONEncoder().encode(flags)
        testDefaults.set(data, forKey: key)

        // Read back
        guard let stored = testDefaults.data(forKey: key) else {
            XCTFail("No data stored"); return
        }
        let decoded = try JSONDecoder().decode(FeatureFlagManager.FeatureFlags.self, from: stored)
        XCTAssertEqual(decoded.enableGeneration, false)
        XCTAssertEqual(decoded.enableFaceSwap, true)
        XCTAssertEqual(decoded.maxFreeGenerations, 10)
        XCTAssertEqual(decoded.maxGoldGenerations, 5000)
        XCTAssertEqual(decoded.minAppVersion, "3.0.0")
    }

    func testGeneratedPhotos_persistAndRestore() throws {
        let key = "gigarizz_generated_photos"
        let photos = [
            GeneratedPhoto(id: "p1", userId: "u1", style: "Pro", isFavorite: true),
            GeneratedPhoto(id: "p2", userId: "u1", style: "Casual", isFavorite: false)
        ]
        let data = try JSONEncoder().encode(photos)
        testDefaults.set(data, forKey: key)

        guard let stored = testDefaults.data(forKey: key) else {
            XCTFail("No data stored"); return
        }
        let decoded = try JSONDecoder().decode([GeneratedPhoto].self, from: stored)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].id, "p1")
        XCTAssertEqual(decoded[0].style, "Pro")
        XCTAssertTrue(decoded[0].isFavorite)
        XCTAssertEqual(decoded[1].id, "p2")
    }

    func testMatches_persistAndRestore() throws {
        let key = "gigarizz_user_matches"
        let matches = [
            Match(id: "m1", name: "Alice", platform: .tinder, status: .active),
            Match(id: "m2", name: "Bob", platform: .bumble, status: .new)
        ]
        let data = try JSONEncoder().encode(matches)
        testDefaults.set(data, forKey: key)

        guard let stored = testDefaults.data(forKey: key) else {
            XCTFail("No data stored"); return
        }
        let decoded = try JSONDecoder().decode([Match].self, from: stored)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].name, "Alice")
        XCTAssertEqual(decoded[1].platform, .bumble)
    }
}
