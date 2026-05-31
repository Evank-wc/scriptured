import Foundation
import Observation

@MainActor
@Observable
final class PlansViewModel {
    let title = "Plans"

    private var readingPlanService: ReadingPlanService?

    private(set) var plans: [ReadingPlanFile] = []
    private(set) var activePlan: UserReadingPlan?
    private(set) var currentActiveDayNumber: Int?
    private(set) var startedPlanIds: Set<String> = []
    private(set) var decodingErrors: [String] = []
    private(set) var errorMessage: String?

    var hasDecodingErrors: Bool {
        !decodingErrors.isEmpty
    }

    var selectedPlan: ReadingPlanFile? {
        guard let activePlan else {
            return nil
        }

        return plans.first { $0.id == activePlan.planId }
    }

    var otherPlans: [ReadingPlanFile] {
        guard let selectedPlan else {
            return plans
        }

        return plans.filter { $0.id != selectedPlan.id }
    }

    func configure(readingPlanService: ReadingPlanService) {
        self.readingPlanService = readingPlanService
        loadPlans()
    }

    func loadPlans() {
        guard let readingPlanService else {
            return
        }

        let result = readingPlanService.allPlans()
        plans = result.plans
        decodingErrors = result.errors
        refreshProgressState()
    }

    func isPlanStarted(planId: String) -> Bool {
        startedPlanIds.contains(planId)
    }

    func isSelectedPlan(planId: String) -> Bool {
        activePlan?.planId == planId
    }

    func startPlan(_ plan: ReadingPlanFile) {
        guard let readingPlanService else {
            return
        }

        do {
            _ = try readingPlanService.startPlan(plan)
            refreshProgressState()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func getActivePlan() -> UserReadingPlan? {
        activePlan
    }

    func getCurrentDayForActivePlan() -> Int? {
        currentActiveDayNumber
    }

    private func refreshProgressState() {
        guard let readingPlanService else {
            return
        }

        do {
            var startedIds = Set<String>()
            for plan in plans where try readingPlanService.isPlanStarted(planId: plan.id) {
                startedIds.insert(plan.id)
            }
            startedPlanIds = startedIds
            activePlan = try readingPlanService.getActivePlan()
            currentActiveDayNumber = try readingPlanService.getCurrentDayForActivePlan()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
