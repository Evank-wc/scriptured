import SwiftData
import SwiftUI

struct BibleReaderView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BibleReaderViewModel
    @State private var isShowingSettings = false

    init(viewModel: BibleReaderViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Bible Unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.verses.isEmpty {
                    ContentUnavailableView(
                        "No Verses Loaded",
                        systemImage: "book.closed",
                        description: Text("Choose a book and chapter to begin reading")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    verseList
                }

                bottomControls
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    navigationPickerHeader
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Bible reader settings")
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                BibleReaderSettingsView(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
        }
        .task {
            viewModel.configure(
                progressService: ReadingProgressService(modelContext: modelContext),
                progressionService: ProgressionService(modelContext: modelContext)
            )
            viewModel.load()
        }
        .alert(
            "Reading Progress",
            isPresented: Binding(
                get: { viewModel.rewardMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.rewardMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.rewardMessage = nil
            }
        } message: {
            Text(viewModel.rewardMessage ?? "")
        }
    }

    private var navigationPickerHeader: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(viewModel.books) { book in
                    Button(book.name) {
                        viewModel.selectBook(abbrev: book.abbrev)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedBook?.name ?? "Book")
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 158, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .disabled(viewModel.books.isEmpty)

            Menu {
                ForEach(viewModel.chapters) { chapter in
                    Button("\(chapter.number)") {
                        viewModel.selectChapter(number: chapter.number)
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text("\(viewModel.selectedChapterNumber)")
                        .monospacedDigit()
                        .lineLimit(1)
                        .frame(width: 24, alignment: .trailing)

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .disabled(viewModel.chapters.isEmpty)
        }
        .font(.headline.weight(.semibold))
        .foregroundStyle(Color(.label))
        .frame(width: 224, alignment: .leading)
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

    private var bottomControls: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.moveToPreviousChapter()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!viewModel.canMoveToPreviousChapter)
            .accessibilityLabel("Previous chapter")

            Spacer()

            Button {
                viewModel.toggleCurrentChapterRead()
            } label: {
                Label(
                    viewModel.isCurrentChapterRead ? "Mark Unread" : "Mark Read",
                    systemImage: viewModel.isCurrentChapterRead ? "arrow.uturn.backward.circle" : "checkmark.circle"
                )
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.selectedBookAbbrev == nil || viewModel.verses.isEmpty)

            Spacer()

            Button {
                viewModel.moveToNextChapter()
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!viewModel.canMoveToNextChapter)
            .accessibilityLabel("Next chapter")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
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

private struct BibleReaderSettingsView: View {
    @Bindable var viewModel: BibleReaderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("Language", selection: languageSelection) {
                        ForEach(viewModel.availableLanguages) { language in
                            Text(language.version.displayName)
                                .tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Text Size") {
                    HStack(spacing: 12) {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundStyle(.secondary)

                        Slider(value: $viewModel.fontSize, in: 14...28, step: 1)

                        Image(systemName: "textformat.size.larger")
                            .foregroundStyle(.secondary)
                    }

                    Text("Preview text")
                        .font(.system(size: viewModel.fontSize, weight: .regular, design: .serif))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reader Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
