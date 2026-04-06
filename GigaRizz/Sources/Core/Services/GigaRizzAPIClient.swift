import FirebaseAuth
import Foundation

/// Networking client for the GigaRizz FastAPI backend.
/// Handles auth token injection, JSON encoding/decoding, and error mapping.
actor GigaRizzAPIClient {
    static let shared = GigaRizzAPIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Base URL

    private var baseURL: String {
        AppConstants.backendBaseURL
    }

    // MARK: - Auth Token

    /// Get the current Firebase ID token for authenticated requests.
    private func authToken() async -> String? {
        #if DEBUG
        // Dev mode: backend accepts unauthenticated requests
        return nil
        #else
        // Production: get Firebase ID token
        do {
            return try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    guard let user = AuthManager.shared.currentUser else {
                        continuation.resume(returning: nil)
                        return
                    }
                    user.getIDToken { token, error in
                        if let token {
                            continuation.resume(returning: token)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }
            }
        } catch {
            return nil
        }
        #endif
    }

    // MARK: - Feature Flags

    func fetchFeatureFlags() async throws -> FeatureFlagManager.FeatureFlags {
        try await get("/api/v1/flags")
    }

    // MARK: - Generation

    struct GenerateRequest: Codable {
        let style: String
        let prompt: String?
        let model: String?
        let sourceImageUrl: String?
    }

    struct GenerationJobResponse: Codable {
        let jobId: String
        let status: String
        let style: String?
        let progress: Double
        let createdAt: String?
        let completedAt: String?
        let resultUrls: [String]
        let error: String?
    }

    func submitGeneration(style: String, prompt: String? = nil, model: String = "flux_schnell", sourceImageUrl: String? = nil) async throws -> GenerationJobResponse {
        let req = GenerateRequest(style: style, prompt: prompt, model: model, sourceImageUrl: sourceImageUrl)
        return try await post("/api/v1/generate", body: req)
    }

    func checkGeneration(jobId: String) async throws -> GenerationJobResponse {
        try await get("/api/v1/generate/\(jobId)")
    }

    func cancelGeneration(jobId: String) async throws {
        try await delete("/api/v1/generate/\(jobId)")
    }

    // MARK: - Models

    func fetchModels() async throws -> [AIModel] {
        try await get("/api/v1/generate/models")
    }

    // MARK: - Batch Generation

    struct BatchGenerateRequest: Codable {
        let style: String
        let prompt: String?
        let models: [String]
        let sourceImageUrl: String?
        let photoCount: Int
    }

    struct BatchGenerationResponse: Codable {
        let batchId: String
        let jobs: [GenerationJobResponse]
        let totalModels: Int
    }

    func submitBatchGeneration(style: String, prompt: String? = nil, models: [String], photoCount: Int = 2, sourceImageUrl: String? = nil) async throws -> BatchGenerationResponse {
        let req = BatchGenerateRequest(style: style, prompt: prompt, models: models, sourceImageUrl: sourceImageUrl, photoCount: photoCount)
        return try await post("/api/v1/generate/batch", body: req)
    }

    // MARK: - Coach

    struct BioRequest: Codable {
        let interests: [String]
        let tone: String
        let platform: String
        let vibe: String?
    }

    struct BioResponse: Codable {
        let bio: String
        let alternatives: [String]
    }

    struct OpenersRequest: Codable {
        let profileContext: String
        let count: Int
    }

    struct OpenersResponse: Codable {
        let openers: [String]
    }

    struct PromptsResponse: Codable {
        let prompts: [PromptPair]
    }

    struct PromptPair: Codable {
        let prompt: String
        let answer: String
    }

    struct ReplyRequest: Codable {
        let theirMessage: String
        let conversationContext: [String]
    }

    struct ReplyResponse: Codable {
        let replies: [String]
    }

    func generateBio(interests: [String], tone: String, platform: String, vibe: String? = nil) async throws -> BioResponse {
        let req = BioRequest(interests: interests, tone: tone, platform: platform, vibe: vibe)
        return try await post("/api/v1/coach/bio", body: req)
    }

    func generateOpeners(profileContext: String, count: Int = 5) async throws -> OpenersResponse {
        let req = OpenersRequest(profileContext: profileContext, count: count)
        return try await post("/api/v1/coach/openers", body: req)
    }

    func generatePrompts() async throws -> PromptsResponse {
        try await post("/api/v1/coach/prompts", body: EmptyBody())
    }

    func suggestReplies(theirMessage: String, conversationContext: [String] = []) async throws -> ReplyResponse {
        let req = ReplyRequest(theirMessage: theirMessage, conversationContext: conversationContext)
        return try await post("/api/v1/coach/reply", body: req)
    }

    // MARK: - User

    struct UserProfile: Codable {
        let uid: String
        let email: String?
        let displayName: String?
        let tier: String
        let totalGenerations: Int
        let createdAt: String?
    }

    struct UserAnalytics: Codable {
        let totalGenerations: Int
        let successfulGenerations: Int
        let generationsToday: Int
        let favoriteStyle: String?
    }

    func fetchProfile() async throws -> UserProfile {
        try await get("/api/v1/users/me")
    }

    func fetchAnalytics() async throws -> UserAnalytics {
        try await get("/api/v1/users/me/analytics")
    }

    func deleteAccount() async throws {
        try await delete("/api/v1/users/me")
    }

    // MARK: - Health

    struct HealthResponse: Codable {
        let status: String
        let version: String
        let environment: String
    }

    func health() async throws -> HealthResponse {
        try await get("/health")
    }

    // MARK: - HTTP Helpers

    private struct EmptyBody: Codable {}

    private func get<T: Decodable>(_ path: String) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = await authToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)
        if let token = await authToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func delete(_ path: String) async throws {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = "DELETE"
        if let token = await authToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        // 204 No Content is expected for delete
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
            return
        }
        try validateResponse(response, data: data)
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return  // Success
        case 401:
            throw APIError.unauthorized
        case 429:
            let detail = try? decoder.decode(ErrorDetail.self, from: data)
            throw APIError.rateLimited(detail?.detail ?? "Rate limit exceeded")
        case 400..<500:
            let detail = try? decoder.decode(ErrorDetail.self, from: data)
            throw APIError.clientError(httpResponse.statusCode, detail?.detail ?? "Request failed")
        case 500..<600:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.unexpected(httpResponse.statusCode)
        }
    }

    private struct ErrorDetail: Codable {
        let detail: String
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case rateLimited(String)
    case clientError(Int, String)
    case serverError(Int)
    case unexpected(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .unauthorized: return "Please sign in again"
        case .rateLimited(let msg): return msg
        case .clientError(_, let msg): return msg
        case .serverError(let code): return "Server error (\(code)). Try again later."
        case .unexpected(let code): return "Unexpected error (\(code))"
        }
    }
}
