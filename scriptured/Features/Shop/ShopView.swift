import SwiftUI

struct ShopView: View {
    let viewModel: ShopViewModel

    var body: some View {
        NavigationStack {
            EmptyStateView(
                title: viewModel.title,
                message: "Shop placeholder",
                systemImage: "bag"
            )
            .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    ShopView(viewModel: ShopViewModel())
}
