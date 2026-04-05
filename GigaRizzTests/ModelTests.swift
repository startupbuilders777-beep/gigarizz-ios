@testable import GigaRizz
import XCTest

// MARK: - PhotoModel Tests

final class PhotoModelTests: XCTestCase {

    // MARK: - UserPhoto

    func testUserPhoto_defaultInit() {
        let photo = UserPhoto(userId: "user123")
        XCTAssertFalse(photo.id.isEmpty)
        XCTAssertEqual(photo.userId, "user123")
        XCTAssertNil(photo.originalURL)
        XCTAssertEqual(photo.status, .uploading)
    }

    func testUserPhoto_allStatusCases() {
        let statuses: [UserPhoto.PhotoStatus] = [.uploading, .uploaded, .processing, .completed, .failed]
        for status in statuses {
            let photo = UserPhoto(userId: "u1", status: status)
            XCTAssertEqual(photo.status, status)
        }
    }

    func testUserPhoto_codableRoundTrip() throws {
        let photo = UserPhoto(
            id: "test-id",
            userId: "user1",
            originalURL: URL(string: "https://example.com/photo.jpg"),
            status: .completed
        )
        let data = try JSONEncoder().encode(photo)
        let decoded = try JSONDecoder().decode(UserPhoto.self, from: data)
        XCTAssertEqual(photo, decoded)
    }

    func testUserPhoto_equatable() {
        let photo1 = UserPhoto(id: "same-id", userId: "u1")
        let photo2 = UserPhoto(id: "same-id", userId: "u1")
        let photo3 = UserPhoto(id: "diff-id", userId: "u1")
        XCTAssertEqual(photo1, photo2)
        XCTAssertNotEqual(photo1, photo3)
    }

    // MARK: - GeneratedPhoto

    func testGeneratedPhoto_defaultInit() {
        let photo = GeneratedPhoto(userId: "u1", style: "Professional")
        XCTAssertFalse(photo.id.isEmpty)
        XCTAssertEqual(photo.userId, "u1")
        XCTAssertEqual(photo.style, "Professional")
        XCTAssertNil(photo.imageURL)
        XCTAssertNil(photo.thumbnailURL)
        XCTAssertFalse(photo.isFavorite)
    }

    func testGeneratedPhoto_withURLs() {
        let photo = GeneratedPhoto(
            userId: "u1",
            style: "Casual",
            imageURL: URL(string: "https://cdn.gigarizz.com/photo.jpg"),
            thumbnailURL: URL(string: "https://cdn.gigarizz.com/thumb.jpg"),
            isFavorite: true
        )
        XCTAssertNotNil(photo.imageURL)
        XCTAssertNotNil(photo.thumbnailURL)
        XCTAssertTrue(photo.isFavorite)
    }

    func testGeneratedPhoto_codableRoundTrip() throws {
        let photo = GeneratedPhoto(
            id: "gen-1",
            userId: "u1",
            style: "Bold",
            imageURL: URL(string: "https://example.com/img.jpg"),
            thumbnailURL: URL(string: "https://example.com/thumb.jpg"),
            isFavorite: true
        )
        let data = try JSONEncoder().encode(photo)
        let decoded = try JSONDecoder().decode(GeneratedPhoto.self, from: data)
        XCTAssertEqual(photo, decoded)
    }

    // MARK: - PhotoScore

    func testPhotoScore_init() {
        let score = PhotoScore(
            overallScore: 8.5,
            categories: [
                PhotoScore.ScoreCategory(name: "Lighting", score: 9.0, feedback: "Great")
            ],
            suggestions: ["Try outdoor shots"]
        )
        XCTAssertEqual(score.overallScore, 8.5)
        XCTAssertEqual(score.categories.count, 1)
        XCTAssertEqual(score.suggestions.count, 1)
    }

    func testPhotoScore_demo_isValid() {
        let demo = PhotoScore.demo
        XCTAssertGreaterThan(demo.overallScore, 0)
        XCTAssertLessThanOrEqual(demo.overallScore, 10)
        XCTAssertEqual(demo.categories.count, 5)
        XCTAssertFalse(demo.suggestions.isEmpty)
    }

