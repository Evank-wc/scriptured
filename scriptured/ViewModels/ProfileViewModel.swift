import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    let title = "Profile"

    private var progressionService: (any ProgressionServicing)?

    private(set) var testCoinMessage: String?

    func configure(progressionService: any ProgressionServicing) {
        self.progressionService = progressionService
    }

    func grantTestingCoins() {
        guard let progressionService else {
            testCoinMessage = "Progression service is not ready."
            return
        }

        do {
            try progressionService.addCoins(amount: 1000)
            testCoinMessage = "+1000 coins added for testing."
            ReadingActivitySignal.send()
        } catch {
            testCoinMessage = error.localizedDescription
        }
    }
}
