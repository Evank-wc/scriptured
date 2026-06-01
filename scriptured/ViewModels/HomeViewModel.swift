import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    let title = "Home"

    private var progressionService: (any ProgressionServicing)?
    private var streakService: (any StreakServicing)?
    private var readingProgressService: (any ReadingProgressServicing)?
    private var bibleService: (any BibleServicing)?
    private var readingPlanService: ReadingPlanService?
    private var shopService: ShopService?

    private(set) var totalXP = 0
    private(set) var currentLevel = 1
    private(set) var coins = 0
    private(set) var lifetimeCoins = 0
    private(set) var chaptersRead = 0
    private(set) var totalBibleChapters = 0
    private(set) var dailyGoalsCompleted = 0
    private(set) var todayPlanAssignment: ReadingPlanTodayAssignment?
    private(set) var planActionMessage: String?
    private(set) var boostActionMessage: String?
    private(set) var xpBoostInventoryQuantity = 0
    private(set) var availableXPBoosts: [ShopItem] = []
    private(set) var activeXPBoostMultiplier: Double?
    private(set) var activeXPBoostEndDate: Date?
    private(set) var xpProgress = XPProgress(currentXP: 0, requiredXP: 150)
    private(set) var streakStatus = StreakStatus(
        currentStreak: 0,
        longestStreak: 0,
        hasCompletedToday: false,
        isAtRisk: false,
        shouldConsumeFreeze: false,
        streakFreezesAvailable: 0
    )
    private(set) var errorMessage: String?

    var chapterProgressValue: String {
        guard totalBibleChapters > 0 else {
            return "\(chaptersRead)"
        }

        return "\(chaptersRead)/\(totalBibleChapters)"
    }

    var todayPlanProgressText: String {
        guard let todayPlanAssignment else {
            return "No active plan"
        }

        return "\(todayPlanAssignment.completedReadingKeys.count)/\(todayPlanAssignment.readings.count) readings"
    }

    var nextPlanReading: PlanReadingReference? {
        guard let todayPlanAssignment else {
            return nil
        }

        return todayPlanAssignment.readings.first {
            !todayPlanAssignment.completedReadingKeys.contains($0.readingKey)
        } ?? todayPlanAssignment.readings.first
    }

    var statusMessage: String {
        if streakStatus.hasCompletedToday {
            "Your streak is safe for today."
        } else if streakStatus.isAtRisk {
            "Your streak is at risk."
        } else {
            "Read now to protect your streak."
        }
    }

    var urgencyMessage: String {
        if streakStatus.hasCompletedToday {
            "Keep the chain alive tomorrow."
        } else if streakStatus.isAtRisk {
            "One chapter keeps the fire alive."
        } else {
            "Start today and make the first link count."
        }
    }

    var todayGoalTitle: String {
        if todayPlanAssignment?.isComplete == true {
            return "Plan goal complete"
        }
        return streakStatus.hasCompletedToday ? "Daily goal complete" : "Today’s reading goal"
    }

    var todayGoalMessage: String {
        if let todayPlanAssignment {
            if todayPlanAssignment.isComplete {
                return "You completed Day \(todayPlanAssignment.dayNumber) of \(todayPlanAssignment.plan.name)."
            }
            return "Complete today’s plan readings to earn the daily plan bonus."
        }

        return streakStatus.hasCompletedToday
            ? "Come back tomorrow to keep growing."
            : "Complete one chapter or plan part to secure today’s streak."
    }

    var todayGoalProgress: Double {
        if let todayPlanAssignment, !todayPlanAssignment.readings.isEmpty {
            return Double(todayPlanAssignment.completedReadingKeys.count) / Double(todayPlanAssignment.readings.count)
        }
        return streakStatus.hasCompletedToday ? 1 : 0
    }

    func configure(
        progressionService: any ProgressionServicing,
        streakService: any StreakServicing,
        readingProgressService: (any ReadingProgressServicing)? = nil,
        bibleService: (any BibleServicing)? = nil,
        readingPlanService: ReadingPlanService? = nil,
        shopService: ShopService? = nil
    ) {
        self.progressionService = progressionService
        self.streakService = streakService
        self.readingProgressService = readingProgressService
        self.bibleService = bibleService
        self.readingPlanService = readingPlanService
        self.shopService = shopService
        loadStats()
    }

    func completeTodayPlan() {
        guard let progressionService,
              let readingProgressService,
              let readingPlanService else {
            planActionMessage = "Plan progress tracking is not ready yet. Please try again."
            return
        }

        do {
            guard let result = try readingPlanService.markTodayComplete(
                progressionService: progressionService,
                readingProgressService: readingProgressService
            ) else {
                planActionMessage = "Select a plan to start tracking today’s reading."
                loadStats()
                return
            }

            if let rewardResult = result.rewardResult, rewardResult.didAwardRewards {
                planActionMessage = "Day \(result.dayNumber) complete: +\(rewardResult.xpAwarded) XP and +\(rewardResult.coinsAwarded) coins."
            } else {
                planActionMessage = "Day \(result.dayNumber) is already complete."
            }
            ReadingActivitySignal.send()
            loadStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func activateXPBoost(_ item: ShopItem) {
        guard let shopService else {
            boostActionMessage = "Shop inventory is not ready yet."
            return
        }

        do {
            let boost = try shopService.activateXPBoost(itemId: item.id)
            activeXPBoostMultiplier = boost.multiplier
            activeXPBoostEndDate = boost.endDate
            boostActionMessage = "XP boost active: \(multiplierText(boost.multiplier)) XP."
            ReadingActivitySignal.send()
            loadStats()
        } catch {
            boostActionMessage = error.localizedDescription
        }
    }

    func boostRemainingText(at date: Date = .now) -> String? {
        guard let activeXPBoostEndDate, activeXPBoostEndDate > date else {
            return nil
        }

        let remainingSeconds = Int(activeXPBoostEndDate.timeIntervalSince(date))
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func multiplierText(_ multiplier: Double) -> String {
        if multiplier.rounded(.down) == multiplier {
            return "\(Int(multiplier))x"
        }

        return "\(multiplier)x"
    }

    func loadStats() {
        guard let progressionService,
              let streakService else {
            return
        }

        do {
            let stats = try progressionService.currentStats()
            totalXP = stats.totalXP
            currentLevel = stats.currentLevel
            coins = stats.coins
            lifetimeCoins = stats.lifetimeCoins
            xpProgress = progressionService.xpProgressForCurrentLevel(totalXP: stats.totalXP)
            streakStatus = try streakService.currentStatus()
            let sessions = try readingProgressService?.fetchAllReadingSessions()
            chaptersRead = uniqueChaptersReadCount(from: sessions) ?? chaptersRead
            dailyGoalsCompleted = dailyGoalsCompletedCount(from: sessions) ?? dailyGoalsCompleted
            totalBibleChapters = try totalChapterCount() ?? totalBibleChapters
            todayPlanAssignment = try readingPlanService?.todaysAssignment()
            let boost = try progressionService.activeXPBoost(now: .now)
            activeXPBoostMultiplier = boost?.multiplier
            activeXPBoostEndDate = boost?.endDate
            availableXPBoosts = try shopService?.shopItems()
                .filter { $0.type == .xpBoost && $0.inventoryQuantity > 0 } ?? []
            xpBoostInventoryQuantity = availableXPBoosts.reduce(0) { $0 + $1.inventoryQuantity }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func uniqueChaptersReadCount(from sessions: [ReadingSession]?) -> Int? {
        guard let sessions else {
            return nil
        }

        let uniqueChapterIDs = Set(
            sessions.map { session in
                "\(session.bookAbbrev)-\(session.chapterIndex)"
            }
        )
        return uniqueChapterIDs.count
    }

    private func dailyGoalsCompletedCount(from sessions: [ReadingSession]?) -> Int? {
        guard let sessions else {
            return nil
        }

        let completedDays = Set(
            sessions.map { session in
                Calendar.current.startOfDay(for: session.date)
            }
        )
        return completedDays.count
    }

    private func totalChapterCount() throws -> Int? {
        guard let bibleService else {
            return nil
        }

        return try bibleService.allBooks().reduce(0) { total, book in
            total + book.chapters.count
        }
    }
}
