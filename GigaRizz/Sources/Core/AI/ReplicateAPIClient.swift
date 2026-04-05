import Foundation

// MARK: - Replicate API Client

/// Client for direct Replicate API integration.
/// Handles image-to-image generation with face consistency.
actor ReplicateAPIClient {
    // MARK: - Singleton

    static let shared = ReplicateAPIClient()

    // MARK: - Constants

    private let baseURL = URL(string: "https://api.replicate.com")!
    private let maxRetries = 3
    private let timeoutSeconds: TimeInterval = 120

    // MARK: - Replicate API Token

    /// Replicate API token — set from AppConstants or environment.
    private var apiToken: String {
        // In production this should come from a secure source (backend, env var, etc.)
        // For now, we use the backend as proxy (see GigaRizzAPIClient).
        // This client is available for direct Replicate calls when needed.
        AppConstants.replicateAPIToken
    }

    // MARK: - Prediction Lifecycle

    /// Create a new prediction for img2img generation.
    func createPrediction(
        sourceImageURL: URL,
        prompt: String,
        styleParameters: StyleParameters,
        aspectRatio: AspectRatio,
        model: String = "pfpotex/floral-uxl:v1"
    ) async throws -> ReplicateAPIResponse {
        let url = baseURL.appendingPathComponent("v1/predictions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let input: [String: Any] = [
            "image": sourceImageURL.absoluteString,
            "prompt": buildPrompt(from: prompt, parameters: styleParameters),
            "strength": 0.65,
            "guidance_scale": 7.5,
            "num_inference_steps": 25,
            "aspect_ratio": aspectRatio.rawValue,
            "seed": Int.random(in: 1...Int.max),
            "enhance_face": true,
            "preserve_original_pose": true,
            "preserve_original_expression": styleParameters.preserveExpression
        ]

        let body: [String: Any] = [
            "version": "version-id-placeholder",
            "input": input
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReplicateError.invalidResponse
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ReplicateError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let prediction = try JSONDecoder().decode(ReplicateAPIResponse.self, from: data)
        return prediction
    }

    /// Poll for prediction status until completion.
    func pollPrediction(id: String, maxAttempts: Int = 120) async throws -> ReplicateAPIResponse {
        let url = baseURL.appendingPathComponent("v1/predictions/\(id)")

        var request = URLRequest(url: url)
        request.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")

        for attempt in 1...maxAttempts {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw ReplicateError.invalidResponse
            }

            let prediction = try JSONDecoder().decode(ReplicateAPIResponse.self, from: data)

            if prediction.isCompleted {
                return prediction
            } else if prediction.isFailed {
                throw ReplicateError.predictionFailed(prediction.error ?? "Unknown error")
            }

            // Wait before next poll (exponential backoff: 1s, 2s, 3s...)
            let delay = min(Double(attempt) * 0.5, 5.0)
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        throw ReplicateError.timeout
    }

    /// Cancel an in-flight prediction.
    func cancelPrediction(id: String) async throws {
        let url = baseURL.appendingPathComponent("v1/predictions/\(id)/cancel")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw ReplicateError.cancelFailed
        }
    }

    /// Stream prediction logs (for real-time progress).
    func streamPredictionLogs(id: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let url = baseURL.appendingPathComponent("v1/predictions/\(id)/logs")

                var request = URLRequest(url: url)
                request.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")

                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: ReplicateError.invalidResponse)
                        return
                    }

                    for try await line in bytes.lines {
                        continuation.yield(line)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Batch Generation

    /// Configuration for batch generation.
    struct BatchConfig {
        let sourceImageURLs: [URL]
        let primarySourceURL: URL
        let prompt: String
        let parameters: StyleParameters
        let aspectRatios: [AspectRatio]
        let photoCount: Int
    }

    /// Generate photos across multiple aspect ratios.
    func generateBatch(
        config: BatchConfig,
        progressHandler: @escaping (Double) async -> Void
    ) async throws -> [URL] {
        var outputURLs: [URL] = []

        let totalJobs = config.aspectRatios.count * config.photoCount
        var completedJobs = 0

        for ratio in config.aspectRatios {
            for _ in 0..<config.photoCount {
                // Create prediction
                let prediction = try await createPrediction(
                    sourceImageURL: config.primarySourceURL,
                    prompt: config.prompt,
                    styleParameters: config.parameters,
                    aspectRatio: ratio
                )

                guard let predictionId = extractPredictionId(from: prediction) else {
                    throw ReplicateError.noPredictionId
                }

                // Poll for completion
                let result = try await pollPrediction(id: predictionId)

                // Extract output URLs
                if let output = result.output,
                   let images = output.images {
                    outputURLs.append(contentsOf: images.compactMap { URL(string: $0) })
                }

                completedJobs += 1
                await progressHandler(Double(completedJobs) / Double(totalJobs))
            }
        }

        return outputURLs
    }

    // MARK: - Helpers

    private func buildPrompt(from base: String, parameters: StyleParameters) -> String {
        var components: [String] = [base]

        // Add lighting
        components.append("lighting: \(parameters.lighting)")

        // Add background
        components.append("background: \(parameters.background)")

        // Add face enhancement
        if parameters.faceEnhancement == "strong" {
            components.append("face enhancement, high detail facial features")
        }

        // Color tone
        components.append("color tone: \(parameters.colorTone)")

        // Quality
        components.append("8k, professional photography, sharp focus")

        return components.joined(separator: ", ")
    }

    private func extractPredictionId(from response: ReplicateAPIResponse) -> String? {
        // Extract ID from the get URL or directly from id field
        response.id.isEmpty ? nil : response.id
    }
}

// MARK: - Replicate Error

enum ReplicateError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case predictionFailed(String)
    case timeout
    case cancelFailed
    case noPredictionId

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Replicate API."
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .predictionFailed(let reason):
            return "Prediction failed: \(reason)"
        case .timeout:
            return "Generation timed out after 2 minutes."
        case .cancelFailed:
            return "Failed to cancel generation."
        case .noPredictionId:
            return "No prediction ID returned from Replicate."
        }
    }
}

// MARK: - AppConstants Extension

extension AppConstants {
    /// Replicate API token for direct Replicate integration.
    /// In production, this should come from backend or secure storage.
    static let replicateAPIToken: String = {
        // Placeholder — replace with actual token from environment or backend
        // Never commit real tokens to source control
        "r8_REPLACE_WITH_YOUR_REPLICATE_TOKEN"
    }()
}
