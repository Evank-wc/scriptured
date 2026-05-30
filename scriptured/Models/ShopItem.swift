import Foundation

struct ShopItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let priceDisplayText: String
}
