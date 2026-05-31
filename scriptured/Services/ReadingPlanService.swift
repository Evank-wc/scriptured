import Foundation
import SwiftData

@MainActor
struct ReadingPlanService {
    private let bundle: Bundle
    private let decoder: JSONDecoder
    private let modelContext: ModelContext?
    private let calendar: Calendar
    private let selectionStore: UserDefaults

    init(
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder(),
        modelContext: ModelContext? = nil,
        calendar: Calendar = .current,
        selectionStore: UserDefaults = .standard
    ) {
        self.bundle = bundle
        self.decoder = decoder
        self.modelContext = modelContext
        self.calendar = calendar
        self.selectionStore = selectionStore
    }

    func allPlans() -> ReadingPlanLoadResult {
        let urls = readingPlanJSONURLs()
        guard !urls.isEmpty else {
            return ReadingPlanLoadResult(
                plans: [],
                errors: ["No reading plan JSON files were found in Resources/ReadingPlans."]
            )
        }

        var plans: [ReadingPlanFile] = []
        var errors: [String] = []

        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            do {
                let data = try Data(contentsOf: url)
                let plan = try decoder.decode(ReadingPlanFile.self, from: data)
                plans.append(plan)
            } catch {
                let message = "Failed to decode reading plan \(url.lastPathComponent): \(error.localizedDescription)"
                errors.append(message)
                print("[ReadingPlanService] \(message)")
            }
        }

