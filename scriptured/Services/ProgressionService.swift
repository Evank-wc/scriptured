import Foundation
import SwiftData

@MainActor
protocol ProgressionServicing {
    func currentStats() throws -> UserStats
    func addXP(amount: Int) throws -> LevelUpResult
    func addCoins(amount: Int) throws
    func calculateLevelFromXP(_ totalXP: Int) -> Int
    func calculateXPRequiredForNextLevel(level: Int) -> Int
    func detectLevelUp(previousLevel: Int, newLevel: Int) -> Bool
    func grantLevelUpReward(for level: Int) throws
    func xpProgressForCurrentLevel(totalXP: Int) -> XPProgress
    func chapterCompletionRewardKey(language: BibleLanguage, bookAbbrev: String, chapterIndex: Int) -> String
    func hasClaimedReward(rewardKey: String) throws -> Bool
    func claimChapterCompletionReward(
        language: BibleLanguage,
        bookAbbrev: String,
        chapterIndex: Int,
        xpAwarded: Int,
        coinsAwarded: Int
    ) throws -> RewardClaimResult
}

struct LevelUpResult {
    let previousLevel: Int
    let currentLevel: Int
    let didLevelUp: Bool
}

struct RewardClaimResult {
    let rewardKey: String
    let didAwardRewards: Bool
    let xpAwarded: Int
    let coinsAwarded: Int
    let levelUpResult: LevelUpResult?
}

struct XPProgress {
    let currentXP: Int
    let requiredXP: Int

    var fraction: Double {
        guard requiredXP > 0 else {
            return 0
        }

        return min(Double(currentXP) / Double(requiredXP), 1)
    }
}

@MainActor
struct ProgressionService: ProgressionServicing {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func currentStats() throws -> UserStats {
        var descriptor = FetchDescriptor<UserStats>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        if let stats = try modelContext.fetch(descriptor).first {
            return stats
        }

        let stats = UserStats()
        modelContext.insert(stats)
        try modelContext.save()
        return stats
    }

    func addXP(amount: Int) throws -> LevelUpResult {
        guard amount > 0 else {
            let stats = try currentStats()
            return LevelUpResult(
                previousLevel: stats.currentLevel,
                currentLevel: stats.currentLevel,
                didLevelUp: false
            )
        }

        let stats = try currentStats()
        let previousLevel = stats.currentLevel
        stats.totalXP += amount
        stats.currentLevel = calculateLevelFromXP(stats.totalXP)
        stats.lastUpdated = .now

        if detectLevelUp(previousLevel: previousLevel, newLevel: stats.currentLevel) {
            try grantLevelUpReward(for: stats.currentLevel)
        }

        try modelContext.save()

        return LevelUpResult(
            previousLevel: previousLevel,
            currentLevel: stats.currentLevel,
            didLevelUp: detectLevelUp(previousLevel: previousLevel, newLevel: stats.currentLevel)
        )
    }

    func addCoins(amount: Int) throws {
        guard amount > 0 else {
            return
        }

        let stats = try currentStats()
        stats.coins += amount
        stats.lifetimeCoins += amount
        stats.lastUpdated = .now
        try modelContext.save()
    }

    func calculateLevelFromXP(_ totalXP: Int) -> Int {
        var level = 1
        var remainingXP = max(totalXP, 0)

        while remainingXP >= calculateXPRequiredForNextLevel(level: level) {
            remainingXP -= calculateXPRequiredForNextLevel(level: level)
            level += 1
        }

        return level
    }

    func calculateXPRequiredForNextLevel(level: Int) -> Int {
        100 + max(level, 1) * 50
    }

    func detectLevelUp(previousLevel: Int, newLevel: Int) -> Bool {
        newLevel > previousLevel
    }

    func grantLevelUpReward(for level: Int) throws {
        let stats = try currentStats()
        let reward = 100
        stats.coins += reward
        stats.lifetimeCoins += reward
        stats.lastUpdated = .now
    }

    func xpProgressForCurrentLevel(totalXP: Int) -> XPProgress {
        var level = 1
        var remainingXP = max(totalXP, 0)
        var requiredXP = calculateXPRequiredForNextLevel(level: level)

        while remainingXP >= requiredXP {
            remainingXP -= requiredXP
            level += 1
            requiredXP = calculateXPRequiredForNextLevel(level: level)
        }

        return XPProgress(currentXP: remainingXP, requiredXP: requiredXP)
    }

    func chapterCompletionRewardKey(
        language: BibleLanguage,
        bookAbbrev: String,
        chapterIndex: Int
    ) -> String {
        "chapter:\(language.version.languageCode):\(bookAbbrev):\(chapterIndex)"
    }

    func hasClaimedReward(rewardKey: String) throws -> Bool {
        try rewardTransaction(for: rewardKey) != nil
    }

    func claimChapterCompletionReward(
        language: BibleLanguage,
        bookAbbrev: String,
        chapterIndex: Int,
        xpAwarded: Int,
        coinsAwarded: Int
    ) throws -> RewardClaimResult {
        let rewardKey = chapterCompletionRewardKey(
            language: language,
            bookAbbrev: bookAbbrev,
            chapterIndex: chapterIndex
        )

        if try hasClaimedReward(rewardKey: rewardKey) {
            return RewardClaimResult(
                rewardKey: rewardKey,
                didAwardRewards: false,
                xpAwarded: 0,
                coinsAwarded: 0,
                levelUpResult: nil
            )
        }

        let stats = try currentStats()
        let previousLevel = stats.currentLevel
        stats.totalXP += max(xpAwarded, 0)
        stats.currentLevel = calculateLevelFromXP(stats.totalXP)
        stats.coins += max(coinsAwarded, 0)
        stats.lifetimeCoins += max(coinsAwarded, 0)
        stats.lastUpdated = .now

        if detectLevelUp(previousLevel: previousLevel, newLevel: stats.currentLevel) {
            try grantLevelUpReward(for: stats.currentLevel)
        }

        let transaction = RewardTransaction(
            rewardKey: rewardKey,
            rewardType: "chapterCompletion",
            xpAwarded: max(xpAwarded, 0),
            coinsAwarded: max(coinsAwarded, 0)
        )
        modelContext.insert(transaction)
        try modelContext.save()

        let levelUpResult = LevelUpResult(
            previousLevel: previousLevel,
            currentLevel: stats.currentLevel,
            didLevelUp: detectLevelUp(previousLevel: previousLevel, newLevel: stats.currentLevel)
        )

        return RewardClaimResult(
            rewardKey: rewardKey,
            didAwardRewards: true,
            xpAwarded: max(xpAwarded, 0),
            coinsAwarded: max(coinsAwarded, 0),
            levelUpResult: levelUpResult
        )
    }

    private func rewardTransaction(for rewardKey: String) throws -> RewardTransaction? {
        var descriptor = FetchDescriptor<RewardTransaction>(
            predicate: #Predicate { transaction in
                transaction.rewardKey == rewardKey
            }
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).first
    }
}
