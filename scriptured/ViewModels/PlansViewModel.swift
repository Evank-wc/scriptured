import Foundation
import Observation

@MainActor
@Observable
final class PlansViewModel {
    let title = "Plans"

    private var readingPlanService: ReadingPlanService?

    private(set) var plans: [ReadingPlanFile] = []
    private(set) var activePlan: UserReadingPlan?
    private(set) var selectedPlanId: String?
    private(set) var currentActiveDayNumber: Int?
    private(set) var startedPlanIds: Set<String> = []
    private(set) var decodingErrors: [String] = []
    private(set) var errorMessage: String?

    var hasDecodingErrors: Bool {
        !decodingErrors.isEmpty
    }

    var selectedPlan: ReadingPlanFile? {
        guard let selectedPlanId else {
            return nil
        }

        return plans.first { $0.id == selectedPlanId }
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
        selectedPlanId == planId
    }

    func startPlan(_ plan: ReadingPlanFile) {
        guard let readingPlanService else {
            errorMessage = "Reading plan service is not ready."
            return
        }

        do {
            selectedPlanId = plan.id
            _ = try readingPlanService.startPlan(plan)
            ReadingActivitySignal.send()
            refreshProgressState()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            refreshProgressState()
        }
    }

    func refreshSelectionState() {
        refreshProgressState()
    }

    func unselectPlan() {
        guard let readingPlanService else {
            errorMessage = "Reading plan service is not ready."
            return
        }

        do {
            try readingPlanService.unselectPlan()
            ReadingActivitySignal.send()
            selectedPlanId = nil
            activePlan = nil
            currentActiveDayNumber = nil
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
            selectedPlanId = readingPlanService.selectedPlanId() ?? activePlan?.planId
            currentActiveDayNumber = try readingPlanService.getCurrentDayForActivePlan()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            selectedPlanId = readingPlanService.selectedPlanId() ?? selectedPlanId
        }
    }
}
