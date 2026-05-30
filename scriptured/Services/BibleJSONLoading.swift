import Foundation

protocol BibleJSONLoading {
    func loadResource(named resourceName: String) throws -> Data
}

struct BundleBibleJSONLoader: BibleJSONLoading {
    private let bundle: Bundle

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func loadResource(named resourceName: String) throws -> Data {
        guard let url = resourceURL(named: resourceName) else {
            throw BibleServiceError.missingResource(resourceName: resourceName)
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            throw BibleServiceError.unreadableResource(resourceName: resourceName, underlyingError: error)
        }
    }

    private func resourceURL(named resourceName: String) -> URL? {
        bundle.url(forResource: resourceName, withExtension: "json")
            ?? bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "Bible")
            ?? bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "Resources/Bible")
    }
}
