import SwiftUI

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    var body: some View {
        MainTabView()
            .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    ContentView()
}
