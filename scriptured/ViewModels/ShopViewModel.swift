import Foundation
import Observation

@MainActor
@Observable
final class ShopViewModel {
    let title = "Shop"

    private var shopService: ShopService?

    private(set) var coins = 0
    private(set) var items: [ShopItem] = []
    private(set) var activeXPBoostEndDate: Date?
    private(set) var activeXPBoostMultiplier: Double?
    private(set) var message: String?
    private(set) var errorMessage: String?

    var powerUps: [ShopItem] {
        items.filter { $0.type == .streakFreeze || $0.type == .xpBoost }
    }

    var outfits: [ShopItem] {
        items.filter { $0.type == .outfit }
    }

    var frames: [ShopItem] {
        items.filter { $0.type == .profileFrame }
    }

    var titles: [ShopItem] {
        items.filter { $0.type == .title }
    }

    func configure(shopService: ShopService) {
        self.shopService = shopService
        loadShop()
    }

    func loadShop() {
        guard let shopService else {
            return
        }

        do {
            items = try shopService.shopItems()
            coins = try shopService.currentCoins()
            let boost = try shopService.activeXPBoost()
            activeXPBoostEndDate = boost?.endDate
            activeXPBoostMultiplier = boost?.multiplier
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ item: ShopItem) {
        guard let shopService else {
            errorMessage = "Shop service is not ready."
            return
        }

        do {
            let result = try shopService.purchase(itemId: item.id)
            coins = result.remainingCoins
            items = try shopService.shopItems()
            message = "Purchased \(result.item.name)."
            errorMessage = nil
            scheduleMessageDismissal()
            ReadingActivitySignal.send()
        } catch {
            message = nil
            errorMessage = error.localizedDescription
        }
    }

    func activateXPBoost(_ item: ShopItem) {
        guard let shopService else {
            errorMessage = "Shop service is not ready."
            return
        }

        do {
            let boost = try shopService.activateXPBoost(itemId: item.id)
            activeXPBoostEndDate = boost.endDate
            activeXPBoostMultiplier = boost.multiplier
            items = try shopService.shopItems()
            message = "XP boost active."
            errorMessage = nil
            scheduleMessageDismissal()
            ReadingActivitySignal.send()
        } catch {
            message = nil
            errorMessage = error.localizedDescription
        }
    }

    func boostRemainingText(at date: Date = .now) -> String? {
        guard let activeXPBoostEndDate, activeXPBoostEndDate > date else {
            return nil
        }

        let remainingSeconds = Int(activeXPBoostEndDate.timeIntervalSince(date))
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func equip(_ item: ShopItem) {
        guard let shopService else {
            errorMessage = "Shop service is not ready."
            return
        }

        do {
            try shopService.equip(itemId: item.id)
            items = try shopService.shopItems()
            message = "Equipped \(item.name)."
            errorMessage = nil
            scheduleMessageDismissal()
        } catch {
            message = nil
            errorMessage = error.localizedDescription
            scheduleMessageDismissal()
        }
    }

    func clearMessage() {
        message = nil
        errorMessage = nil
    }

    private func scheduleMessageDismissal() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            clearMessage()
        }
    }
}
