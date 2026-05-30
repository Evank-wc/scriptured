import SwiftUI

struct BibleView: View {
    @State private var viewModel: BibleViewModel

    init(viewModel: BibleViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Language", selection: languageSelection) {
                        ForEach(viewModel.availableLanguages) { language in
                            Text(language.version.displayName)
                                .tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Books") {
                    if let errorMessage = viewModel.errorMessage {
                        ContentUnavailableView(
                            "Bible Unavailable",
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                    } else if viewModel.books.isEmpty {
                        ContentUnavailableView(
                            "No Books Loaded",
                            systemImage: "book.closed",
                            description: Text("No local Bible books are available")
                        )
                    } else {
                        ForEach(viewModel.books) { book in
                            Text(book.name)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.title)
        }
        .task {
            viewModel.loadBooks()
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

#Preview {
    BibleView(viewModel: BibleViewModel())
}
