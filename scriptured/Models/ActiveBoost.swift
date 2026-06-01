import Foundation
import SwiftData

@Model
final class ActiveBoost {
    var id: UUID
    var boostType: String
    var multiplier: Double
    var startDate: Date
    var endDate: Date

    init(
        id: UUID = UUID(),
        boostType: String,
        multiplier: Double,
        startDate: Date = .now,
        endDate: Date
    ) {
        self.id = id
        self.boostType = boostType
        self.multiplier = multiplier
        self.startDate = startDate
        self.endDate = endDate
    }
}
