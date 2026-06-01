import Foundation
import SwiftData

enum ShopError: LocalizedError {
    case insufficientCoins
    case duplicateCosmetic
    case itemNotFound
    case cosmeticRequired
    case boostUnavailable

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
        case .boostUnavailable:
            "Buy an XP boost before activating one."
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
            price: 150,
            quantityGranted: 1
        ),
        CatalogShopItem(
            id: "streak-freeze-5-pack",
            name: "5 Freeze Bundle",
            description: "Five streak freezes for steady protection.",
            type: .streakFreeze,
            price: 700,
            quantityGranted: 5
        ),
        CatalogShopItem(
            id: "streak-freeze-10-pack",
            name: "10 Freeze Bundle",
            description: "Ten streak freezes for a longer safety net.",
            type: .streakFreeze,
            price: 1200,
            quantityGranted: 10
        ),
        CatalogShopItem(
            id: "xp-boost-small",
            name: "XP Boost",
            description: "Double XP rewards for 1 hour.",
            type: .xpBoost,
            price: 200,
            boostDuration: 60 * 60
        ),
        CatalogShopItem(
            id: "xp-boost-3-hour",
            name: "3 Hour XP Boost",
            description: "Double XP rewards for 3 hours.",
            type: .xpBoost,
            price: 500,
            boostDuration: 3 * 60 * 60
        ),
        CatalogShopItem(
            id: "xp-boost-24-hour",
            name: "24 Hour XP Boost",
            description: "Double XP rewards for 24 hours.",
            type: .xpBoost,
            price: 3000,
            boostDuration: 24 * 60 * 60
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
            id: "outfit-sabbath-robe",
            name: "Sabbath Robe",
            description: "A quiet robe with a soft cream finish.",
            type: .outfit,
            price: 180
        ),
        CatalogShopItem(
            id: "outfit-river-tunic",
            name: "River Tunic",
            description: "A fresh blue-green outfit for steady mornings.",
            type: .outfit,
            price: 210
        ),
        CatalogShopItem(
            id: "outfit-olive-mantle",
            name: "Olive Mantle",
            description: "A warm mantle with grounded olive tones.",
            type: .outfit,
            price: 240
        ),
        CatalogShopItem(
            id: "outfit-garden-vestments",
            name: "Garden Vestments",
            description: "A brighter outfit for milestone readers.",
            type: .outfit,
            price: 300
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
            id: "frame-vine-border",
            name: "Vine Border",
            description: "A simple green frame with woven vine edges.",
            type: .profileFrame,
            price: 140
        ),
        CatalogShopItem(
            id: "frame-lantern-light",
            name: "Lantern Light",
            description: "A gentle frame with a warm evening glow.",
            type: .profileFrame,
            price: 170
        ),
        CatalogShopItem(
            id: "frame-river-stone",
            name: "River Stone",
            description: "A cool frame with smooth blue stone accents.",
            type: .profileFrame,
            price: 200
        ),
        CatalogShopItem(
            id: "frame-crown-garden",
            name: "Crown Garden",
            description: "A premium frame with gold and meadow detail.",
            type: .profileFrame,
            price: 260
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
        ),
        CatalogShopItem(
            id: "title-daily-reader",
            name: "Daily Reader",
            description: "A title for showing up one day at a time.",
            type: .title,
            price: 120
        ),
        CatalogShopItem(
            id: "title-plan-finisher",
            name: "Plan Finisher",
            description: "A title for readers who complete the path.",
            type: .title,
            price: 160
        ),
        CatalogShopItem(
            id: "title-verse-seeker",
            name: "Verse Seeker",
            description: "A title for curious and consistent reading.",
            type: .title,
            price: 200
        ),
        CatalogShopItem(
            id: "title-faithful-flame",
            name: "Faithful Flame",
            description: "A title for keeping the reading fire alive.",
            type: .title,
            price: 260
        )
    ]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func shopItems() throws -> [ShopItem] {
        let inventory = try inventoryItems()
        let streakFreezesAvailable = try currentStreakState().streakFreezesAvailable
        return catalog.map { catalogItem in
            let matchingInventory = inventory.first { $0.shopItemId == catalogItem.id }
            let quantity = catalogItem.type == .streakFreeze
                ? streakFreezesAvailable
                : matchingInventory?.quantity ?? 0
            return catalogItem.shopItem(
                isOwned: quantity > 0 || matchingInventory != nil,
                isEquipped: matchingInventory?.isEquipped == true,
                inventoryQuantity: quantity
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

        if catalogItem.type == .streakFreeze {
            let streakState = try currentStreakState()
            streakState.streakFreezesAvailable += catalogItem.quantityGranted
            streakState.lastEvaluatedAt = .now
        } else if let existingInventoryItem, catalogItem.type.isConsumable {
            existingInventoryItem.quantity += catalogItem.quantityGranted
            existingInventoryItem.updatedAt = .now
        } else {
            let inventoryItem = InventoryItem(
                shopItemId: catalogItem.id,
                itemType: catalogItem.type,
                quantity: catalogItem.quantityGranted,
                isEquipped: false
            )
            modelContext.insert(inventoryItem)
        }

        try modelContext.save()

        return ShopPurchaseResult(
            item: catalogItem.shopItem(isOwned: true, isEquipped: false, inventoryQuantity: (try inventoryItem(for: itemId)?.quantity) ?? 1),
            remainingCoins: stats.coins
        )
    }

    func activateXPBoost(itemId: String? = nil) throws -> ActiveBoost {
        let selectedInventoryItem = try inventoryItems().first { inventoryItem in
            inventoryItem.itemType == .xpBoost
                && inventoryItem.quantity > 0
                && (itemId == nil || inventoryItem.shopItemId == itemId)
        }
        guard let inventoryItem = selectedInventoryItem,
              let catalogItem = catalog.first(where: { $0.id == inventoryItem.shopItemId }) else {
            throw ShopError.boostUnavailable
        }

        inventoryItem.quantity -= 1
        inventoryItem.updatedAt = .now
        if inventoryItem.quantity <= 0 {
            modelContext.delete(inventoryItem)
        }

        let now = Date()
        let duration = catalogItem.boostDuration
        let boost = try activeXPBoost(now: now)
        if let boost {
            boost.endDate = boost.endDate.addingTimeInterval(duration)
        } else {
            let newBoost = ActiveBoost(
                boostType: ShopItemType.xpBoost.rawValue,
                multiplier: 2,
                startDate: now,
                endDate: now.addingTimeInterval(duration)
            )
            modelContext.insert(newBoost)
        }

        try modelContext.save()
        guard let activeBoost = try activeXPBoost(now: now) else {
            throw ShopError.boostUnavailable
        }
        return activeBoost
    }

    func activeXPBoost(now: Date = .now) throws -> ActiveBoost? {
        try expireBoosts(now: now)
        var descriptor = FetchDescriptor<ActiveBoost>(
            predicate: #Predicate { boost in
                boost.boostType == "xpBoost" && boost.endDate > now
            },
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).first
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

    private func expireBoosts(now: Date) throws {
        let descriptor = FetchDescriptor<ActiveBoost>(
            predicate: #Predicate { boost in
                boost.endDate <= now
            }
        )
        let expiredBoosts = try modelContext.fetch(descriptor)
        guard !expiredBoosts.isEmpty else {
            return
        }

        for boost in expiredBoosts {
            modelContext.delete(boost)
        }
        try modelContext.save()
    }
}

private struct CatalogShopItem {
    let id: String
    let name: String
    let description: String
    let type: ShopItemType
    let price: Int
    var quantityGranted = 1
    var boostDuration: TimeInterval = 60 * 60

    func shopItem(isOwned: Bool, isEquipped: Bool, inventoryQuantity: Int) -> ShopItem {
        ShopItem(
            id: id,
            name: name,
            description: description,
            type: type,
            price: price,
            isOwned: isOwned,
            isEquipped: isEquipped,
            inventoryQuantity: inventoryQuantity
        )
    }
}
