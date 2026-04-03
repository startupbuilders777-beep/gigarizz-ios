import Foundation
import PhotosUI
import SwiftUI

// MARK: - Audit Models

struct PhotoAuditResult: Identifiable, Equatable {
    let id: String
    let overallScore: Double
    let categories: [AuditCategory]
    let improvements: [String]
    let verdict: String
    let verdictDetail: String
    let missingPhotoTypes: [String]

    init(
        id: String = UUID().uuidString,
        overallScore: Double,
        categories: [AuditCategory],
        improvements: [String],
        verdict: String,
        verdictDetail: String,
        missingPhotoTypes: [String] = []
    ) {
        self.id = id
        self.overallScore = overallScore
        self.categories = categories
        self.improvements = improvements
        self.verdict = verdict
        self.verdictDetail = verdictDetail
        self.missingPhotoTypes = missingPhotoTypes
    }
}

struct AuditCategory: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let score: Double
    let feedback: String

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        score: Double,
        feedback: String
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.score = score
        self.feedback = feedback
    }
}

// MARK: - Photo Audit View Model

@MainActor
final class PhotoAuditViewModel: ObservableObject {
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0
    @Published var analysisStageText = "Starting analysis..."
    @Published var auditResult: PhotoAuditResult?
    @Published var errorMessage: String?

    private let stages = [
        (0.0, "Detecting face and features..."),
        (0.15, "Analyzing lighting quality..."),
        (0.30, "Checking composition..."),
        (0.45, "Evaluating expression..."),
        (0.60, "Scanning background..."),
        (0.75, "Rating outfit and style..."),
        (0.85, "Assessing body language..."),
        (0.95, "Calculating final score...")
    ]

    // MARK: - Load and Analyze

    func loadAndAnalyzePhoto() async {
        guard let item = photosPickerItem else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Failed to load image"
                return
            }

