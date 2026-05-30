import SwiftUI

struct PlansView: View {
    let viewModel: PlansViewModel

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                viewModel.title,
                systemImage: "calendar",
                description: Text("Reading plans placeholder")
            )
            .navigationTitle(viewModel.title)
        }
    }
}

#Preview {
    PlansView(viewModel: PlansViewModel())
}
