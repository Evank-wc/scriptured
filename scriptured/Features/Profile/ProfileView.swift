import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext

    let viewModel: ProfileViewModel
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(AppTheme.Colors.meadow)
                }
                .listRowBackground(AppTheme.Colors.elevatedCard)

                Section("Testing") {
                    Button {
                        viewModel.grantTestingCoins()
                    } label: {
                        Label("Give 1000 Coins", systemImage: "circle.hexagongrid.fill")
                    }
                    .font(AppTheme.Typography.rounded(.headline, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.meadow)

                    if let testCoinMessage = viewModel.testCoinMessage {
                        Text(testCoinMessage)
                            .font(AppTheme.Typography.rounded(.footnote, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.softText)
                    }
                }
                .listRowBackground(AppTheme.Colors.elevatedCard)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            viewModel.configure(progressionService: ProgressionService(modelContext: modelContext))
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
