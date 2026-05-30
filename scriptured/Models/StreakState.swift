import Foundation
import SwiftData

@Model
final class StreakState {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var streakFreezesAvailable: Int
    var consumedFreezeDates: [Date]
    var lastEvaluatedAt: Date

    init(
        id: UUID = UUID(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        streakFreezesAvailable: Int = 0,
        consumedFreezeDates: [Date] = [],
        lastEvaluatedAt: Date = .now
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakFreezesAvailable = streakFreezesAvailable
        self.consumedFreezeDates = consumedFreezeDates
        self.lastEvaluatedAt = lastEvaluatedAt
    }
}
