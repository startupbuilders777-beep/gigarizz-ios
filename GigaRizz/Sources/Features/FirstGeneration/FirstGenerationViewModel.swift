import SwiftUI

// MARK: - First Generation ViewModel

@MainActor
final class FirstGenerationViewModel: ObservableObject {
    @Published var currentStep: Step = .welcome
    @Published var selectedStyle: StylePreset?

    enum Step: Int, CaseIterable {
        case welcome = 1
        case photoTips = 2
        case styleSelection = 3
        case generating = 4
    }

    func advanceStep() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else {
            // Finished - would trigger actual generation
            return
        }
        currentStep = next
    }

    func goBack() {
        guard let previous = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previous
    }
}
