import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                viewModel.title,
                systemImage: "house",
                description: Text("Home dashboard placeholder")
            )
            .navigationTitle(viewModel.title)
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
