import Foundation
import SwiftData

enum ShopError: LocalizedError {
    case insufficientCoins
    case duplicateCosmetic
    case itemNotFound
    case cosmeticRequired

    var errorDescription: String? {
        switch self {
        case .insufficientCoins:
            "You need more coins for this item."
        case .duplicateCosmetic:
            "You already own this cosmetic."
        case .itemNotFound:
            "This shop item is no longer available."
        case .cosmeticRequired:
            "Only cosmetic items can be equipped."
        }
    }
}

struct ShopPurchaseResult {
    let item: ShopItem
    let remainingCoins: Int
}

@MainActor
struct ShopService {
    private let modelContext: ModelContext

    private let catalog: [CatalogShopItem] = [
        CatalogShopItem(
            id: "streak-freeze",
            name: "Streak Freeze",
            description: "Protects one missed day when your streak is at risk.",
            type: .streakFreeze,
            price: 40
        ),
        CatalogShopItem(
            id: "xp-boost-small",
            name: "Morning Spark",
            description: "A saved boost for a future XP bonus.",
            type: .xpBoost,
            price: 30
        ),
        CatalogShopItem(
            id: "outfit-forest-cloak",
            name: "Forest Cloak",
            description: "A calm green outfit for your profile.",
            type: .outfit,
            price: 120
        ),
        CatalogShopItem(
            id: "outfit-sunrise-wrap",
            name: "Sunrise Wrap",
            description: "A bright outfit inspired by daily progress.",
            type: .outfit,
            price: 150
        ),
        CatalogShopItem(
            id: "frame-meadow",
            name: "Meadow Frame",
            description: "A leafy profile frame for steady readers.",
            type: .profileFrame,
            price: 90
        ),
        CatalogShopItem(
            id: "frame-golden-hour",
            name: "Golden Hour Frame",
            description: "A warm frame with a soft reward glow.",
            type: .profileFrame,
            price: 110
        ),
        CatalogShopItem(
            id: "title-streak-keeper",
            name: "Streak Keeper",
            description: "A profile title for daily consistency.",
            type: .title,
            price: 75
        ),
        CatalogShopItem(
            id: "title-word-walker",
            name: "Word Walker",
            description: "A profile title for the long journey.",
            type: .title,
            price: 100
        )
    ]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func shopItems() throws -> [ShopItem] {
        let inventory = try inventoryItems()
        return catalog.map { catalogItem in
            let matchingInventory = inventory.first { $0.shopItemId == catalogItem.id }
            return catalogItem.shopItem(
                isOwned: matchingInventory != nil,
                isEquipped: matchingInventory?.isEquipped == true
            )
        }
    }

    func inventoryItems() throws -> [InventoryItem] {
        var descriptor = FetchDescriptor<InventoryItem>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    func currentCoins() throws -> Int {
        try currentStats().coins
    }

    func purchase(itemId: String) throws -> ShopPurchaseResult {
        guard let catalogItem = catalog.first(where: { $0.id == itemId }) else {
            throw ShopError.itemNotFound
        }

        let existingInventoryItem = try inventoryItem(for: itemId)
        if catalogItem.type.isCosmetic, existingInventoryItem != nil {
            throw ShopError.duplicateCosmetic
        }

        let stats = try currentStats()
        guard stats.coins >= catalogItem.price else {
            throw ShopError.insufficientCoins
        }

        stats.coins -= catalogItem.price
        stats.lastUpdated = .now

        if let existingInventoryItem, catalogItem.type.isConsumable {
            existingInventoryItem.quantity += 1
            existingInventoryItem.updatedAt = .now
        } else {
            let inventoryItem = InventoryItem(
                shopItemId: catalogItem.id,
                itemType: catalogItem.type,
                quantity: 1,
                isEquipped: false
            )
            modelContext.insert(inventoryItem)
        }

        if catalogItem.type == .streakFreeze {
            let streakState = try currentStreakState()
            streakState.streakFreezesAvailable += 1
            streakState.lastEvaluatedAt = .now
        }

        try modelContext.save()

        return ShopPurchaseResult(
            item: catalogItem.shopItem(isOwned: true, isEquipped: false),
            remainingCoins: stats.coins
        )
    }

    func equip(itemId: String) throws {
        guard let catalogItem = catalog.first(where: { $0.id == itemId }) else {
            throw ShopError.itemNotFound
        }

        guard catalogItem.type.isCosmetic else {
            throw ShopError.cosmeticRequired
        }

        guard let inventoryItem = try inventoryItem(for: itemId) else {
            throw ShopError.itemNotFound
        }

        let inventory = try inventoryItems()
        for item in inventory where item.itemType == catalogItem.type {
            item.isEquipped = item.shopItemId == inventoryItem.shopItemId
            item.updatedAt = .now
        }

        try modelContext.save()
    }

    private func currentStats() throws -> UserStats {
        var descriptor = FetchDescriptor<UserStats>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.includePendingChanges = true

        if let stats = try modelContext.fetch(descriptor).first {
            return stats
        }

        let stats = UserStats()
        modelContext.insert(stats)
        try modelContext.save()
        return stats
    }

    private func currentStreakState() throws -> StreakState {
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
        return state
    }

    private func inventoryItem(for shopItemId: String) throws -> InventoryItem? {
        var descriptor = FetchDescriptor<InventoryItem>(
            predicate: #Predicate { item in
                item.shopItemId == shopItemId
            }
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).first
    }
}

private struct CatalogShopItem {
    let id: String
    let name: String
    let description: String
    let type: ShopItemType
    let price: Int

    func shopItem(isOwned: Bool, isEquipped: Bool) -> ShopItem {
        ShopItem(
            id: id,
            name: name,
            description: description,
            type: type,
            price: price,
            isOwned: isOwned,
            isEquipped: isEquipped
        )
    }
}
