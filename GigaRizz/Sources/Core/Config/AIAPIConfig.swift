import Foundation

/// Configuration for AI API limits and pricing.
enum AIAPIConfig {
    /// Free tier generations per day.
    static let freeGenerationsPerDay: Int = 3
    
    /// Pro tier generations per day.
    static let proGenerationsPerDay: Int = 50
    
    /// Cooldown between generations in seconds.
    static let generationCooldownSeconds: TimeInterval = 30
    
    /// Maximum photos per batch.
    static let maxPhotosPerBatch: Int = 4
    
    /// API timeout in seconds.
    static let apiTimeoutSeconds: TimeInterval = 60
    
    /// OpenAI model for photo generation.
    static let generationModel: String = "gpt-4-vision-preview"
    
    /// OpenAI model for coach suggestions.
    static let coachModel: String = "gpt-4-turbo"
}