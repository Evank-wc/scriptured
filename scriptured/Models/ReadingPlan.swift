import Foundation
import SwiftData

struct ReadingPlanFile: Identifiable, Hashable, Codable {
    let data: [String]
    let data2: [[String]]
    let id: String
    let abbv: String
    let name: String
    let info: String

    enum CodingKeys: String, CodingKey {
        case data
        case data2
        case id
        case abbv
        case name
        case info
    }

    init(
        data: [String],
        data2: [[String]],
        id: String,
        abbv: String,
        name: String,
        info: String
    ) {
        self.data = data
        self.data2 = data2
        self.id = id
        self.abbv = abbv
        self.name = name
        self.info = info
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent([String].self, forKey: .data) ?? []
        data2 = try container.decodeIfPresent([[String]].self, forKey: .data2) ?? []
        abbv = try container.decodeIfPresent(String.self, forKey: .abbv) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Untitled Plan"
        info = try container.decodeIfPresent(String.self, forKey: .info) ?? ""

        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else if let intID = try? container.decode(Int.self, forKey: .id) {
            id = String(intID)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: [CodingKeys.id],
                    debugDescription: "Expected reading plan id to be a String or Int."
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(data2, forKey: .data2)
        try container.encode(id, forKey: .id)
        try container.encode(abbv, forKey: .abbv)
        try container.encode(name, forKey: .name)
        try container.encode(info, forKey: .info)
    }

    func getDurationDays() -> Int {
        max(data.count, data2.count)
    }

    func getReadingForDay(dayNumber: Int) -> [String] {
        guard dayNumber > 0 else {
            return []
        }

        let index = dayNumber - 1
        if data2.indices.contains(index), !data2[index].isEmpty {
            return data2[index]
        }

        if data.indices.contains(index) {
            return [data[index]]
        }

        return []
    }
}

@Model
final class UserReadingPlan {
    @Attribute(.unique) var planId: String
    var planName: String
    var planAbbreviation: String
    var startDate: Date
    var currentDayNumber: Int
    var isActive: Bool
    var isCompleted: Bool

    init(
        planId: String,
        planName: String,
        planAbbreviation: String,
        startDate: Date = .now,
        currentDayNumber: Int = 1,
        isActive: Bool = true,
        isCompleted: Bool = false
    ) {
        self.planId = planId
        self.planName = planName
        self.planAbbreviation = planAbbreviation
        self.startDate = startDate
        self.currentDayNumber = currentDayNumber
        self.isActive = isActive
        self.isCompleted = isCompleted
    }
}

@Model
final class UserReadingPlanDayProgress {
    @Attribute(.unique) var progressKey: String
    var planId: String
    var dayNumber: Int
    var completedAt: Date

    init(planId: String, dayNumber: Int, completedAt: Date = .now) {
        self.progressKey = "\(planId):\(dayNumber)"
        self.planId = planId
        self.dayNumber = dayNumber
        self.completedAt = completedAt
    }
}
