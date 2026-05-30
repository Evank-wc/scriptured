import Foundation

protocol AuthenticationService {
    func currentUser() async throws -> UserProfile?
}

struct AppleAuthenticationService: AuthenticationService {
    func currentUser() async throws -> UserProfile? {
        nil
    }
}
