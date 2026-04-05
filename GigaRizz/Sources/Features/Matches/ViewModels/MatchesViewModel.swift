import Foundation
import SwiftUI

@MainActor
final class MatchesViewModel: ObservableObject {
    #if DEBUG
    @Published var matches: [Match] = Match.demoMatches
    #else
    @Published var matches: [Match] = []
    #endif

    var activeCount: Int { matches.filter { $0.status == .active }.count }
    var staleCount: Int { matches.filter { $0.status == .stale || $0.isStale }.count }
    var scheduledCount: Int { matches.filter { $0.status == .dateScheduled }.count }

    func addMatch(_ match: Match) {
        matches.insert(match, at: 0)
        DesignSystem.Haptics.success()
    }

    func updateMatch(_ match: Match) {
        if let index = matches.firstIndex(where: { $0.id == match.id }) { matches[index] = match }
    }

    func deleteMatch(_ match: Match) {
        matches.removeAll { $0.id == match.id }
        DesignSystem.Haptics.medium()
    }

    func updateStatus(_ match: Match, to status: MatchStatus) {
        if let index = matches.firstIndex(where: { $0.id == match.id }) {
            matches[index].status = status
            DesignSystem.Haptics.light()
        }
    }
}
