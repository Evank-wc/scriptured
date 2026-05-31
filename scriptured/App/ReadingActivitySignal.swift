import Foundation

enum ReadingActivitySignal {
    static let revisionKey = "readingActivity.revision"

    static func send(store: UserDefaults = .standard) {
        let nextRevision = store.integer(forKey: revisionKey) + 1
        store.set(nextRevision, forKey: revisionKey)
    }
}
