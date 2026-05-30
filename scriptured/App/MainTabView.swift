import SwiftUI

struct MainTabView: View {
    private let environment = AppEnvironment.live

    @State private var homeViewModel = HomeViewModel()
    @State private var bibleReaderViewModel: BibleReaderViewModel
    @State private var plansViewModel = PlansViewModel()
    @State private var shopViewModel = ShopViewModel()
    @State private var profileViewModel = ProfileViewModel()

    init() {
        _bibleReaderViewModel = State(
            initialValue: BibleReaderViewModel(bibleService: environment.bibleService)
        )
    }

    var body: some View {
        TabView {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            BibleReaderView(viewModel: bibleReaderViewModel)
                .tabItem {
                    Label("Bible", systemImage: "book")
                }

            PlansView(viewModel: plansViewModel)
                .tabItem {
                    Label("Plans", systemImage: "calendar")
                }

            ShopView(viewModel: shopViewModel)
                .tabItem {
                    Label("Shop", systemImage: "bag")
                }

            ProfileView(viewModel: profileViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView()
}
