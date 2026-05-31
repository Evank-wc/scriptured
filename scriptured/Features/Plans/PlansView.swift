import SwiftUI

struct PlansView: View {
    let viewModel: PlansViewModel

    var body: some View {
        NavigationStack {
            EmptyStateView(
                title: viewModel.title,
                message: "Reading plans placeholder",
                systemImage: "calendar"
            )
            .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    PlansView(viewModel: PlansViewModel())
}
