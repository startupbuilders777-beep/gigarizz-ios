import Foundation

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var selectedTone: CoachService.BioTone = .witty
    @Published var selectedPlatform: DatingPlatform = .tinder
    @Published var matchName = ""
    @Published var generatedBio: String?
    @Published var openingLines: [String] = []
    @Published var hingePrompts: [(prompt: String, answer: String)] = []
    @Published var isGeneratingBio = false
    @Published var isGeneratingLines = false
    @Published var isGeneratingPrompts = false
    @Published var copiedBio = false

    private let coachService = CoachService.shared

    func generateBio() async {
        isGeneratingBio = true
        defer { isGeneratingBio = false }
        do {
            generatedBio = try await coachService.generateBio(interests: [], tone: selectedTone, platform: selectedPlatform)
        } catch { generatedBio = nil }
    }

    func generateOpeningLines() async {
        isGeneratingLines = true
        defer { isGeneratingLines = false }
        do {
            openingLines = try await coachService.generateOpeningLines(matchName: matchName.isEmpty ? "there" : matchName, platform: selectedPlatform)
        } catch { openingLines = [] }
    }

    func generateHingePrompts() async {
        isGeneratingPrompts = true
        defer { isGeneratingPrompts = false }
        do {
            hingePrompts = try await coachService.generateHingePrompts()
        } catch { hingePrompts = [] }
    }
}
