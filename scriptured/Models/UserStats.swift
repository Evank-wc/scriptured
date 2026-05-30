import Foundation
import SwiftData

@Model
final class UserStats {
    var id: UUID
    var totalXP: Int
    var currentLevel: Int
    var coins: Int
    var lifetimeCoins: Int
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        totalXP: Int = 0,
        currentLevel: Int = 1,
        coins: Int = 0,
        lifetimeCoins: Int = 0,
        lastUpdated: Date = .now
    ) {
        self.id = id
        self.totalXP = totalXP
        self.currentLevel = currentLevel
        self.coins = coins
        self.lifetimeCoins = lifetimeCoins
        self.lastUpdated = lastUpdated
    }
}
