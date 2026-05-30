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
                }
            }
            .navigationTitle(viewModel.title)
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
