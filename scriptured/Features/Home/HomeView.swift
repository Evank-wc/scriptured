import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel

    private let onContinueReading: () -> Void
    private let onOpenReadingPlan: () -> Void

    init(
        viewModel: HomeViewModel,
        onContinueReading: @escaping () -> Void = {},
        onOpenReadingPlan: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onContinueReading = onContinueReading
        self.onOpenReadingPlan = onOpenReadingPlan
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage = viewModel.errorMessage {
                        ContentUnavailableView(
                            "Dashboard Unavailable",
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                    } else {
                        streakHero
                        actionButtons
                        todayGoalCard
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

    private var streakHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.orange)

                        Text("\(viewModel.streakStatus.currentStreak)")
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                    }

                    Text(viewModel.streakStatus.currentStreak == 1 ? "day streak" : "day streak")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Label("\(viewModel.streakStatus.streakFreezesAvailable)", systemImage: "snowflake")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.blue)

                    Text("freezes")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.statusMessage)
                    .font(.title3.weight(.bold))

                Text(viewModel.urgencyMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(viewModel.streakStatus.hasCompletedToday ? Color.secondary : Color.orange)
            }

            HStack(spacing: 10) {
                DashboardPill(
                    title: "Longest",
                    value: "\(viewModel.streakStatus.longestStreak)",
                    systemImage: "trophy.fill",
                    tint: .yellow
                )

                DashboardPill(
                    title: "Today",
                    value: viewModel.streakStatus.hasCompletedToday ? "Safe" : "Open",
                    systemImage: viewModel.streakStatus.hasCompletedToday ? "shield.fill" : "bolt.fill",
                    tint: viewModel.streakStatus.hasCompletedToday ? .green : .orange
                )
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onContinueReading) {
                Label("Continue Reading", systemImage: "book.fill")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: onOpenReadingPlan) {
                Label("Current Plan", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
    }

    private var todayGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(viewModel.todayGoalTitle, systemImage: "target")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text(viewModel.streakStatus.hasCompletedToday ? "1/1" : "0/1")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(viewModel.streakStatus.hasCompletedToday ? .green : .orange)
            }

            ProgressView(value: viewModel.todayGoalProgress, total: 1)
                .tint(viewModel.streakStatus.hasCompletedToday ? .green : .orange)

            Text(viewModel.todayGoalMessage)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
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
                .font(.footnote.weight(.medium))
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
                systemImage: "circle.hexagongrid.fill",
                tint: .yellow
            )

            StatTile(
                title: "Lifetime Coins",
                value: "\(viewModel.lifetimeCoins)",
                systemImage: "sparkles",
                tint: .purple
            )
        }
    }
}

private struct DashboardPill: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)

            Text(value)
                .font(.title3.weight(.semibold))

            Text(title)
                .font(.footnote.weight(.medium))
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
