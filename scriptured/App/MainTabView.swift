import SwiftUI

struct MainTabView: View {
    private let environment = AppEnvironment.live

    @State private var selectedTab: AppTab = .home
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
        TabView(selection: $selectedTab) {
            HomeView(
                viewModel: homeViewModel,
                onContinueReading: { selectedTab = .bible },
                onOpenReadingPlan: { selectedTab = .plans }
            )
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(AppTab.home)

            BibleReaderView(viewModel: bibleReaderViewModel)
                .tabItem {
                    Label("Bible", systemImage: "book")
                }
                .tag(AppTab.bible)

            PlansView(viewModel: plansViewModel)
                .tabItem {
                    Label("Plans", systemImage: "calendar")
                }
                .tag(AppTab.plans)

            ShopView(viewModel: shopViewModel)
                .tabItem {
                    Label("Shop", systemImage: "bag")
                }
                .tag(AppTab.shop)

            ProfileView(viewModel: profileViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(AppTab.profile)
        }
        .tint(AppTheme.Colors.meadow)
    }
}

private enum AppTab: Hashable {
    case home
    case bible
    case plans
    case shop
    case profile
}

#Preview {
    MainTabView()
}
