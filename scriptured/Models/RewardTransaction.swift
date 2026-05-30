import Foundation
import SwiftData

@Model
final class RewardTransaction {
    var id: UUID
    var rewardKey: String
    var rewardType: String
    var xpAwarded: Int
    var coinsAwarded: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        rewardKey: String,
        rewardType: String,
        xpAwarded: Int,
        coinsAwarded: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.rewardKey = rewardKey
        self.rewardType = rewardType
        self.xpAwarded = xpAwarded
        self.coinsAwarded = coinsAwarded
        self.createdAt = createdAt
    }
}
