import Foundation

// MARK: - Generation State

/// Represents the current state of a generation job.
enum GenerationState: Equatable {
    case idle
    case uploading(progress: Double)
    case uploadingComplete
    case queued
    case generating(progress: Double)
    case downloading(progress: Double)
    case completed(photos: [GeneratedPhoto])
    case failed(reason: String)

    var isActive: Bool {
        switch self {
        case .idle, .completed, .failed:
            return false
        default:
            return true
        }
    }

    var overallProgress: Double {
        switch self {
        case .idle: return 0
        case .uploading(let p): return p * 0.3
        case .uploadingComplete: return 0.3
        case .queued: return 0.3
        case .generating(let p): return 0.3 + p * 0.5
        case .downloading(let p): return 0.8 + p * 0.2
        case .completed: return 1.0
        case .failed: return 0
        }
    }

    var stepDescription: String {
        switch self {
        case .idle: return "Ready"
        case .uploading: return "Uploading photos..."
        case .uploadingComplete: return "Upload complete"
        case .queued: return "AI is thinking..."
        case .generating: return "Creating your photos..."
        case .downloading: return "Downloading results..."
        case .completed: return "Done!"
        case .failed(let reason): return "Failed: \(reason)"
        }
    }
}

// MARK: - Generation Response

/// Result of a completed generation job.
struct GenerationResponse: Codable, Equatable {
    /// All generated photos across all aspect ratios.
    let photos: [GeneratedPhoto]

    /// Style used for generation.
    let styleUsed: String

    /// Total time for generation (seconds).
    let generationDuration: TimeInterval

    /// Request ID for tracking.
    let requestId: String

    /// Timestamps.
    let startedAt: Date
    let completedAt: Date

    init(
        photos: [GeneratedPhoto],
        styleUsed: String,
        generationDuration: TimeInterval,
        requestId: String
    ) {
        self.photos = photos
        self.styleUsed = styleUsed
        self.generationDuration = generationDuration
        self.requestId = requestId
        self.startedAt = Date()
        self.completedAt = Date()
    }
}

// MARK: - Upload Response

/// Response from uploading source photos to cloud storage.
struct UploadResponse: Codable {
    /// URLs for uploaded photos.
    let photoURLs: [String]

    /// Upload request ID.
    let requestId: String

    /// Whether upload succeeded.
    let success: Bool
}

// MARK: - Replicate API Response

/// Response from Replicate API prediction.
struct ReplicateAPIResponse: Codable {
    let id: String
    let status: String
    let output: ReplicateOutput?
    let error: String?
    let logs: String?
    let urls: ReplicateURLs?
    let createdAt: String?
    let completedAt: String?
    let metrics: ReplicateMetrics?

    struct ReplicateOutput: Codable {
        let images: [String]?       // URLs to generated images
        let seed: Int?
    }

    struct ReplicateURLs: Codable {
        let get: String?
        let cancel: String?
    }

    struct ReplicateMetrics: Codable {
        let predictTime: Double?
    }

    var isCompleted: Bool { status == "succeeded" }
    var isFailed: Bool { status == "failed" }
    var isProcessing: Bool { status == "starting" || status == "processing" }
}

// MARK: - Generation Job

/// Internal tracking for a generation job.
struct GenerationJob: Identifiable {
    let id: String
    let requestId: String
    let style: String
    var state: GenerationState
    var progress: Double
    var error: String?
    let createdAt: Date

    init(requestId: String, style: String) {
        self.id = UUID().uuidString
        self.requestId = requestId
        self.style = style
        self.state = .idle
        self.progress = 0
        self.error = nil
        self.createdAt = Date()
    }
}

// MARK: - Progress Update

/// Real-time progress update from generation pipeline.
struct ProgressUpdate: Equatable {
    let phase: ProgressPhase
    let progress: Double
    let message: String
    let estimatedSecondsRemaining: Int?

    enum ProgressPhase: String, Equatable {
        case uploading = "Uploading photos"
        case analyzing = "Analyzing faces"
        case generating = "Generating"
        case postProcessing = "Post-processing"
        case downloading = "Downloading"
        case complete = "Complete"
        case failed = "Failed"
    }

    static let uploading = ProgressUpdate(phase: .uploading, progress: 0, message: "Uploading photos...", estimatedSecondsRemaining: nil)
    static let analyzing = ProgressUpdate(phase: .analyzing, progress: 0, message: "Analyzing faces...", estimatedSecondsRemaining: nil)
    static let generating = { (p: Double) in
        ProgressUpdate(phase: .generating, progress: p, message: "Creating your photos...", estimatedSecondsRemaining: nil)
    }
    static let downloading = ProgressUpdate(phase: .downloading, progress: 0, message: "Downloading results...", estimatedSecondsRemaining: nil)
    static let complete = ProgressUpdate(phase: .complete, progress: 1, message: "Your photos are ready!", estimatedSecondsRemaining: 0)
}
