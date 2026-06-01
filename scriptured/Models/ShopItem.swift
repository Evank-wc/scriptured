import Foundation
import SwiftData

enum ShopItemType: String, CaseIterable, Codable, Identifiable {
    case streakFreeze
    case xpBoost
    case outfit
    case profileFrame
    case title

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .streakFreeze:
            "Streak Freeze"
        case .xpBoost:
            "XP Boost"
        case .outfit:
            "Outfit"
        case .profileFrame:
            "Frame"
        case .title:
            "Title"
        }
    }

    var isConsumable: Bool {
        switch self {
        case .streakFreeze, .xpBoost:
            true
        case .outfit, .profileFrame, .title:
            false
        }
    }

    var isCosmetic: Bool {
        !isConsumable
    }

    var systemImage: String {
        switch self {
        case .streakFreeze:
            "snowflake"
        case .xpBoost:
            "bolt.fill"
        case .outfit:
            "tshirt.fill"
        case .profileFrame:
            "person.crop.square.filled.and.at.rectangle"
        case .title:
            "textformat"
        }
    }
}

struct ShopItem: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let type: ShopItemType
    let price: Int
    let isOwned: Bool
    let isEquipped: Bool
}

@Model
final class InventoryItem {
    var id: UUID
    var shopItemId: String
    var itemTypeRawValue: String
    var quantity: Int
    var isEquipped: Bool
    var purchasedAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        shopItemId: String,
        itemType: ShopItemType,
        quantity: Int = 1,
        isEquipped: Bool = false,
        purchasedAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.shopItemId = shopItemId
        self.itemTypeRawValue = itemType.rawValue
        self.quantity = quantity
        self.isEquipped = isEquipped
        self.purchasedAt = purchasedAt
        self.updatedAt = updatedAt
    }

    var itemType: ShopItemType {
        get { ShopItemType(rawValue: itemTypeRawValue) ?? .title }
        set { itemTypeRawValue = newValue.rawValue }
    }
}