    func testPhotoScore_codableRoundTrip() throws {
        let score = PhotoScore.demo
        let data = try JSONEncoder().encode(score)
        let decoded = try JSONDecoder().decode(PhotoScore.self, from: data)
        XCTAssertEqual(score.overallScore, decoded.overallScore)
        XCTAssertEqual(score.categories.count, decoded.categories.count)
        XCTAssertEqual(score.suggestions, decoded.suggestions)
    }

    func testScoreCategory_init() {
        let cat = PhotoScore.ScoreCategory(name: "Composition", score: 7.5, feedback: "Good framing")
        XCTAssertEqual(cat.name, "Composition")
        XCTAssertEqual(cat.score, 7.5)
        XCTAssertEqual(cat.feedback, "Good framing")
        XCTAssertFalse(cat.id.isEmpty)
    }
}

// MARK: - ServiceMode Tests

final class ServiceModeTests: XCTestCase {

    func testCurrent_isMock() {
        // ServiceMode.current should be .mock during dev/testing
        XCTAssertEqual(ServiceMode.current, .mock, "ServiceMode should be .mock during development")
    }
}

// MARK: - RizzCoachModels Tests

final class RizzCoachModelsTests: XCTestCase {

    // MARK: - RizzScore

    func testRizzScore_clampsAbove100() {
        let score = RizzScore(overallScore: 150, categories: [], trend: .stable)
        XCTAssertEqual(score.overallScore, 100)
    }

    func testRizzScore_clampsBelow1() {
        let score = RizzScore(overallScore: -10, categories: [], trend: .stable)
        XCTAssertEqual(score.overallScore, 1)
    }

    func testRizzScore_normalRange() {
        let score = RizzScore(overallScore: 72, categories: [], trend: .improving)
        XCTAssertEqual(score.overallScore, 72)
    }

    func testRizzScore_edgeCases() {
        XCTAssertEqual(RizzScore(overallScore: 0, categories: [], trend: .stable).overallScore, 1)
        XCTAssertEqual(RizzScore(overallScore: 1, categories: [], trend: .stable).overallScore, 1)
        XCTAssertEqual(RizzScore(overallScore: 100, categories: [], trend: .stable).overallScore, 100)
        XCTAssertEqual(RizzScore(overallScore: 101, categories: [], trend: .stable).overallScore, 100)
    }

    func testRizzScore_trends() {
        XCTAssertEqual(RizzScore.ScoreTrend.improving.rawValue, "Improving")
        XCTAssertEqual(RizzScore.ScoreTrend.stable.rawValue, "Stable")
        XCTAssertEqual(RizzScore.ScoreTrend.declining.rawValue, "Needs Attention")
    }

    func testRizzScore_demo() {
        let demo = RizzScore.demo
        XCTAssertEqual(demo.overallScore, 72)
        XCTAssertEqual(demo.categories.count, 5)
        XCTAssertEqual(demo.previousScore, 65)
        XCTAssertEqual(demo.trend, .improving)
    }

    func testRizzScore_codableRoundTrip() throws {
        let score = RizzScore.demo
        let data = try JSONEncoder().encode(score)
        let decoded = try JSONDecoder().decode(RizzScore.self, from: data)
        XCTAssertEqual(score.overallScore, decoded.overallScore)
        XCTAssertEqual(score.categories.count, decoded.categories.count)
        XCTAssertEqual(score.trend, decoded.trend)
        XCTAssertEqual(score.previousScore, decoded.previousScore)
    }

    func testRizzScore_withPreviousScore() {
        let score = RizzScore(
            overallScore: 80,
            categories: [],
            previousScore: 70,
            trend: .improving
        )
        XCTAssertEqual(score.previousScore, 70)
        XCTAssertEqual(score.trend, .improving)
    }

    // MARK: - RizzScoreCategory

    func testRizzScoreCategory_clampsAbove100() {
        let cat = RizzScoreCategory(name: "Test", score: 200, weight: 0.5, icon: "star")
        XCTAssertEqual(cat.score, 100)
    }

