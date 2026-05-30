import Foundation

@MainActor
protocol BibleServicing {
    var selectedLanguage: BibleLanguage { get }

    func availableVersions() -> [BibleVersion]
    func selectLanguage(_ language: BibleLanguage)
    func allBooks() throws -> [BibleBook]
    func chapters(for bookAbbrev: String) throws -> [BibleChapter]
    func verses(for bookAbbrev: String, chapterNumber: Int) throws -> [BibleVerse]
}

@MainActor
final class BibleService: BibleServicing {
    private let loader: any BibleJSONLoading
    private let decoder: JSONDecoder
    private var booksByLanguage: [BibleLanguage: [BibleBook]] = [:]

    private(set) var selectedLanguage: BibleLanguage

    convenience init() {
        self.init(
            loader: BundleBibleJSONLoader(bundle: .main),
            decoder: JSONDecoder(),
            selectedLanguage: .english
        )
    }

    init(
        loader: any BibleJSONLoading,
        decoder: JSONDecoder,
        selectedLanguage: BibleLanguage
    ) {
        self.loader = loader
        self.decoder = decoder
        self.selectedLanguage = selectedLanguage
    }

    func availableVersions() -> [BibleVersion] {
        BibleLanguage.allCases.map { $0.version }
    }

    func selectLanguage(_ language: BibleLanguage) {
        selectedLanguage = language
    }

    func allBooks() throws -> [BibleBook] {
        try books(for: selectedLanguage)
    }

    func chapters(for bookAbbrev: String) throws -> [BibleChapter] {
        let book = try book(matching: bookAbbrev)

        return book.chapters.enumerated().map { index, verses in
            let chapterNumber = index + 1

            return BibleChapter(
                id: "\(book.abbrev)-\(chapterNumber)",
                bookAbbrev: book.abbrev,
                number: chapterNumber,
                verses: verses
            )
        }
    }

    func verses(for bookAbbrev: String, chapterNumber: Int) throws -> [BibleVerse] {
        let book = try book(matching: bookAbbrev)
        guard book.chapters.indices.contains(chapterNumber - 1) else {
            throw BibleServiceError.chapterNotFound(bookAbbrev: bookAbbrev, chapterNumber: chapterNumber)
        }

        return book.chapters[chapterNumber - 1].enumerated().map { index, text in
            let verseNumber = index + 1

            return BibleVerse(
                id: "\(book.abbrev)-\(chapterNumber)-\(verseNumber)",
                bookAbbrev: book.abbrev,
                chapterNumber: chapterNumber,
                number: verseNumber,
                text: text
            )
        }
    }

    private func book(matching bookAbbrev: String) throws -> BibleBook {
        guard let book = try books(for: selectedLanguage).first(where: { $0.abbrev == bookAbbrev }) else {
            throw BibleServiceError.bookNotFound(bookAbbrev: bookAbbrev)
        }

        return book
    }

    private func books(for language: BibleLanguage) throws -> [BibleBook] {
        if let cachedBooks = booksByLanguage[language] {
            return cachedBooks
        }

        let version = language.version
        let data = try loader.loadResource(named: version.resourceName)

        do {
            let books = try decoder.decode([BibleBook].self, from: data)
                .map { $0.named(for: language) }
            booksByLanguage[language] = books
            return books
        } catch {
            throw BibleServiceError.malformedJSON(resourceName: version.resourceName, underlyingError: error)
        }
    }
}

enum BibleServiceError: Error, LocalizedError, Equatable {
    case missingResource(resourceName: String)
    case unreadableResource(resourceName: String, underlyingError: any Error)
    case malformedJSON(resourceName: String, underlyingError: any Error)
    case bookNotFound(bookAbbrev: String)
    case chapterNotFound(bookAbbrev: String, chapterNumber: Int)

    static func == (lhs: BibleServiceError, rhs: BibleServiceError) -> Bool {
        switch (lhs, rhs) {
        case let (.missingResource(lhsResource), .missingResource(rhsResource)):
            lhsResource == rhsResource
        case let (.unreadableResource(lhsResource, _), .unreadableResource(rhsResource, _)):
            lhsResource == rhsResource
        case let (.malformedJSON(lhsResource, _), .malformedJSON(rhsResource, _)):
            lhsResource == rhsResource
        case let (.bookNotFound(lhsBook), .bookNotFound(rhsBook)):
            lhsBook == rhsBook
        case let (.chapterNotFound(lhsBook, lhsChapter), .chapterNotFound(rhsBook, rhsChapter)):
            lhsBook == rhsBook && lhsChapter == rhsChapter
        default:
            false
        }
    }

    var errorDescription: String? {
        switch self {
        case let .missingResource(resourceName):
            "Missing Bible JSON resource: \(resourceName).json"
        case let .unreadableResource(resourceName, underlyingError):
            "Unable to read Bible JSON resource \(resourceName).json: \(underlyingError.localizedDescription)"
        case let .malformedJSON(resourceName, underlyingError):
            "Malformed Bible JSON resource \(resourceName).json: \(underlyingError.localizedDescription)"
        case let .bookNotFound(bookAbbrev):
            "Bible book not found: \(bookAbbrev)"
        case let .chapterNotFound(bookAbbrev, chapterNumber):
            "Bible chapter not found: \(bookAbbrev) \(chapterNumber)"
        }
    }
}
