import Foundation
import UIKit

enum AIAPIConfig {
    static let replicateBaseURL = "https://api.replicate.com/v1"
    static var apiKey: String { ProcessInfo.processInfo.environment["REPLICATE_API_KEY"] ?? "" }
    static let modelVersion = "stability-ai/sdxl:7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc"
    static let freeGenerationsPerDay = 3
    static let proGenerationsPerDay = 50
    static let maxSourceImages = 10
    static let minSourceImages = 3
}

@MainActor
final class AIGenerationService: ObservableObject {
    static let shared = AIGenerationService()

    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var errorMessage: String?
    @Published private(set) var dailyGenerationsUsed: Int = 0

    private let urlSession: URLSession
    private let rateLimiter: RateLimiter

    struct GenerationResult {
        let photos: [GeneratedPhoto]
        let style: String
        let processingTime: TimeInterval
    }

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: config)
        self.rateLimiter = RateLimiter()
        self.dailyGenerationsUsed = rateLimiter.todayCount(for: "photo_generation")
    }

    func generatePhotos(sourceImages: [UIImage], style: StylePreset, userId: String, count: Int = 4) async throws -> GenerationResult {
        guard !sourceImages.isEmpty else { throw GenerationError.noSourceImages }
        guard sourceImages.count >= AIAPIConfig.minSourceImages else {
            throw GenerationError.insufficientPhotos(minimum: AIAPIConfig.minSourceImages, provided: sourceImages.count)
        }
        let isPro = SubscriptionManager.shared.isSubscribed
        let limit = isPro ? AIAPIConfig.proGenerationsPerDay : AIAPIConfig.freeGenerationsPerDay
        guard rateLimiter.canPerform("photo_generation", limit: limit) else { throw GenerationError.quotaExceeded }

        isGenerating = true; generationProgress = 0; errorMessage = nil
        let startTime = Date()
        do {
            let photos: [GeneratedPhoto]
            if !AIAPIConfig.apiKey.isEmpty {
                photos = try await generateWithReplicateAPI(sourceImages: sourceImages, style: style, userId: userId, count: count)
            } else {
                photos = try await simulateGeneration(sourceImages: sourceImages, style: style, userId: userId, count: count)
            }
            let processingTime = Date().timeIntervalSince(startTime)
            rateLimiter.recordUsage("photo_generation")
            dailyGenerationsUsed = rateLimiter.todayCount(for: "photo_generation")
            PostHogManager.shared.trackPhotoGenerated(style: style.name, tier: isPro ? "pro" : "free", photoCount: photos.count)
            AppRatingManager.shared.trackPhotoGenerated()
            isGenerating = false; generationProgress = 1.0
            DesignSystem.Haptics.success()
            return GenerationResult(photos: photos, style: style.name, processingTime: processingTime)
        } catch is CancellationError { isGenerating = false; throw GenerationError.cancelled } catch { isGenerating = false; errorMessage = error.localizedDescription; DesignSystem.Haptics.error(); throw error }
    }

    private func generateWithReplicateAPI(sourceImages: [UIImage], style: StylePreset, userId: String, count: Int) async throws -> [GeneratedPhoto] {
        generationProgress = 0.05
        let base64Images = sourceImages.prefix(6).compactMap { $0.jpegData(compressionQuality: 0.85)?.base64EncodedString() }
        generationProgress = 0.15
        guard !base64Images.isEmpty else { throw GenerationError.apiError("Failed to encode source images") }
        generationProgress = 0.2
        let prediction = try await createPrediction(prompt: style.aiPrompt, negativePrompt: "blurry, low quality, distorted face, extra limbs, deformed, ugly, bad anatomy", imageData: base64Images.first, count: count)
        generationProgress = 0.3
        let outputs = try await pollPrediction(id: prediction.id, startProgress: 0.3, endProgress: 0.9)
        generationProgress = 0.95
        var photos: [GeneratedPhoto] = []
        for urlString in outputs { photos.append(GeneratedPhoto(userId: userId, style: style.name, imageURL: URL(string: urlString), createdAt: Date())) }
        generationProgress = 1.0
        return photos
    }

    private struct ReplicatePrediction: Codable { let id: String; let status: String; let output: [String]?; let error: String? }

    private func createPrediction(prompt: String, negativePrompt: String, imageData: String?, count: Int) async throws -> ReplicatePrediction {
        var request = URLRequest(url: URL(string: "\(AIAPIConfig.replicateBaseURL)/predictions")!)
        request.httpMethod = "POST"
        request.setValue("Token \(AIAPIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var input: [String: Any] = ["prompt": prompt, "negative_prompt": negativePrompt, "num_outputs": min(count, 4), "width": 1024, "height": 1024, "num_inference_steps": 30, "guidance_scale": 7.5, "scheduler": "K_EULER"]
        if let imageData = imageData { input["image"] = "data:image/jpeg;base64,\(imageData)" }
        let body: [String: Any] = ["version": AIAPIConfig.modelVersion.components(separatedBy: ":").last ?? "", "input": input]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw GenerationError.apiError("Invalid response") }
        if httpResponse.statusCode == 429 { throw GenerationError.apiError("API rate limited. Please try again in a minute.") }
        guard (200...299).contains(httpResponse.statusCode) else { throw GenerationError.apiError("API error (\(httpResponse.statusCode))") }
        return try JSONDecoder().decode(ReplicatePrediction.self, from: data)
    }

    private func pollPrediction(id: String, startProgress: Double, endProgress: Double) async throws -> [String] {
        let url = URL(string: "\(AIAPIConfig.replicateBaseURL)/predictions/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Token \(AIAPIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        let maxAttempts = 60
        for attempt in 0..<maxAttempts {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            generationProgress = startProgress + (endProgress - startProgress) * min(Double(attempt) / 30.0, 0.95)
            let (data, _) = try await urlSession.data(for: request)
            let prediction = try JSONDecoder().decode(ReplicatePrediction.self, from: data)
            switch prediction.status {
            case "succeeded": return prediction.output ?? []
            case "failed": throw GenerationError.apiError(prediction.error ?? "Generation failed")
            case "canceled": throw GenerationError.cancelled
            default: continue
            }
        }
        throw GenerationError.apiError("Generation timed out after 5 minutes")
    }

    private func simulateGeneration(sourceImages: [UIImage], style: StylePreset, userId: String, count: Int) async throws -> [GeneratedPhoto] {
        for step in 1...5 { try await Task.sleep(nanoseconds: 300_000_000); generationProgress = Double(step) * 0.05 }
        for step in 1...5 { try await Task.sleep(nanoseconds: 400_000_000); generationProgress = 0.25 + Double(step) * 0.05 }
        var photos: [GeneratedPhoto] = []
        for i in 0..<count {
            try await Task.sleep(nanoseconds: 500_000_000)
            generationProgress = 0.5 + (Double(i + 1) / Double(count)) * 0.4
            photos.append(GeneratedPhoto(userId: userId, style: style.name, createdAt: Date()))
        }
        try await Task.sleep(nanoseconds: 300_000_000); generationProgress = 1.0
        return photos
    }

    func cancelGeneration() { isGenerating = false; generationProgress = 0 }
    var remainingGenerations: Int { max(0, (SubscriptionManager.shared.isSubscribed ? AIAPIConfig.proGenerationsPerDay : AIAPIConfig.freeGenerationsPerDay) - dailyGenerationsUsed) }
}

