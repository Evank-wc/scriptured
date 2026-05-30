import SwiftUI

struct ShopView: View {
    let viewModel: ShopViewModel

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                viewModel.title,
                systemImage: "bag",
                description: Text("Shop placeholder")
            )
            .navigationTitle(viewModel.title)
        }
    }
}

#Preview {
    ShopView(viewModel: ShopViewModel())
}
