import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    let title = "Home"

    private var progressionService: (any ProgressionServicing)?

    private(set) var totalXP = 0
    private(set) var currentLevel = 1
    private(set) var coins = 0
    private(set) var lifetimeCoins = 0
    private(set) var xpProgress = XPProgress(currentXP: 0, requiredXP: 150)
    private(set) var errorMessage: String?

    func configure(progressionService: any ProgressionServicing) {
        self.progressionService = progressionService
        loadStats()
    }

    func loadStats() {
        guard let progressionService else {
            return
        }

        do {
            let stats = try progressionService.currentStats()
            totalXP = stats.totalXP
            currentLevel = stats.currentLevel
            coins = stats.coins
            lifetimeCoins = stats.lifetimeCoins
            xpProgress = progressionService.xpProgressForCurrentLevel(totalXP: stats.totalXP)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
