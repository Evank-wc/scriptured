import SwiftUI

struct ProfileView: View {
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
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
