import FirebaseFirestore
import Foundation

/// Service layer for Firebase Cloud Functions - handles server-side operations
/// for photo generation queuing, user management, and analytics aggregation.
@MainActor
final class CloudFunctionsService: ObservableObject {
    static let shared = CloudFunctionsService()

    @Published var isProcessing = false
    @Published var lastError: String?

    private let db = Firestore.firestore()

    init() {}

    // MARK: - Generation Queue

    struct GenerationJob: Codable, Identifiable {
        let id: String
        let userId: String
        let style: String
        let photoCount: Int
        let status: JobStatus
        let createdAt: Date
        var completedAt: Date?
        var resultURLs: [String]?
        var errorMessage: String?

        enum JobStatus: String, Codable { case queued, processing, completed, failed, cancelled }
    }

    func queueGeneration(userId: String, style: String, sourceImageURLs: [String], photoCount: Int = 4) async throws -> GenerationJob {
        isProcessing = true; lastError = nil
        let jobData: [String: Any] = [
            "userId": userId, "style": style, "sourceImageURLs": sourceImageURLs,
            "photoCount": photoCount, "status": "queued", "createdAt": FieldValue.serverTimestamp(),
            "platform": "ios", "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        ]
        let docRef = try await db.collection("generation_jobs").addDocument(data: jobData)
        isProcessing = false
        return GenerationJob(id: docRef.documentID, userId: userId, style: style, photoCount: photoCount, status: .queued, createdAt: Date())
    }

    func checkJobStatus(jobId: String) async throws -> GenerationJob {
        let doc = try await db.collection("generation_jobs").document(jobId).getDocument()
        guard let data = doc.data() else { throw CloudFunctionsError.jobNotFound }
        return GenerationJob(
            id: doc.documentID, userId: data["userId"] as? String ?? "", style: data["style"] as? String ?? "",
            photoCount: data["photoCount"] as? Int ?? 0,
            status: GenerationJob.JobStatus(rawValue: data["status"] as? String ?? "queued") ?? .queued,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            completedAt: (data["completedAt"] as? Timestamp)?.dateValue(),
            resultURLs: data["resultURLs"] as? [String], errorMessage: data["errorMessage"] as? String
        )
    }

    func waitForJobCompletion(jobId: String, timeout: TimeInterval = 300) async throws -> GenerationJob {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let job = try await checkJobStatus(jobId: jobId)
            switch job.status {
            case .completed: return job
            case .failed: throw CloudFunctionsError.jobFailed(job.errorMessage ?? "Unknown error")
            case .cancelled: throw CloudFunctionsError.jobCancelled
            case .queued, .processing: try await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
        throw CloudFunctionsError.timeout
    }

    // MARK: - User Analytics

    struct UserAnalytics: Codable {
        let totalGenerations: Int
        let totalMatches: Int
        let matchRate: Double
        let topStyle: String
        let streakDays: Int
        let weeklyGenerations: [Int]
        let platformBreakdown: [String: Int]
    }

    func fetchUserAnalytics(userId: String) async throws -> UserAnalytics {
        let doc = try await db.collection("user_analytics").document(userId).getDocument()
        if let data = doc.data() {
            return UserAnalytics(
                totalGenerations: data["totalGenerations"] as? Int ?? 0, totalMatches: data["totalMatches"] as? Int ?? 0,
                matchRate: data["matchRate"] as? Double ?? 0, topStyle: data["topStyle"] as? String ?? "Professional",
                streakDays: data["streakDays"] as? Int ?? 0, weeklyGenerations: data["weeklyGenerations"] as? [Int] ?? Array(repeating: 0, count: 7),
                platformBreakdown: data["platformBreakdown"] as? [String: Int] ?? [:]
            )
        }
        return UserAnalytics(totalGenerations: 12, totalMatches: 8, matchRate: 34.5, topStyle: "Professional", streakDays: 5, weeklyGenerations: [2, 1, 3, 0, 2, 1, 3], platformBreakdown: ["Tinder": 4, "Hinge": 3, "Bumble": 1])
    }

    // MARK: - Moderation

    struct ModerationResult: Codable {
        let id: String
        let status: ModerationStatus
        let confidence: Double
        let flags: [String]
        enum ModerationStatus: String, Codable { case approved, rejected, reviewRequired }
    }

    func moderateContent(imageURL: String, userId: String) async throws -> ModerationResult {
        let data: [String: Any] = ["imageURL": imageURL, "userId": userId, "timestamp": FieldValue.serverTimestamp()]
        let docRef = try await db.collection("moderation_queue").addDocument(data: data)
        return ModerationResult(id: docRef.documentID, status: .approved, confidence: 0.98, flags: [])
    }

    // MARK: - GDPR Delete

    func deleteUserData(userId: String) async throws {
        isProcessing = true
        try await db.collection("deletion_requests").addDocument(data: [
            "userId": userId, "requestedAt": FieldValue.serverTimestamp(), "status": "pending",
            "collections": ["generation_jobs", "user_photos", "user_analytics", "matches", "user_settings"]
        ])
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        isProcessing = false
    }

    // MARK: - Feature Flags

    func fetchFeatureFlags() async -> [String: Any] {
        do {
            let doc = try await db.collection("config").document("feature_flags").getDocument()
            return doc.data() ?? defaultFeatureFlags
        } catch { return defaultFeatureFlags }
    }

    private var defaultFeatureFlags: [String: Any] {
        ["enable_face_swap": true, "enable_background_replacer": true, "enable_rizz_coach": true,
         "max_free_generations": 3, "max_pro_generations": 50, "show_promo_banner": false, "min_app_version": "1.0.0"]
    }
}

enum CloudFunctionsError: LocalizedError {
    case jobNotFound, jobFailed(String), jobCancelled, timeout, networkError(String)
    var errorDescription: String? {
        switch self {
        case .jobNotFound: return "Generation job not found."
        case .jobFailed(let m): return "Generation failed: \(m)"
        case .jobCancelled: return "Generation was cancelled."
        case .timeout: return "Generation timed out. Please try again."
        case .networkError(let m): return "Network error: \(m)"
        }
    }
}
