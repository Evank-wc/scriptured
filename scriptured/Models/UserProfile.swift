import Foundation

struct UserProfile: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let emailAddress: String?
}
