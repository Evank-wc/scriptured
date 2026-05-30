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

    var canMoveToPreviousChapter: Bool {
        guard let selectedBookAbbrev,
              let bookIndex = books.firstIndex(where: { $0.abbrev == selectedBookAbbrev }) else {
            return false
        }

        return selectedChapterNumber > 1 || bookIndex > books.startIndex
    }

    var canMoveToNextChapter: Bool {
        guard let selectedBookAbbrev,
              let bookIndex = books.firstIndex(where: { $0.abbrev == selectedBookAbbrev }) else {
            return false
        }

        if selectedChapterNumber < chapters.count {
            return true
        }

        return bookIndex < books.index(before: books.endIndex)
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
        let previousBookAbbrev = selectedBookAbbrev
        let previousChapterNumber = selectedChapterNumber

        do {
            bibleService.selectLanguage(language)
            selectedLanguage = language
            books = try bibleService.allBooks()

            if let previousBookAbbrev,
               books.contains(where: { $0.abbrev == previousBookAbbrev }) {
                selectedBookAbbrev = previousBookAbbrev
                selectedChapterNumber = previousChapterNumber
                try reloadChaptersAndVerses(resetChapter: false)
            } else {
                selectedBookAbbrev = books.first?.abbrev
                try reloadChaptersAndVerses(resetChapter: true)
            }

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

    func moveToPreviousChapter() {
        guard canMoveToPreviousChapter else {
            return
        }

        if selectedChapterNumber > 1 {
            selectChapter(number: selectedChapterNumber - 1)
            return
        }

        guard let currentBookAbbrev = selectedBookAbbrev,
              let currentIndex = books.firstIndex(where: { $0.abbrev == currentBookAbbrev }),
              currentIndex > books.startIndex else {
            return
        }

        let previousBook = books[books.index(before: currentIndex)]
        selectedBookAbbrev = previousBook.abbrev

        do {
            chapters = try bibleService.chapters(for: previousBook.abbrev)
            selectedChapterNumber = chapters.last?.number ?? 1
            try reloadVerses()
            errorMessage = nil
        } catch {
            verses = []
            errorMessage = error.localizedDescription
        }
    }

    func moveToNextChapter() {
        guard canMoveToNextChapter else {
            return
        }

        if selectedChapterNumber < chapters.count {
            selectChapter(number: selectedChapterNumber + 1)
            return
        }

        guard let currentBookAbbrev = selectedBookAbbrev,
              let currentIndex = books.firstIndex(where: { $0.abbrev == currentBookAbbrev }),
              currentIndex < books.index(before: books.endIndex) else {
            return
        }

        let nextBook = books[books.index(after: currentIndex)]
        selectedBookAbbrev = nextBook.abbrev

        do {
            try reloadChaptersAndVerses(resetChapter: true)
            errorMessage = nil
        } catch {
            verses = []
            errorMessage = error.localizedDescription
        }
    }

    func toggleCurrentChapterRead() {
        guard let selectedBookAbbrev else {
            return
        }

        let id = chapterID(bookAbbrev: selectedBookAbbrev, chapterNumber: selectedChapterNumber)
        if readChapterIDs.contains(id) {
            readChapterIDs.remove(id)
        } else {
            readChapterIDs.insert(id)
        }
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
        "\(bookAbbrev)-\(chapterNumber)"
    }
}
