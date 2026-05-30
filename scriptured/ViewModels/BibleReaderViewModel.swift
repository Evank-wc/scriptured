import Foundation
import Observation

@MainActor
@Observable
final class BibleReaderViewModel {
    let availableLanguages = BibleLanguage.allCases

    private let bibleService: any BibleServicing
    private var readChapterIDs: Set<String> = []

    private(set) var selectedLanguage: BibleLanguage
    private(set) var books: [BibleBook] = []
    private(set) var chapters: [BibleChapter] = []
    private(set) var verses: [BibleVerse] = []
    private(set) var selectedBookAbbrev: String?
    private(set) var selectedChapterNumber = 1
    private(set) var errorMessage: String?

    var fontSize = 18.0

    var selectedBook: BibleBook? {
        books.first { $0.abbrev == selectedBookAbbrev }
    }

    var currentReference: String {
        guard let selectedBook else {
            return "Bible"
        }

        return "\(selectedBook.name) \(selectedChapterNumber)"
    }

    var isCurrentChapterRead: Bool {
        guard let selectedBookAbbrev else {
            return false
        }

        return readChapterIDs.contains(chapterID(bookAbbrev: selectedBookAbbrev, chapterNumber: selectedChapterNumber))
    }

    convenience init() {
        self.init(bibleService: BibleService())
    }

    init(bibleService: any BibleServicing) {
        self.bibleService = bibleService
        self.selectedLanguage = bibleService.selectedLanguage
    }

    func load() {
        do {
            selectedLanguage = bibleService.selectedLanguage
            books = try bibleService.allBooks()
            selectedBookAbbrev = selectedBookAbbrev ?? books.first?.abbrev
            try reloadChaptersAndVerses(resetChapter: true)
            errorMessage = nil
        } catch {
            clearReaderContent()
            errorMessage = error.localizedDescription
        }
    }

    func selectLanguage(_ language: BibleLanguage) {
        do {
            bibleService.selectLanguage(language)
            selectedLanguage = language
            books = try bibleService.allBooks()
            selectedBookAbbrev = books.first?.abbrev
            try reloadChaptersAndVerses(resetChapter: true)
            errorMessage = nil
        } catch {
            clearReaderContent()
            errorMessage = error.localizedDescription
        }
    }

    func selectBook(abbrev: String) {
        guard selectedBookAbbrev != abbrev else {
            return
        }

        selectedBookAbbrev = abbrev
        do {
            try reloadChaptersAndVerses(resetChapter: true)
            errorMessage = nil
        } catch {
            chapters = []
            verses = []
            errorMessage = error.localizedDescription
        }
    }

    func selectChapter(number: Int) {
        guard selectedChapterNumber != number else {
            return
        }

        selectedChapterNumber = number
        do {
            try reloadVerses()
            errorMessage = nil
        } catch {
            verses = []
            errorMessage = error.localizedDescription
        }
    }

    func markCurrentChapterAsRead() {
        guard let selectedBookAbbrev else {
            return
        }

        readChapterIDs.insert(chapterID(bookAbbrev: selectedBookAbbrev, chapterNumber: selectedChapterNumber))
    }

    private func reloadChaptersAndVerses(resetChapter: Bool) throws {
        guard let selectedBookAbbrev else {
            chapters = []
            verses = []
            return
        }

        chapters = try bibleService.chapters(for: selectedBookAbbrev)

        if resetChapter || !chapters.contains(where: { $0.number == selectedChapterNumber }) {
            selectedChapterNumber = chapters.first?.number ?? 1
        }

        try reloadVerses()
    }

    private func reloadVerses() throws {
        guard let selectedBookAbbrev else {
            verses = []
            return
        }

        verses = try bibleService.verses(
            for: selectedBookAbbrev,
            chapterNumber: selectedChapterNumber
        )
    }

    private func clearReaderContent() {
        books = []
        chapters = []
        verses = []
        selectedBookAbbrev = nil
        selectedChapterNumber = 1
    }

    private func chapterID(bookAbbrev: String, chapterNumber: Int) -> String {
        "\(selectedLanguage.id)-\(bookAbbrev)-\(chapterNumber)"
    }
}
