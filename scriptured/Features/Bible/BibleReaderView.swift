import SwiftUI

struct BibleReaderView: View {
    @State private var viewModel: BibleReaderViewModel

    init(viewModel: BibleReaderViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                readerControls

                if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Bible Unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if viewModel.verses.isEmpty {
                    ContentUnavailableView(
                        "No Verses Loaded",
                        systemImage: "book.closed",
                        description: Text("Choose a book and chapter to begin reading")
                    )
                } else {
                    verseList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.currentReference)
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            viewModel.load()
        }
    }

    private var readerControls: some View {
        VStack(spacing: 14) {
            Picker("Language", selection: languageSelection) {
                ForEach(viewModel.availableLanguages) { language in
                    Text(language.version.displayName)
                        .tag(language)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Picker("Book", selection: bookSelection) {
                    ForEach(viewModel.books) { book in
                        Text(book.name)
                            .tag(book.abbrev)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(viewModel.books.isEmpty)

                Picker("Chapter", selection: chapterSelection) {
                    ForEach(viewModel.chapters) { chapter in
                        Text("Chapter \(chapter.number)")
                            .tag(chapter.number)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(viewModel.chapters.isEmpty)
            }

            HStack(spacing: 12) {
                Image(systemName: "textformat.size.smaller")
                    .foregroundStyle(.secondary)

                Slider(value: $viewModel.fontSize, in: 14...28, step: 1)

                Image(systemName: "textformat.size.larger")
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.markCurrentChapterAsRead()
            } label: {
                Label(
                    viewModel.isCurrentChapterRead ? "Chapter Read" : "Mark Chapter Read",
                    systemImage: viewModel.isCurrentChapterRead ? "checkmark.circle.fill" : "checkmark.circle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedBookAbbrev == nil || viewModel.verses.isEmpty || viewModel.isCurrentChapterRead)
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    private var verseList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.verses) { verse in
                        VerseRow(verse: verse, fontSize: viewModel.fontSize)
                            .id(verse.id)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
            }
            .onChange(of: viewModel.selectedChapterNumber) { _, _ in
                scrollToFirstVerse(using: proxy)
            }
            .onChange(of: viewModel.selectedBookAbbrev) { _, _ in
                scrollToFirstVerse(using: proxy)
            }
        }
    }

    private var languageSelection: Binding<BibleLanguage> {
        Binding(
            get: { viewModel.selectedLanguage },
            set: { language in
                viewModel.selectLanguage(language)
            }
        )
    }

    private var bookSelection: Binding<String> {
        Binding(
            get: { viewModel.selectedBookAbbrev ?? "" },
            set: { abbrev in
                viewModel.selectBook(abbrev: abbrev)
            }
        )
    }

    private var chapterSelection: Binding<Int> {
        Binding(
            get: { viewModel.selectedChapterNumber },
            set: { chapterNumber in
                viewModel.selectChapter(number: chapterNumber)
            }
        )
    }

    private func scrollToFirstVerse(using proxy: ScrollViewProxy) {
        guard let firstVerse = viewModel.verses.first else {
            return
        }

        withAnimation(.snappy) {
            proxy.scrollTo(firstVerse.id, anchor: .top)
        }
    }
}

private struct VerseRow: View {
    let verse: BibleVerse
    let fontSize: Double

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(verse.number)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)

            Text(verse.text)
                .font(.system(size: fontSize, weight: .regular, design: .serif))
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BibleReaderView(viewModel: BibleReaderViewModel())
}
