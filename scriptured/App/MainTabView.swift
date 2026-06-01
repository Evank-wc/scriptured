import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    private let environment = AppEnvironment.live

    @AppStorage(ReadingActivitySignal.revisionKey) private var readingActivityRevision = 0
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
                onOpenReadingPlan: { selectedTab = .plans },
                onOpenPlanReading: { reading in
                    bibleReaderViewModel.openReading(reading)
                    selectedTab = .bible
                }
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
        .onAppear {
            configureViewModels()
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == .home {
                homeViewModel.loadStats()
            }
        }
        .onChange(of: readingActivityRevision) { _, _ in
            homeViewModel.loadStats()
            bibleReaderViewModel.refreshProgressFromStorage()
            plansViewModel.refreshSelectionState()
            shopViewModel.loadShop()
        }
    }

    private func configureViewModels() {
        let progressionService = ProgressionService(modelContext: modelContext)
        let readingProgressService = ReadingProgressService(modelContext: modelContext)
        let readingPlanService = ReadingPlanService(modelContext: modelContext)
        let shopService = ShopService(modelContext: modelContext)

        homeViewModel.configure(
            progressionService: progressionService,
            streakService: StreakService(modelContext: modelContext),
            readingProgressService: readingProgressService,
            bibleService: environment.bibleService,
            readingPlanService: readingPlanService,
            shopService: shopService
        )
        bibleReaderViewModel.configure(
            progressService: readingProgressService,
            progressionService: progressionService,
            readingPlanService: readingPlanService
        )
        plansViewModel.configure(readingPlanService: readingPlanService)
        shopViewModel.configure(shopService: shopService)
        profileViewModel.configure(progressionService: progressionService)
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