extension StylePreset {
    var aiPrompt: String {
        switch name {
        case "Professional": return "professional headshot, studio lighting, clean background, sharp focus, business attire, confident expression, shot on Canon R5, 85mm f/1.4"
        case "Casual": return "casual lifestyle photo, natural lighting, coffee shop vibes, relaxed smile, candid feel, warm tones, shot on iPhone 15"
        case "Adventure": return "adventurous outdoor photo, golden hour, mountain or beach backdrop, active lifestyle, natural expression, vibrant colors"
        case "Night Out": return "stylish night out photo, city lights background, well-dressed, confident pose, moody lighting, premium feel"
        case "Fitness": return "fitness lifestyle photo, athletic wear, gym or outdoor setting, strong physique showcase, motivational energy, natural sunlight"
        case "Artistic": return "artistic portrait, creative lighting, unique angles, editorial style, fashion-forward, museum or gallery setting"
        default: return "high quality portrait photo, natural lighting, flattering angle, sharp focus, attractive person, dating app style"
        }
    }
}

enum GenerationError: LocalizedError {
    case noSourceImages, insufficientPhotos(minimum: Int, provided: Int), apiError(String), cancelled, quotaExceeded
    var errorDescription: String? {
        switch self {
        case .noSourceImages: return "No source photos provided. Please upload at least 3 photos."
        case .insufficientPhotos(let min, let provided): return "Need at least \(min) photos, but only \(provided) provided."
        case .apiError(let message): return "Generation failed: \(message)"
        case .cancelled: return "Generation was cancelled."
        case .quotaExceeded: return "You\u{2019}ve reached your daily photo limit. Upgrade to generate more!"
        }
    }
}
