import Foundation

struct ReadingPlan: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let durationInDays: Int
}

struct ReadingPlanProgress: Identifiable, Hashable, Codable {
    let id: String
    let planID: String
    let completedDayCount: Int
}
