import Foundation

// MARK: - AI API Configuration

/// Configuration constants for AI API usage limits.
enum AIAPIConfig {
    /// Free tier daily generation limit.
    static let freeGenerationsPerDay: Int = 5
    
    /// Pro tier daily generation limit.
    static let proGenerationsPerDay: Int = 50
    
    /// Gold tier daily generation limit (unlimited).
    static let goldGenerationsPerDay: Int = 999
    
    /// Default cooldown between generations (seconds).
    static let generationCooldownSeconds: Int = 10
    
    /// API timeout in seconds.
    static let apiTimeoutSeconds: Int = 30
}