    func testRizzScoreCategory_clampsBelow1() {
        let cat = RizzScoreCategory(name: "Test", score: -50, weight: 0.5, icon: "star")
        XCTAssertEqual(cat.score, 1)
    }

    func testRizzScoreCategory_validInit() {
        let cat = RizzScoreCategory(name: "Photos", score: 75, weight: 0.35, icon: "photo.fill")
        XCTAssertEqual(cat.name, "Photos")
        XCTAssertEqual(cat.score, 75)
        XCTAssertEqual(cat.weight, 0.35)
        XCTAssertEqual(cat.icon, "photo.fill")
        XCTAssertNil(cat.feedback)
    }

    func testRizzScoreCategory_withFeedback() {
        let cat = RizzScoreCategory(
            name: "Bio",
            score: 68,
            weight: 0.25,
            icon: "text.quote",
            feedback: "Could be more specific"
        )
        XCTAssertEqual(cat.feedback, "Could be more specific")
    }

    // MARK: - WeeklyRizzReport

    func testWeeklyRizzReport_demo() {
        let demo = WeeklyRizzReport.demo
        XCTAssertEqual(demo.scoreChange, 7)
        XCTAssertEqual(demo.insights.count, 3)
        XCTAssertEqual(demo.topActions.count, 3)
        XCTAssertNotNil(demo.milestone)
    }

    func testWeeklyRizzReport_codable() throws {
        let report = WeeklyRizzReport.demo
        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(WeeklyRizzReport.self, from: data)
        XCTAssertEqual(report.scoreChange, decoded.scoreChange)
        XCTAssertEqual(report.insights.count, decoded.insights.count)
        XCTAssertEqual(report.topActions.count, decoded.topActions.count)
    }

    // MARK: - BioStrength

    func testBioStrength_clampsScores() {
        let bio = BioStrength(
            overallScore: 150,
            voiceConsistency: -10,
            specificity: 200,
            hookQuality: 0,
            lengthScore: 50,
            suggestions: []
        )
        XCTAssertEqual(bio.overallScore, 100)
        XCTAssertEqual(bio.voiceConsistency, 1)
        XCTAssertEqual(bio.specificity, 100)
        XCTAssertEqual(bio.hookQuality, 1)
        XCTAssertEqual(bio.lengthScore, 50)
    }

    func testBioStrength_demo() {
        let demo = BioStrength.demo
        XCTAssertEqual(demo.overallScore, 68)
        XCTAssertEqual(demo.suggestions.count, 4)
    }

    // MARK: - PhotoPerformance

    func testPhotoPerformance_demoArray() {
        let demos = PhotoPerformance.demoPerformances
        XCTAssertEqual(demos.count, 4)
        // Should be in rank order
        for (i, perf) in demos.enumerated() {
            XCTAssertEqual(perf.rank, i + 1)
        }
        // Swipe rates should generally decrease by rank
        XCTAssertGreaterThan(demos[0].swipeRate, demos[3].swipeRate)
    }

    // MARK: - ResponseTimeStats

    func testResponseTimeStats_demo() {
        let demo = ResponseTimeStats.demo
        XCTAssertEqual(demo.averageResponseHours, 6.2)
        XCTAssertEqual(demo.streak, 3)
        XCTAssertNotNil(demo.nudgeMessage)
        XCTAssertFalse(demo.improvementTip.isEmpty)
    }

    // MARK: - DailyTip

    func testDailyTip_demo() {
        let demo = DailyTip.demo
        XCTAssertEqual(demo.title, "Golden Hour Magic")
        XCTAssertEqual(demo.category, .photo)
        XCTAssertFalse(demo.actionTitle.isEmpty)
    }

    func testDailyTip_allCategories() {
        let categories: [DailyTip.TipCategory] = [.photo, .bio, .conversation, .activity, .timing]
        for cat in categories {
            XCTAssertFalse(cat.rawValue.isEmpty)
        }
    }

    // MARK: - RizzInsight

    func testRizzInsight_allTypes() {
        let types: [RizzInsight.InsightType] = [.photo, .bio, .response, .activity, .prompts]
        for type in types {
            XCTAssertFalse(type.rawValue.isEmpty)
        }
    }
}
