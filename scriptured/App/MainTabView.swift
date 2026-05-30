import SwiftUI

struct MainTabView: View {
    private let environment = AppEnvironment.live

    var body: some View {
        TabView {
            HomeView(viewModel: HomeViewModel())
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            BibleReaderView(viewModel: BibleReaderViewModel(bibleService: environment.bibleService))
                .tabItem {
                    Label("Bible", systemImage: "book")
                }

            PlansView(viewModel: PlansViewModel())
                .tabItem {
                    Label("Plans", systemImage: "calendar")
                }

            ShopView(viewModel: ShopViewModel())
                .tabItem {
                    Label("Shop", systemImage: "bag")
                }

            ProfileView(viewModel: ProfileViewModel())
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView()
}
