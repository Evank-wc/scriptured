import Foundation
import SwiftData

@MainActor
protocol ReadingProgressServicing {
    @discardableResult
    func saveCompletedReadingSession(
        bibleLanguage: BibleLanguage,
        bookAbbrev: String,
        bookName: String,
        chapterIndex: Int,
        xpEarned: Int,
        coinsEarned: Int
    ) throws -> ReadingSession

    func isChapterCompletedToday(bookAbbrev: String, chapterIndex: Int) throws -> Bool
    func fetchAllReadingSessions() throws -> [ReadingSession]
    func totalChaptersRead() throws -> Int
    func todaysCompletedReadings() throws -> [ReadingSession]
    func removeCompletedReadingSessionForToday(bookAbbrev: String, chapterIndex: Int) throws
}

@MainActor
struct ReadingProgressService: ReadingProgressServicing {
    private let modelContext: ModelContext
    private let calendar: Calendar

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    @discardableResult
    func saveCompletedReadingSession(
        bibleLanguage: BibleLanguage,
        bookAbbrev: String,
        bookName: String,
        chapterIndex: Int,
        xpEarned: Int,
        coinsEarned: Int
    ) throws -> ReadingSession {
        if let existingSession = try completedSessionForToday(
            bookAbbrev: bookAbbrev,
            chapterIndex: chapterIndex
        ) {
            return existingSession
        }

        let session = ReadingSession(
            bibleLanguage: bibleLanguage.version.languageCode,
            bookAbbrev: bookAbbrev,
            bookName: bookName,
            chapterIndex: chapterIndex,
            xpEarned: xpEarned,
            coinsEarned: coinsEarned
        )

        modelContext.insert(session)
        try modelContext.save()
        return session
    }

    func isChapterCompletedToday(bookAbbrev: String, chapterIndex: Int) throws -> Bool {
        try completedSessionForToday(bookAbbrev: bookAbbrev, chapterIndex: chapterIndex) != nil
    }

    func fetchAllReadingSessions() throws -> [ReadingSession] {
        var descriptor = FetchDescriptor<ReadingSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    func totalChaptersRead() throws -> Int {
        try fetchAllReadingSessions().count
    }

    func todaysCompletedReadings() throws -> [ReadingSession] {
        let interval = todayInterval()
        let start = interval.start
        let end = interval.end
        var descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { session in
                session.date >= start && session.date < end
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    func removeCompletedReadingSessionForToday(bookAbbrev: String, chapterIndex: Int) throws {
        guard let session = try completedSessionForToday(
            bookAbbrev: bookAbbrev,
            chapterIndex: chapterIndex
        ) else {
            return
        }

        modelContext.delete(session)
        try modelContext.save()
    }

    private func completedSessionForToday(bookAbbrev: String, chapterIndex: Int) throws -> ReadingSession? {
        let interval = todayInterval()
        let start = interval.start
        let end = interval.end
        var descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { session in
                session.bookAbbrev == bookAbbrev
                && session.chapterIndex == chapterIndex
                && session.date >= start
                && session.date < end
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).first
    }

    private func todayInterval() -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        return (start, end)
    }
}
