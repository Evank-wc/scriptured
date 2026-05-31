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
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    if let errorMessage = viewModel.errorMessage {
                        EmptyStateView(
                            title: "Bible unavailable",
                            message: errorMessage,
                            systemImage: "exclamationmark.triangle"
                        )
                    } else if viewModel.verses.isEmpty {
                        EmptyStateView(
                            title: "No verses loaded",
                            message: "Choose a book and chapter to begin reading.",
                            systemImage: "book.closed"
                        )
                    } else {
                        readerHeader
                        verseList
                    }

                    bottomControls
                }
                .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())

                if let rewardMessage = viewModel.rewardMessage {
                    RewardBanner(
                        message: rewardMessage,
                        systemImage: rewardMessage.contains("+") ? "sparkles" : "checkmark.seal.fill",
                        tint: rewardMessage.contains("+") ? AppTheme.Colors.sunrise : AppTheme.Colors.meadow
                    )
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.top, AppTheme.Spacing.small)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            viewModel.rewardMessage = nil
                        }
                    }
                    .zIndex(1)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    navigationPickerHeader
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppTheme.Colors.meadow)
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
        .onChange(of: viewModel.rewardMessage) { _, message in
            dismissRewardBannerAutomatically(message)
        }
    }

    private var navigationPickerHeader: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            selectorMenu(
                title: viewModel.selectedBook?.name ?? "Book",
                maxWidth: 158,
                isDisabled: viewModel.books.isEmpty
            ) {
                ForEach(viewModel.books) { book in
                    Button(book.name) {
                        viewModel.selectBook(abbrev: book.abbrev)
                    }
                }
            }

            selectorMenu(
                title: "\(viewModel.selectedChapterNumber)",
                maxWidth: 58,
                isDisabled: viewModel.chapters.isEmpty
            ) {
                ForEach(viewModel.chapters) { chapter in
                    Button("\(chapter.number)") {
                        viewModel.selectChapter(number: chapter.number)
                    }
                }
            }
        }
        .frame(width: 236, alignment: .leading)
    }

    private func selectorMenu<Content: View>(
        title: String,
        maxWidth: CGFloat,
        isDisabled: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu(content: content) {
            HStack(spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.rounded(.subheadline, weight: .heavy))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: maxWidth, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(AppTheme.Colors.ink)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.xSmall)
            .background(AppTheme.Colors.mint.opacity(0.9), in: Capsule())
            .overlay {
                Capsule().stroke(AppTheme.Colors.leaf.opacity(0.32), lineWidth: 1)
            }
        }
        .disabled(isDisabled)
    }

    private var readerHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentReference)
                        .font(AppTheme.Typography.rounded(.title2, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(viewModel.selectedLanguage.version.displayName)
                        .font(AppTheme.Typography.rounded(.caption, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.softText)
                }

                Spacer()

                if viewModel.isCurrentChapterRead {
                    Label("Done", systemImage: "checkmark.seal.fill")
                        .font(AppTheme.Typography.rounded(.caption, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.meadow)
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.xSmall)
                        .background(AppTheme.Colors.mint, in: Capsule())
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.medium)
        .padding(.bottom, AppTheme.Spacing.small)
    }

    private var verseList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    ForEach(viewModel.verses) { verse in
                        VerseRow(verse: verse, fontSize: viewModel.fontSize)
                            .id(verse.id)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.vertical, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xLarge)
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
        VStack(spacing: AppTheme.Spacing.small) {
            PrimaryGameButton(
                title: viewModel.isCurrentChapterRead ? "Mark Unread" : "Complete Chapter",
                systemImage: viewModel.isCurrentChapterRead ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill"
            ) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    viewModel.toggleCurrentChapterRead()
                }
            }
            .disabled(viewModel.selectedBookAbbrev == nil || viewModel.verses.isEmpty)
            .opacity(viewModel.selectedBookAbbrev == nil || viewModel.verses.isEmpty ? 0.58 : 1)

            HStack(spacing: AppTheme.Spacing.medium) {
                Button {
                    viewModel.moveToPreviousChapter()
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 38)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .disabled(!viewModel.canMoveToPreviousChapter)
                .accessibilityLabel("Previous chapter")

                Text(viewModel.currentReference)
                    .font(AppTheme.Typography.rounded(.footnote, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity)

                Button {
                    viewModel.moveToNextChapter()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 38)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .disabled(!viewModel.canMoveToNextChapter)
                .accessibilityLabel("Next chapter")
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.elevatedCard.opacity(0.96))
    }

    private func scrollToFirstVerse(using proxy: ScrollViewProxy) {
        guard let firstVerse = viewModel.verses.first else {
            return
        }

        withAnimation(.snappy) {
            proxy.scrollTo(firstVerse.id, anchor: .top)
        }
    }

    private func dismissRewardBannerAutomatically(_ message: String?) {
        guard let message else {
            return
        }

        Task {
            try? await Task.sleep(for: .seconds(3))
            guard viewModel.rewardMessage == message else {
                return
            }

            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                viewModel.rewardMessage = nil
            }
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
                            .foregroundStyle(AppTheme.Colors.softText)

                        Slider(value: $viewModel.fontSize, in: 14...28, step: 1)
                            .tint(AppTheme.Colors.meadow)

                        Image(systemName: "textformat.size.larger")
                            .foregroundStyle(AppTheme.Colors.softText)
                    }

                    Text("Preview text")
                        .font(AppTheme.Typography.reader(size: viewModel.fontSize))
                        .foregroundStyle(AppTheme.Colors.softText)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
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
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.medium) {
            Text("\(verse.number)")
                .font(AppTheme.Typography.rounded(.caption, weight: .heavy))
                .foregroundStyle(AppTheme.Colors.meadow)
                .monospacedDigit()
                .frame(width: 30, alignment: .trailing)
                .accessibilityHidden(true)

            Text(verse.text)
                .font(AppTheme.Typography.reader(size: fontSize))
                .lineSpacing(7)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(AppTheme.Colors.mint.opacity(0.72), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    BibleReaderView(viewModel: BibleReaderViewModel())
}
