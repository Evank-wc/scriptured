import Foundation
import SwiftData

@Model
final class ReadingSession {
    var id: UUID
    var date: Date
    var bibleLanguage: String
    var bookAbbrev: String
    var bookName: String
    var chapterIndex: Int
    var xpEarned: Int
    var coinsEarned: Int

    init(
        id: UUID = UUID(),
        date: Date = .now,
        bibleLanguage: String,
        bookAbbrev: String,
        bookName: String,
        chapterIndex: Int,
        xpEarned: Int,
        coinsEarned: Int
    ) {
        self.id = id
        self.date = date
        self.bibleLanguage = bibleLanguage
        self.bookAbbrev = bookAbbrev
        self.bookName = bookName
        self.chapterIndex = chapterIndex
        self.xpEarned = xpEarned
        self.coinsEarned = coinsEarned
    }
}
