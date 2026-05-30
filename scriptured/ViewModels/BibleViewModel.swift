import Foundation
import Observation

@MainActor
@Observable
final class BibleViewModel {
    let title = "Bible"
    let availableLanguages = BibleLanguage.allCases

    private let bibleService: any BibleServicing

    private(set) var selectedLanguage: BibleLanguage
    private(set) var books: [BibleBook] = []
    private(set) var errorMessage: String?

    convenience init() {
        self.init(bibleService: BibleService())
    }

    init(bibleService: any BibleServicing) {
        self.bibleService = bibleService
        self.selectedLanguage = bibleService.selectedLanguage
    }

    func loadBooks() {
        do {
            selectedLanguage = bibleService.selectedLanguage
            books = try bibleService.allBooks()
            errorMessage = nil
        } catch {
            books = []
            errorMessage = error.localizedDescription
        }
    }

    func selectLanguage(_ language: BibleLanguage) {
        bibleService.selectLanguage(language)
        selectedLanguage = language
        loadBooks()
    }

    func chapters(for book: BibleBook) throws -> [BibleChapter] {
        try bibleService.chapters(for: book.abbrev)
    }

    func verses(for book: BibleBook, chapterNumber: Int) throws -> [BibleVerse] {
        try bibleService.verses(for: book.abbrev, chapterNumber: chapterNumber)
    }
}
