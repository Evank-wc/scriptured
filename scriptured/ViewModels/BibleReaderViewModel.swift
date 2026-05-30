import Foundation
import Observation

@MainActor
@Observable
final class BibleReaderViewModel {
    let availableLanguages = BibleLanguage.allCases

    private let bibleService: any BibleServicing
    private let readerStateStore: UserDefaults
    private var progressService: (any ReadingProgressServicing)?
    private var progressionService: (any ProgressionServicing)?
    private var completedTodayChapterIDs: Set<String> = []

    private(set) var selectedLanguage: BibleLanguage
    private(set) var books: [BibleBook] = []
    private(set) var chapters: [BibleChapter] = []
    private(set) var verses: [BibleVerse] = []
    private(set) var selectedBookAbbrev: String?
    private(set) var selectedChapterNumber = 1
    private(set) var errorMessage: String?
    var rewardMessage: String?

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

        return completedTodayChapterIDs.contains(
            chapterID(bookAbbrev: selectedBookAbbrev, chapterNumber: selectedChapterNumber)
        )
    }

    convenience init() {
        self.init(bibleService: BibleService())
    }

    init(bibleService: any BibleServicing, readerStateStore: UserDefaults = .standard) {
        self.bibleService = bibleService
        self.readerStateStore = readerStateStore

        let savedLanguage = readerStateStore.string(forKey: ReaderStateKey.language.rawValue)
            .flatMap(BibleLanguage.init(rawValue:))
            ?? bibleService.selectedLanguage
        bibleService.selectLanguage(savedLanguage)

        self.selectedLanguage = savedLanguage
        self.selectedBookAbbrev = readerStateStore.string(forKey: ReaderStateKey.bookAbbrev.rawValue)

        let savedChapterNumber = readerStateStore.integer(forKey: ReaderStateKey.chapterNumber.rawValue)
        self.selectedChapterNumber = max(savedChapterNumber, 1)
    }

    func configure(
        progressService: any ReadingProgressServicing,
        progressionService: any ProgressionServicing
    ) {
        self.progressService = progressService
        self.progressionService = progressionService
        refreshCompletedReadingsForToday()
    }

    func load() {
        do {
            selectedLanguage = bibleService.selectedLanguage
            books = try bibleService.allBooks()

            if let selectedBookAbbrev,
               books.contains(where: { $0.abbrev == selectedBookAbbrev }) {
                try reloadChaptersAndVerses(resetChapter: false)
            } else {
                selectedBookAbbrev = books.first?.abbrev
                try reloadChaptersAndVerses(resetChapter: true)
            }

            persistReaderState()
            refreshCompletedReadingsForToday()
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

            persistReaderState()
            refreshCompletedReadingsForToday()
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
            persistReaderState()
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
            persistReaderState()
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
            persistReaderState()
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
            persistReaderState()
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

        do {
            if isCurrentChapterRead {
                try progressService?.removeCompletedReadingSessionForToday(
                    bookAbbrev: selectedBookAbbrev,
                    chapterIndex: selectedChapterNumber
                )
                completedTodayChapterIDs.remove(id)
                rewardMessage = nil
            } else if let selectedBook {
                let claimResult = try progressionService?.claimChapterCompletionReward(
                    language: selectedLanguage,
                    bookAbbrev: selectedBook.abbrev,
                    chapterIndex: selectedChapterNumber,
                    xpAwarded: 10,
                    coinsAwarded: 1
                )

                try progressService?.saveCompletedReadingSession(
                    bibleLanguage: selectedLanguage,
                    bookAbbrev: selectedBook.abbrev,
                    bookName: selectedBook.name,
                    chapterIndex: selectedChapterNumber,
                    xpEarned: claimResult?.xpAwarded ?? 0,
                    coinsEarned: claimResult?.coinsAwarded ?? 0
                )
                completedTodayChapterIDs.insert(id)
                rewardMessage = rewardMessage(for: claimResult)
            }

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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

    private func refreshCompletedReadingsForToday() {
        guard let progressService else {
            return
        }

        do {
            completedTodayChapterIDs = Set(
                try progressService.todaysCompletedReadings().map {
                    chapterID(bookAbbrev: $0.bookAbbrev, chapterNumber: $0.chapterIndex)
                }
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearReaderContent() {
        books = []
        chapters = []
        verses = []
        selectedBookAbbrev = nil
        selectedChapterNumber = 1
    }

    private func rewardMessage(for claimResult: RewardClaimResult?) -> String {
        guard let claimResult else {
            return "Chapter marked read. Rewards already claimed."
        }

        if claimResult.didAwardRewards {
            return "+\(claimResult.xpAwarded) XP and +\(claimResult.coinsAwarded) coin earned."
        }

        return "Chapter marked read. Rewards already claimed."
    }

    private func persistReaderState() {
        readerStateStore.set(selectedLanguage.rawValue, forKey: ReaderStateKey.language.rawValue)
        readerStateStore.set(selectedBookAbbrev, forKey: ReaderStateKey.bookAbbrev.rawValue)
        readerStateStore.set(selectedChapterNumber, forKey: ReaderStateKey.chapterNumber.rawValue)
    }

    private func chapterID(bookAbbrev: String, chapterNumber: Int) -> String {
        "\(bookAbbrev)-\(chapterNumber)"
    }

    private enum ReaderStateKey: String {
        case language = "bibleReader.language"
        case bookAbbrev = "bibleReader.bookAbbrev"
        case chapterNumber = "bibleReader.chapterNumber"
    }
}
