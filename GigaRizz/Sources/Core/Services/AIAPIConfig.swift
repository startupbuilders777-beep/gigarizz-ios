import Foundation

/// Centralized AI API configuration and rate limits.
struct AIAPIConfig {
    // MARK: - Generation Limits

    /// Free tier daily generation limit
    static let freeGenerationsPerDay = 5

    /// Pro tier daily generation limit
    static let proGenerationsPerDay = 50

    // MARK: - API Configuration

    /// Default AI model for photo generation
    static let defaultModel = "photo-generator-v1"

    /// API timeout in seconds
    static let apiTimeoutSeconds = 60

    /// Maximum retry attempts
    static let maxRetryAttempts = 3

    // MARK: - Endpoints (placeholder for Firebase config)

    /// Cloud Functions endpoint base URL
    static var cloudFunctionsBaseURL: String {
        // In production, fetch from Firebase Remote Config
        return "https://api.gigarizz.com"
    }

    // MARK: - Feature Flags

    /// Enable background replacement feature
    static let enableBackgroundReplacement: Bool = true

    /// Enable face enhancement feature
    static let enableFaceEnhancement: Bool = true

    /// Enable style presets
    static let enableStylePresets: Bool = true
}