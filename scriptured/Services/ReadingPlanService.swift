import Foundation
import SwiftData

@MainActor
struct ReadingPlanService {
    private let bundle: Bundle
    private let decoder: JSONDecoder
    private let modelContext: ModelContext?

    init(
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder(),
        modelContext: ModelContext? = nil
    ) {
        self.bundle = bundle
        self.decoder = decoder
        self.modelContext = modelContext
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

    @discardableResult
    func startPlan(_ plan: ReadingPlanFile) throws -> UserReadingPlan {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        if let existingPlan = try userPlan(planId: plan.id) {
            try activate(existingPlan, in: modelContext)
            return existingPlan
        }

        try deactivateActivePlans(in: modelContext)

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

    func getActivePlan() throws -> UserReadingPlan? {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        var descriptor = FetchDescriptor<UserReadingPlan>(
            predicate: #Predicate { plan in
                plan.isActive == true && plan.isCompleted == false
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func getCurrentDayForActivePlan() throws -> Int? {
        guard let activePlan = try getActivePlan() else {
            return nil
        }

        return currentDayNumber(for: activePlan)
    }

    func completedDayNumbers(planId: String) throws -> Set<Int> {
        guard let modelContext else {
            throw ReadingPlanServiceError.missingModelContext
        }

        let descriptor = FetchDescriptor<UserReadingPlanDayProgress>(
            predicate: #Predicate { progress in
                progress.planId == planId
            }
        )
        return Set(try modelContext.fetch(descriptor).map(\.dayNumber))
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

    private func activate(_ plan: UserReadingPlan, in modelContext: ModelContext) throws {
        try deactivateActivePlans(in: modelContext)
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

    private func currentDayNumber(for plan: UserReadingPlan) -> Int {
        let start = Calendar.current.startOfDay(for: plan.startDate)
        let today = Calendar.current.startOfDay(for: .now)
        let elapsedDays = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
        return max(elapsedDays + 1, 1)
    }
}

struct ReadingPlanLoadResult {
    let plans: [ReadingPlanFile]
    let errors: [String]
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