        return ReadingPlanLoadResult(
            plans: plans.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
            errors: errors
        )
    }

    func plan(id: String) -> ReadingPlanFile? {
        allPlans().plans.first { $0.id == id }
    }

    func isPlanStarted(planId: String) throws -> Bool {
        try userPlan(planId: planId) != nil
    }

    func selectedPlanId() -> String? {
        selectionStore.string(forKey: SelectionKey.selectedPlanId.rawValue)
    }

    @discardableResult
    func startPlan(_ plan: ReadingPlanFile) throws -> UserReadingPlan {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        selectionStore.set(plan.id, forKey: SelectionKey.selectedPlanId.rawValue)

        if let existingPlan = try userPlan(planId: plan.id) {
            try activate(existingPlan, in: modelContext)
            return existingPlan
        }

        return try createUserPlan(for: plan, in: modelContext)
    }

    func unselectPlan() throws {
        selectionStore.removeObject(forKey: SelectionKey.selectedPlanId.rawValue)
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        try deactivateActivePlans(in: modelContext)
        try modelContext.save()
    }

    func getActivePlan() throws -> UserReadingPlan? {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        if let selectedPlanId = selectedPlanId() {
            if let selectedPlan = try userPlan(planId: selectedPlanId) {
                return selectedPlan
            }

            if let plan = plan(id: selectedPlanId) {
                return try createUserPlan(for: plan, in: modelContext)
            }
        }

        var descriptor = FetchDescriptor<UserReadingPlan>(
            predicate: #Predicate { plan in
                plan.isActive == true
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let activePlan = try modelContext.fetch(descriptor).first
        if let activePlan {
            selectionStore.set(activePlan.planId, forKey: SelectionKey.selectedPlanId.rawValue)
        }
        return activePlan
    }

    func getCurrentDayForActivePlan() throws -> Int? {
        guard let activePlan = try getActivePlan() else {
            return nil
        }

        return currentDayNumber(for: activePlan)
    }

    func todaysAssignment() throws -> ReadingPlanTodayAssignment? {
        guard let activePlan = try getActivePlan(),
              let plan = plan(id: activePlan.planId) else {
            return nil
        }

        let currentDay = min(currentDayNumber(for: activePlan), max(plan.getDurationDays(), 1))
        activePlan.currentDayNumber = currentDay
        let readings = parsedReadings(for: plan, dayNumber: currentDay)
        let progress = try dayProgress(planId: plan.id, dayNumber: currentDay)
        let completedKeys = Set(progress?.completedReadingKeys ?? [])
        return ReadingPlanTodayAssignment(
            plan: plan,
            userPlan: activePlan,
            dayNumber: currentDay,
            readings: readings,
            completedReadingKeys: completedKeys,
            isComplete: progress?.isCompleted == true
        )
    }

    func completedDayNumbers(planId: String) throws -> Set<Int> {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        let descriptor = FetchDescriptor<UserReadingPlanDayProgress>(
            predicate: #Predicate { progress in
                progress.planId == planId && progress.isCompleted == true
            }
        )
        return Set(try modelContext.fetch(descriptor).map(\.dayNumber))
    }

    func parsedReadings(for plan: ReadingPlanFile, dayNumber: Int) -> [PlanReadingReference] {
        plan.getReadingForDay(dayNumber: dayNumber).flatMap(parseReadingReference)
    }

    @discardableResult
    func markTodayComplete(
        progressionService: any ProgressionServicing,
        readingProgressService: any ReadingProgressServicing
    ) throws -> PlanDayCompletionResult? {
        guard let assignment = try todaysAssignment() else {
            return nil
        }

        let requiredKeys = Set(assignment.readings.map(\.readingKey))
        guard !requiredKeys.isEmpty else {
            return nil
        }

        let progress = try progressForDay(planId: assignment.plan.id, dayNumber: assignment.dayNumber)
        let completedKeys = requiredKeys
        progress.completedReadingKeys = completedKeys.sorted()
        progress.updatedAt = .now
        assignment.userPlan.completedReadingKeys = Array(Set(assignment.userPlan.completedReadingKeys).union(completedKeys)).sorted()
        assignment.userPlan.currentDayNumber = assignment.dayNumber

        if let firstReading = assignment.readings.first {
            try readingProgressService.saveCompletedReadingSession(
                bibleLanguage: .english,
                bookAbbrev: firstReading.bookAbbrev,
                bookName: firstReading.bookName,
                chapterIndex: firstReading.chapterNumber,
                xpEarned: 0,
                coinsEarned: 0
            )
        }

        var rewardResult: RewardClaimResult?
        if !progress.isCompleted {
            progress.isCompleted = true
            progress.completedAt = .now
            var completedDays = Set(assignment.userPlan.completedDayNumbers)
            completedDays.insert(assignment.dayNumber)
            assignment.userPlan.completedDayNumbers = completedDays.sorted()
            assignment.userPlan.isCompleted = completedDays.count >= assignment.plan.getDurationDays()
            rewardResult = try progressionService.claimPlanDayCompletionReward(
                planId: assignment.plan.id,
                dayNumber: assignment.dayNumber,
                xpAwarded: 25,
                coinsAwarded: 5
            )
        }

        try modelContext?.save()

        return PlanDayCompletionResult(
            planName: assignment.plan.name,
            dayNumber: assignment.dayNumber,
            completedCount: completedKeys.count,
            requiredCount: requiredKeys.count,
            didCompleteDay: true,
            rewardResult: rewardResult
        )
    }

    @discardableResult
    func markReadingComplete(
        bookAbbrev: String,
        chapterNumber: Int,
        progressionService: any ProgressionServicing
    ) throws -> PlanDayCompletionResult? {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        guard let assignment = try todaysAssignment() else {
            return nil
        }

        let requiredKeys = Set(assignment.readings.map(\.readingKey))
        let completedKey = "\(bookAbbrev)-\(chapterNumber)"
        guard requiredKeys.contains(completedKey) else {
            return nil
        }

        let progress = try progressForDay(planId: assignment.plan.id, dayNumber: assignment.dayNumber)
        var completedKeys = Set(progress.completedReadingKeys)
        completedKeys.insert(completedKey)
        progress.completedReadingKeys = completedKeys.sorted()
        progress.updatedAt = .now
        assignment.userPlan.completedReadingKeys = Array(Set(assignment.userPlan.completedReadingKeys).union(completedKeys)).sorted()
        assignment.userPlan.currentDayNumber = assignment.dayNumber

        let didCompleteDay = requiredKeys.isSubset(of: completedKeys)
        var rewardResult: RewardClaimResult?

        if didCompleteDay && !progress.isCompleted {
            progress.isCompleted = true
            progress.completedAt = .now
            var completedDays = Set(assignment.userPlan.completedDayNumbers)
            completedDays.insert(assignment.dayNumber)
            assignment.userPlan.completedDayNumbers = completedDays.sorted()
            assignment.userPlan.isCompleted = completedDays.count >= assignment.plan.getDurationDays()
            rewardResult = try progressionService.claimPlanDayCompletionReward(
                planId: assignment.plan.id,
                dayNumber: assignment.dayNumber,
                xpAwarded: 25,
                coinsAwarded: 5
            )
        }

        try modelContext.save()

        return PlanDayCompletionResult(
            planName: assignment.plan.name,
            dayNumber: assignment.dayNumber,
            completedCount: completedKeys.intersection(requiredKeys).count,
            requiredCount: requiredKeys.count,
            didCompleteDay: didCompleteDay,
            rewardResult: rewardResult
        )
    }

    private func readingPlanJSONURLs() -> [URL] {
        let subdirectories = ["ReadingPlans", "Resources/ReadingPlans"]
        for subdirectory in subdirectories {
            if let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: subdirectory), !urls.isEmpty {
                return urls
            }
        }

        guard let rootURLs = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            return []
        }

        return rootURLs.filter { url in
            let filename = url.deletingPathExtension().lastPathComponent.lowercased()
            return filename != "en_bbe" && filename != "zh_cuv"
        }
    }

    private func createUserPlan(for plan: ReadingPlanFile, in modelContext: ModelContext) throws -> UserReadingPlan {
        try deactivateActivePlans(in: modelContext)
        selectionStore.set(plan.id, forKey: SelectionKey.selectedPlanId.rawValue)
        let userPlan = UserReadingPlan(
            planId: plan.id,
            planName: plan.name,
            planAbbreviation: plan.abbv,
            startDate: .now,
            currentDayNumber: 1,
            isActive: true,
            isCompleted: false
        )
        modelContext.insert(userPlan)
        try modelContext.save()
        return userPlan
    }

    private func userPlan(planId: String) throws -> UserReadingPlan? {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        var descriptor = FetchDescriptor<UserReadingPlan>(
            predicate: #Predicate { plan in
                plan.planId == planId
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func dayProgress(planId: String, dayNumber: Int) throws -> UserReadingPlanDayProgress? {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        let progressKey = "\(planId):\(dayNumber)"
        var descriptor = FetchDescriptor<UserReadingPlanDayProgress>(
            predicate: #Predicate { progress in
                progress.progressKey == progressKey
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func progressForDay(planId: String, dayNumber: Int) throws -> UserReadingPlanDayProgress {
        if let existingProgress = try dayProgress(planId: planId, dayNumber: dayNumber) {
            return existingProgress
        }

        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        let progress = UserReadingPlanDayProgress(planId: planId, dayNumber: dayNumber)
        modelContext.insert(progress)
        return progress
    }

    private func activate(_ plan: UserReadingPlan, in modelContext: ModelContext) throws {
        try deactivateActivePlans(in: modelContext)
        selectionStore.set(plan.planId, forKey: SelectionKey.selectedPlanId.rawValue)
        plan.selectedPlanId = plan.planId
        plan.isActive = true
        plan.isCompleted = false
        plan.currentDayNumber = currentDayNumber(for: plan)
        try modelContext.save()
    }

    private func deactivateActivePlans(in modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<UserReadingPlan>(
            predicate: #Predicate { plan in
                plan.isActive == true
            }
        )
        let activePlans = try modelContext.fetch(descriptor)
        for activePlan in activePlans {
            activePlan.isActive = false
        }
    }

    private enum SelectionKey: String {
        case selectedPlanId = "readingPlan.selectedPlanId"
    }

    private func currentDayNumber(for plan: UserReadingPlan) -> Int {
        let start = calendar.startOfDay(for: plan.startDate)
        let today = calendar.startOfDay(for: .now)
        let elapsedDays = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(elapsedDays + 1, 1)
    }

    private func parseReadingReference(_ displayText: String) -> [PlanReadingReference] {
        let trimmed = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = firstBookMatch(in: trimmed) else {
            return []
        }

        let remainder = String(trimmed.dropFirst(match.name.count))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstChapter = firstChapterNumber(in: remainder) else {
            return []
        }

        let endChapter = endChapterNumber(in: remainder, fallback: firstChapter)
        return (firstChapter...max(firstChapter, endChapter)).map { chapter in
            PlanReadingReference(
                displayText: trimmed,
                bookName: match.displayName,
                bookAbbrev: match.abbrev,
                chapterNumber: chapter
            )
        }
    }

    private func firstBookMatch(in reading: String) -> BookAlias? {
        let normalized = normalize(reading)
        return BookAlias.allCases
            .sorted { $0.name.count > $1.name.count }
            .first { alias in
                normalized.hasPrefix(normalize(alias.name))
            }
    }

    private func firstChapterNumber(in text: String) -> Int? {
        let pattern = #"\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        return Int(text[range])
    }

    private func endChapterNumber(in text: String, fallback: Int) -> Int {
        if let chapterRangeEnd = firstCapture(in: text, pattern: #"-\s*(\d+)\s*:"#) {
            return chapterRangeEnd
        }

        let hasVerseSeparatorBeforeRange = text
            .split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .contains(":") == true
        if hasVerseSeparatorBeforeRange {
            return fallback
        }

        return firstCapture(in: text, pattern: #"-\s*(\d+)"#) ?? fallback
    }

    private func firstCapture(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return Int(text[range])
    }

    private func normalize(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
}

struct ReadingPlanLoadResult {
    let plans: [ReadingPlanFile]
    let errors: [String]
}

struct ReadingPlanTodayAssignment {
    let plan: ReadingPlanFile
    let userPlan: UserReadingPlan
    let dayNumber: Int
    let readings: [PlanReadingReference]
    let completedReadingKeys: Set<String>
    let isComplete: Bool
}

struct PlanDayCompletionResult {
    let planName: String
    let dayNumber: Int
    let completedCount: Int
    let requiredCount: Int
    let didCompleteDay: Bool
    let rewardResult: RewardClaimResult?
}

enum ReadingPlanServiceError: LocalizedError {
    case missingModelContext

    var errorDescription: String? {
        switch self {
        case .missingModelContext:
            "Reading plan progress requires a SwiftData model context."
        }
    }
}

private struct BookAlias {
    let name: String
    let displayName: String
    let abbrev: String

    static let allCases: [BookAlias] = [
        BookAlias(name: "Genesis", displayName: "Genesis", abbrev: "gn"),
        BookAlias(name: "Exodus", displayName: "Exodus", abbrev: "ex"),
        BookAlias(name: "Leviticus", displayName: "Leviticus", abbrev: "lv"),
        BookAlias(name: "Numbers", displayName: "Numbers", abbrev: "nm"),
        BookAlias(name: "Deuteronomy", displayName: "Deuteronomy", abbrev: "dt"),
        BookAlias(name: "Joshua", displayName: "Joshua", abbrev: "js"),
        BookAlias(name: "Judges", displayName: "Judges", abbrev: "jud"),
        BookAlias(name: "Ruth", displayName: "Ruth", abbrev: "rt"),
        BookAlias(name: "1 Samuel", displayName: "1 Samuel", abbrev: "1sm"),
        BookAlias(name: "2 Samuel", displayName: "2 Samuel", abbrev: "2sm"),
        BookAlias(name: "1 Kings", displayName: "1 Kings", abbrev: "1kgs"),
        BookAlias(name: "2 Kings", displayName: "2 Kings", abbrev: "2kgs"),
        BookAlias(name: "1 Chronicles", displayName: "1 Chronicles", abbrev: "1ch"),
        BookAlias(name: "1Chronicles", displayName: "1 Chronicles", abbrev: "1ch"),
        BookAlias(name: "2 Chronicles", displayName: "2 Chronicles", abbrev: "2ch"),
        BookAlias(name: "2Chronicles", displayName: "2 Chronicles", abbrev: "2ch"),
        BookAlias(name: "Ezra", displayName: "Ezra", abbrev: "ezr"),
        BookAlias(name: "Nehemiah", displayName: "Nehemiah", abbrev: "ne"),
        BookAlias(name: "Esther", displayName: "Esther", abbrev: "et"),
        BookAlias(name: "Job", displayName: "Job", abbrev: "job"),
        BookAlias(name: "Psalm", displayName: "Psalms", abbrev: "ps"),
        BookAlias(name: "Psalms", displayName: "Psalms", abbrev: "ps"),
        BookAlias(name: "Proverbs", displayName: "Proverbs", abbrev: "prv"),
        BookAlias(name: "Ecclesiastes", displayName: "Ecclesiastes", abbrev: "ec"),
        BookAlias(name: "Song of Solomon", displayName: "Song of Solomon", abbrev: "so"),
        BookAlias(name: "Isaiah", displayName: "Isaiah", abbrev: "is"),
        BookAlias(name: "Jeremiah", displayName: "Jeremiah", abbrev: "jr"),
        BookAlias(name: "Lamentations", displayName: "Lamentations", abbrev: "lm"),
        BookAlias(name: "Ezekiel", displayName: "Ezekiel", abbrev: "ez"),
        BookAlias(name: "Daniel", displayName: "Daniel", abbrev: "dn"),
        BookAlias(name: "Hosea", displayName: "Hosea", abbrev: "ho"),
        BookAlias(name: "Joel", displayName: "Joel", abbrev: "jl"),
        BookAlias(name: "Amos", displayName: "Amos", abbrev: "am"),
        BookAlias(name: "Obadiah", displayName: "Obadiah", abbrev: "ob"),
        BookAlias(name: "Jonah", displayName: "Jonah", abbrev: "jn"),
        BookAlias(name: "Micah", displayName: "Micah", abbrev: "mi"),
        BookAlias(name: "Nahum", displayName: "Nahum", abbrev: "na"),
        BookAlias(name: "Habakkuk", displayName: "Habakkuk", abbrev: "hk"),
        BookAlias(name: "Zephaniah", displayName: "Zephaniah", abbrev: "zp"),
        BookAlias(name: "Haggai", displayName: "Haggai", abbrev: "hg"),
        BookAlias(name: "Zechariah", displayName: "Zechariah", abbrev: "zc"),
        BookAlias(name: "Malachi", displayName: "Malachi", abbrev: "ml"),
        BookAlias(name: "Matthew", displayName: "Matthew", abbrev: "mt"),
        BookAlias(name: "Mark", displayName: "Mark", abbrev: "mk"),
        BookAlias(name: "Luke", displayName: "Luke", abbrev: "lk"),
        BookAlias(name: "John", displayName: "John", abbrev: "jo"),
        BookAlias(name: "Acts", displayName: "Acts", abbrev: "act"),
        BookAlias(name: "Romans", displayName: "Romans", abbrev: "rm"),
        BookAlias(name: "1 Corinthians", displayName: "1 Corinthians", abbrev: "1co"),
        BookAlias(name: "2 Corinthians", displayName: "2 Corinthians", abbrev: "2co"),
        BookAlias(name: "Galatians", displayName: "Galatians", abbrev: "gl"),
        BookAlias(name: "Ephesians", displayName: "Ephesians", abbrev: "eph"),
        BookAlias(name: "Philippians", displayName: "Philippians", abbrev: "ph"),
        BookAlias(name: "Colossians", displayName: "Colossians", abbrev: "cl"),
        BookAlias(name: "1 Thessalonians", displayName: "1 Thessalonians", abbrev: "1ts"),
        BookAlias(name: "2 Thessalonians", displayName: "2 Thessalonians", abbrev: "2ts"),
        BookAlias(name: "1 Timothy", displayName: "1 Timothy", abbrev: "1tm"),
        BookAlias(name: "2 Timothy", displayName: "2 Timothy", abbrev: "2tm"),
        BookAlias(name: "Titus", displayName: "Titus", abbrev: "tt"),
        BookAlias(name: "Philemon", displayName: "Philemon", abbrev: "phm"),
        BookAlias(name: "Hebrews", displayName: "Hebrews", abbrev: "hb"),
        BookAlias(name: "James", displayName: "James", abbrev: "jm"),
        BookAlias(name: "1 Peter", displayName: "1 Peter", abbrev: "1pe"),
        BookAlias(name: "2 Peter", displayName: "2 Peter", abbrev: "2pe"),
        BookAlias(name: "1 John", displayName: "1 John", abbrev: "1jo"),
        BookAlias(name: "2 John", displayName: "2 John", abbrev: "2jo"),
        BookAlias(name: "3 John", displayName: "3 John", abbrev: "3jo"),
        BookAlias(name: "Jude", displayName: "Jude", abbrev: "jd"),
        BookAlias(name: "Revelation", displayName: "Revelation", abbrev: "re")
    ]
}
