import Foundation
import SwiftData

struct StreakStatus {
    let currentStreak: Int
    let longestStreak: Int
    let hasCompletedToday: Bool
    let isAtRisk: Bool
    let shouldConsumeFreeze: Bool
    let streakFreezesAvailable: Int

    var statusText: String {
        if hasCompletedToday {
            "Completed today"
        } else if isAtRisk {
            "Read today to keep your streak"
        } else if shouldConsumeFreeze {
            "Freeze protected your streak"
        } else {
            "Start a streak today"
        }
    }
}

@MainActor
protocol StreakServicing {
    func currentStatus() throws -> StreakStatus
    func currentStreak() throws -> Int
    func longestStreak() throws -> Int
    func hasCompletedReadingToday() throws -> Bool
    func isStreakAtRisk() throws -> Bool
    func shouldConsumeStreakFreeze() throws -> Bool
    func streakFreezesAvailable() throws -> Int
}

@MainActor
struct StreakService: StreakServicing {
    private let modelContext: ModelContext
    private let calendar: Calendar

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    func currentStatus() throws -> StreakStatus {
        let state = try currentState()
        let completionDays = try completedReadingDays()
        let today = startOfDay(.now)
        let yesterday = day(before: today)
        let hasCompletedToday = completionDays.contains(today)
        let hasCompletedYesterday = completionDays.contains(yesterday)
        let shouldConsumeFreeze = !hasCompletedToday
            && !hasCompletedYesterday
            && hasAnyCompletion(before: today, in: completionDays)
            && state.streakFreezesAvailable > 0
            && !hasConsumedFreeze(on: yesterday, state: state)

        if shouldConsumeFreeze {
            state.streakFreezesAvailable -= 1
            state.consumedFreezeDates.append(yesterday)
        }

        let currentStreak = calculateCurrentStreak(
            completionDays: completionDays,
            consumedFreezeDays: Set(state.consumedFreezeDates.map(startOfDay)),
            today: today
        )
        let longestStreak = max(
            state.longestStreak,
            calculateLongestStreak(
                completionDays: completionDays,
                consumedFreezeDays: Set(state.consumedFreezeDates.map(startOfDay))
            ),
            currentStreak
        )
        let isAtRisk = !hasCompletedToday && (currentStreak > 0 || hasCompletedYesterday)

        state.currentStreak = currentStreak
        state.longestStreak = longestStreak
        state.lastEvaluatedAt = .now
        try modelContext.save()

        return StreakStatus(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            hasCompletedToday: hasCompletedToday,
            isAtRisk: isAtRisk,
            shouldConsumeFreeze: shouldConsumeFreeze,
            streakFreezesAvailable: state.streakFreezesAvailable
        )
    }

    func currentStreak() throws -> Int {
        try currentStatus().currentStreak
    }

    func longestStreak() throws -> Int {
        try currentStatus().longestStreak
    }

    func hasCompletedReadingToday() throws -> Bool {
        try currentStatus().hasCompletedToday
    }

    func isStreakAtRisk() throws -> Bool {
        try currentStatus().isAtRisk
    }

    func shouldConsumeStreakFreeze() throws -> Bool {
        try currentStatus().shouldConsumeFreeze
    }

    func streakFreezesAvailable() throws -> Int {
        try currentStatus().streakFreezesAvailable
    }

    private func currentState() throws -> StreakState {
        var descriptor = FetchDescriptor<StreakState>(
            sortBy: [SortDescriptor(\.lastEvaluatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        if let state = try modelContext.fetch(descriptor).first {
            return state
        }

        let state = StreakState(streakFreezesAvailable: 1)
        modelContext.insert(state)
        try modelContext.save()
        return state
    }

    private func completedReadingDays() throws -> Set<Date> {
        let descriptor = FetchDescriptor<ReadingSession>()
        let sessions = try modelContext.fetch(descriptor)
        return Set(sessions.map { startOfDay($0.date) })
    }

    private func calculateCurrentStreak(
        completionDays: Set<Date>,
        consumedFreezeDays: Set<Date>,
        today: Date
    ) -> Int {
        var streak = 0
        var currentDay = today

        if !completionDays.contains(currentDay) {
            currentDay = day(before: currentDay)
        }

        while completionDays.contains(currentDay) || consumedFreezeDays.contains(currentDay) {
            streak += 1
            currentDay = day(before: currentDay)
        }

        return streak
    }

    private func calculateLongestStreak(
        completionDays: Set<Date>,
        consumedFreezeDays: Set<Date>
    ) -> Int {
        let streakDays = completionDays.union(consumedFreezeDays).sorted()
        guard let firstDay = streakDays.first else {
            return 0
        }

        var longest = 0
        var current = 0
        var previousDay = firstDay

        for streakDay in streakDays {
            if streakDay == firstDay || calendar.isDate(streakDay, inSameDayAs: day(after: previousDay)) {
                current += 1
            } else {
                current = 1
            }

            longest = max(longest, current)
            previousDay = streakDay
        }

        return longest
    }

    private func hasAnyCompletion(before day: Date, in completionDays: Set<Date>) -> Bool {
        completionDays.contains { completedDay in
            completedDay < day
        }
    }

    private func hasConsumedFreeze(on day: Date, state: StreakState) -> Bool {
        state.consumedFreezeDates.map(startOfDay).contains(day)
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func day(before date: Date) -> Date {
        calendar.date(byAdding: .day, value: -1, to: date) ?? date
    }

    private func day(after date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }
}
