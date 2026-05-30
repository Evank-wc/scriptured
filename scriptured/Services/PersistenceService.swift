import Foundation

protocol PersistenceService {
    func prepareLocalStore() async throws
}

struct LocalPersistenceService: PersistenceService {
    func prepareLocalStore() async throws {
    }
}