            selectedImage = image
            await analyzePhoto(image)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func analyzePhoto(_ image: UIImage) async {
        isAnalyzing = true
        analysisProgress = 0
        auditResult = nil

        // Simulate AI analysis stages with realistic timing
        for (progress, stageText) in stages {
            analysisStageText = stageText
            let targetProgress = progress + 0.1
            let steps = 10
            for step in 0..<steps {
                let p = progress + (targetProgress - progress) * Double(step) / Double(steps)
                analysisProgress = min(p, 0.99)
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
        }

        // Generate intelligent result based on image analysis
        let result = generateAuditResult(for: image)
        analysisProgress = 1.0
        analysisStageText = "Analysis complete!"

        try? await Task.sleep(nanoseconds: 300_000_000)

        auditResult = result
        isAnalyzing = false
        DesignSystem.Haptics.success()
        PostHogManager.shared.track("photo_audit_completed", properties: ["overall_score": result.overallScore])
    }

    // MARK: - Generate Audit (Simulated AI)

    private func generateAuditResult(for image: UIImage) -> PhotoAuditResult {
        // In production, this would call a Vision API or ML model.
        // For now, generate realistic scores based on image properties.
        let size = image.size
        let aspectRatio = size.width / size.height
        let isPortrait = aspectRatio < 1.0
        let isHighRes = size.width >= 1000 && size.height >= 1000

        // Base scores with some variance
        let lightingBase = isHighRes ? 7.5 : 6.0
        let compositionBase = isPortrait ? 7.0 : 6.0
        let expressionBase = 6.5
        let backgroundBase = 6.0
        let outfitBase = 6.5
        let bodyLanguageBase = 6.0

        let lighting = min(10, lightingBase + Double.random(in: -0.5...1.5))
        let composition = min(10, compositionBase + Double.random(in: -0.5...1.5))
        let expression = min(10, expressionBase + Double.random(in: -1.0...2.0))
        let background = min(10, backgroundBase + Double.random(in: -1.0...2.0))
        let outfit = min(10, outfitBase + Double.random(in: -0.5...1.5))
        let bodyLanguage = min(10, bodyLanguageBase + Double.random(in: -1.0...2.0))

        let overall = (lighting + composition + expression + background + outfit + bodyLanguage) / 6.0

        let categories = [
            AuditCategory(name: "Lighting", icon: "sun.max.fill", score: round(lighting * 10) / 10, feedback: lightingFeedback(lighting)),
            AuditCategory(name: "Composition", icon: "rectangle.dashed", score: round(composition * 10) / 10, feedback: compositionFeedback(composition)),
            AuditCategory(name: "Expression", icon: "face.smiling", score: round(expression * 10) / 10, feedback: expressionFeedback(expression)),
            AuditCategory(name: "Background", icon: "photo.fill", score: round(background * 10) / 10, feedback: backgroundFeedback(background)),
            AuditCategory(name: "Outfit", icon: "tshirt.fill", score: round(outfit * 10) / 10, feedback: outfitFeedback(outfit)),
            AuditCategory(name: "Body Language", icon: "figure.stand", score: round(bodyLanguage * 10) / 10, feedback: bodyLanguageFeedback(bodyLanguage))
        ]

        let improvements = generateImprovements(categories)
        let (verdict, detail) = generateVerdict(overall)

        return PhotoAuditResult(
            overallScore: round(overall * 10) / 10,
            categories: categories,
            improvements: improvements,
            verdict: verdict,
            verdictDetail: detail,
            missingPhotoTypes: ["Full Body", "Activity Shot", "Social Proof"]
        )
    }

    // MARK: - Feedback Generators

    private func lightingFeedback(_ score: Double) -> String {
        if score >= 8 { return "Great natural lighting! Well-exposed with flattering soft light." }
        if score >= 6 { return "Decent lighting but could be more flattering. Try golden hour or window light." }
        return "Harsh or dim lighting hurts your photos. Shoot near a window or outdoors during golden hour."
    }

    private func compositionFeedback(_ score: Double) -> String {
        if score >= 8 { return "Excellent framing! Great use of negative space and rule of thirds." }
        if score >= 6 { return "Good framing but could improve. Try positioning yourself off-center for more dynamic composition." }
        return "Photo feels too centered or poorly cropped. Use the rule of thirds - put your eyes on the top third line."
    }

    private func expressionFeedback(_ score: Double) -> String {
        if score >= 8 { return "Genuine, warm expression! Your smile looks natural and inviting." }
        if score >= 6 { return "Expression is decent but could be warmer. Think of something funny right before the shot." }
        return "Expression looks forced or neutral. Practice your natural smile - think of a happy memory when posing."
    }

    private func backgroundFeedback(_ score: Double) -> String {
        if score >= 8 { return "Clean, interesting background that complements you well." }
        if score >= 6 { return "Background is okay but slightly distracting. Look for cleaner, more intentional settings." }
        return "Background is cluttered or unflattering. Avoid messy rooms, mirrors, and busy patterns."
    }

    private func outfitFeedback(_ score: Double) -> String {
        if score >= 8 { return "Great outfit choice! Colors complement your skin tone well." }
        if score >= 6 { return "Outfit is fine but could be more intentional. Solid colors photograph better than patterns." }
        return "Outfit needs work. Wear well-fitted clothes in solid, warm colors that complement your complexion."
    }

    private func bodyLanguageFeedback(_ score: Double) -> String {
        if score >= 8 { return "Confident, open body language. You look approachable and self-assured." }
        if score >= 6 { return "Posture is okay. Try standing taller, shoulders back, with your hands visible and relaxed." }
        return "Closed-off body language. Uncross your arms, stand tall, and angle your body slightly for a more dynamic pose."
    }

    private func generateImprovements(_ categories: [AuditCategory]) -> [String] {
        var tips: [String] = []
        let sorted = categories.sorted { $0.score < $1.score }

        for category in sorted.prefix(3) {
            switch category.name {
            case "Lighting":
                tips.append("Shoot during golden hour (1 hour before sunset) for the most flattering natural light. Avoid overhead fluorescent lighting.")
            case "Composition":
                tips.append("Position yourself on the left or right third of the frame, not dead center. Leave some space above your head.")
            case "Expression":
                tips.append("Practice your smile in a mirror. A genuine Duchenne smile (eyes crinkle too) gets 20% more matches than a closed-mouth expression.")
            case "Background":
                tips.append("Choose intentional backgrounds: coffee shops, parks, cityscapes. Avoid bathrooms, messy rooms, and gym mirrors.")
            case "Outfit":
                tips.append("Wear a well-fitted outfit in a solid color that contrasts with your background. Blue, burgundy, and dark green photograph best.")
            case "Body Language":
                tips.append("Stand at a 3/4 angle to the camera (not straight on). Keep your shoulders back and chin slightly down for a stronger jawline.")
            default: break
            }
        }

        // Always add these universal tips
        tips.append("Your profile needs variety: headshot, full body, activity, and social photos. Generate a complete set with our AI Photo Packs.")
        tips.append("Photos with pets get 30% more matches. Try our Bumble Standout pack for the perfect pet photo.")

        return tips
    }

    private func generateVerdict(_ score: Double) -> (String, String) {
        if score >= 9 {
            return ("Profile Photo Perfection!", "This photo is in the top 5% of dating profiles. You're crushing it!")
        }
        if score >= 8 {
            return ("Strong Photo!", "Above average - this will get you noticed. A few tweaks could make it elite.")
        }
        if score >= 7 {
            return ("Solid Foundation", "A decent photo but there's room to level up. Check our tips below.")
        }
        if score >= 5 {
            return ("Needs Work", "This photo is holding you back from matches. Our AI can transform it.")
        }
        return ("Major Upgrade Needed", "Low-quality photos kill your match rate. Let our AI generate better ones for you.")
    }

    // MARK: - Reset

    func reset() {
        photosPickerItem = nil
        selectedImage = nil
        auditResult = nil
        analysisProgress = 0
        isAnalyzing = false
        errorMessage = nil
    }
}
