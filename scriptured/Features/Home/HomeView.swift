import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let errorMessage = viewModel.errorMessage {
                        ContentUnavailableView(
                            "Stats Unavailable",
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                    } else {
                        StreakStatusCard(status: viewModel.streakStatus)
                        levelCard
                        currencyRow
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.title)
        }
        .onAppear {
            viewModel.configure(
                progressionService: ProgressionService(modelContext: modelContext),
                streakService: StreakService(modelContext: modelContext)
            )
            viewModel.loadStats()
        }
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Level \(viewModel.currentLevel)")
                    .font(.title2.weight(.semibold))

                Spacer()

                Text("\(viewModel.totalXP) XP")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(
                value: Double(viewModel.xpProgress.currentXP),
                total: Double(viewModel.xpProgress.requiredXP)
            )
            .tint(.blue)

            Text("\(viewModel.xpProgress.currentXP) / \(viewModel.xpProgress.requiredXP) XP to Level \(viewModel.currentLevel + 1)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var currencyRow: some View {
        HStack(spacing: 12) {
            StatTile(
                title: "Coins",
                value: "\(viewModel.coins)",
                systemImage: "circle.hexagongrid.fill"
            )

            StatTile(
                title: "Lifetime Coins",
                value: "\(viewModel.lifetimeCoins)",
                systemImage: "sparkles"
            )
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.blue)

            Text(value)
                .font(.title3.weight(.semibold))

            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
