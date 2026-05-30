import Foundation

struct BibleVersion: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let languageCode: String
    let resourceName: String
}

struct BibleBook: Identifiable, Hashable, Codable {
    let abbrev: String
    let book: String
    let chapters: [[String]]

    var id: String { abbrev }
    var name: String { book }

    init(abbrev: String, book: String, chapters: [[String]]) {
        self.abbrev = abbrev
        self.book = book
        self.chapters = chapters
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let abbrev = try container.decode(String.self, forKey: .abbrev)
        let chapters = try container.decode([[String]].self, forKey: .chapters)
        let book = try container.decodeIfPresent(String.self, forKey: .book)
            ?? BibleBookNameProvider.englishName(for: abbrev)
            ?? abbrev.uppercased()

        self.init(abbrev: abbrev, book: book, chapters: chapters)
    }

    func named(for language: BibleLanguage) -> BibleBook {
        BibleBook(
            abbrev: abbrev,
            book: BibleBookNameProvider.name(for: abbrev, language: language) ?? book,
            chapters: chapters
        )
    }

    private enum CodingKeys: String, CodingKey {
        case abbrev
        case book
        case chapters
    }
}

struct BibleChapter: Identifiable, Hashable, Codable {
    let id: String
    let bookAbbrev: String
    let number: Int
    let verses: [String]
}

struct BibleVerse: Identifiable, Hashable, Codable {
    let id: String
    let bookAbbrev: String
    let chapterNumber: Int
    let number: Int
    let text: String
}

enum BibleLanguage: String, CaseIterable, Identifiable, Codable {
    case english
    case chinese

    var id: String { rawValue }

    var version: BibleVersion {
        switch self {
        case .english:
            BibleVersion(
                id: "en_bbe",
                displayName: "English",
                languageCode: "en",
                resourceName: "en_bbe"
            )
        case .chinese:
            BibleVersion(
                id: "zh_cuv",
                displayName: "Chinese",
                languageCode: "zh",
                resourceName: "zh_cuv"
            )
        }
    }
}

enum BibleBookNameProvider {
    private static let englishNames: [String: String] = [
        "gn": "Genesis",
        "ex": "Exodus",
        "lv": "Leviticus",
        "nm": "Numbers",
        "dt": "Deuteronomy",
        "js": "Joshua",
        "jud": "Judges",
        "judg": "Judges",
        "rt": "Ruth",
        "1sm": "1 Samuel",
        "2sm": "2 Samuel",
        "1kgs": "1 Kings",
        "2kgs": "2 Kings",
        "1ch": "1 Chronicles",
        "2ch": "2 Chronicles",
        "ezr": "Ezra",
        "ne": "Nehemiah",
        "et": "Esther",
        "job": "Job",
        "ps": "Psalms",
        "prv": "Proverbs",
        "ec": "Ecclesiastes",
        "so": "Song of Solomon",
        "is": "Isaiah",
        "jr": "Jeremiah",
        "lm": "Lamentations",
        "ez": "Ezekiel",
        "dn": "Daniel",
        "ho": "Hosea",
        "jl": "Joel",
        "am": "Amos",
        "ob": "Obadiah",
        "jn": "Jonah",
        "mi": "Micah",
        "na": "Nahum",
        "hk": "Habakkuk",
        "zp": "Zephaniah",
        "hg": "Haggai",
        "zc": "Zechariah",
        "ml": "Malachi",
        "mt": "Matthew",
        "mk": "Mark",
        "lk": "Luke",
        "jo": "John",
        "act": "Acts",
        "rm": "Romans",
        "1co": "1 Corinthians",
        "2co": "2 Corinthians",
        "gl": "Galatians",
        "eph": "Ephesians",
        "ph": "Philippians",
        "cl": "Colossians",
        "1ts": "1 Thessalonians",
        "2ts": "2 Thessalonians",
        "1tm": "1 Timothy",
        "2tm": "2 Timothy",
        "tt": "Titus",
        "phm": "Philemon",
        "hb": "Hebrews",
        "jm": "James",
        "1pe": "1 Peter",
        "2pe": "2 Peter",
        "1jo": "1 John",
        "2jo": "2 John",
        "3jo": "3 John",
        "jd": "Jude",
        "re": "Revelation"
    ]

    private static let chineseNames: [String: String] = [
        "gn": "創世記",
        "ex": "出埃及記",
        "lv": "利未記",
        "nm": "民數記",
        "dt": "申命記",
        "js": "約書亞記",
        "jud": "士師記",
        "judg": "士師記",
        "rt": "路得記",
        "1sm": "撒母耳記上",
        "2sm": "撒母耳記下",
        "1kgs": "列王紀上",
        "2kgs": "列王紀下",
        "1ch": "歷代志上",
        "2ch": "歷代志下",
        "ezr": "以斯拉記",
        "ne": "尼希米記",
        "et": "以斯帖記",
        "job": "約伯記",
        "ps": "詩篇",
        "prv": "箴言",
        "ec": "傳道書",
        "so": "雅歌",
        "is": "以賽亞書",
        "jr": "耶利米書",
        "lm": "耶利米哀歌",
        "ez": "以西結書",
        "dn": "但以理書",
        "ho": "何西阿書",
        "jl": "約珥書",
        "am": "阿摩司書",
        "ob": "俄巴底亞書",
        "jn": "約拿書",
        "mi": "彌迦書",
        "na": "那鴻書",
        "hk": "哈巴谷書",
        "zp": "西番雅書",
        "hg": "哈該書",
        "zc": "撒迦利亞書",
        "ml": "瑪拉基書",
        "mt": "馬太福音",
        "mk": "馬可福音",
        "lk": "路加福音",
        "jo": "約翰福音",
        "act": "使徒行傳",
        "rm": "羅馬書",
        "1co": "哥林多前書",
        "2co": "哥林多後書",
        "gl": "加拉太書",
        "eph": "以弗所書",
        "ph": "腓立比書",
        "cl": "歌羅西書",
        "1ts": "帖撒羅尼迦前書",
        "2ts": "帖撒羅尼迦後書",
        "1tm": "提摩太前書",
        "2tm": "提摩太後書",
        "tt": "提多書",
        "phm": "腓利門書",
        "hb": "希伯來書",
        "jm": "雅各書",
        "1pe": "彼得前書",
        "2pe": "彼得後書",
        "1jo": "約翰一書",
        "2jo": "約翰二書",
        "3jo": "約翰三書",
        "jd": "猶大書",
        "re": "啟示錄"
    ]

    static func name(for abbrev: String, language: BibleLanguage) -> String? {
        switch language {
        case .english:
            englishName(for: abbrev)
        case .chinese:
            chineseNames[abbrev]
        }
    }

    static func englishName(for abbrev: String) -> String? {
        englishNames[abbrev]
    }
}
