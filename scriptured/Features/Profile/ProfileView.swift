import SwiftUI

struct ProfileView: View {
    let viewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                viewModel.title,
                systemImage: "person",
                description: Text("Profile placeholder")
            )
            .navigationTitle(viewModel.title)
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
