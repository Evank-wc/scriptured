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
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    if let errorMessage = viewModel.errorMessage {
                        EmptyStateView(
                            title: "Dashboard unavailable",
                            message: errorMessage,
                            systemImage: "exclamationmark.triangle"
                        )
                    } else {
                        header
                        streakHero
                        actionButtons
                        progressCard
                        todayGoalCard
                        statsRow
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.top, AppTheme.Spacing.small)
                .padding(.bottom, AppTheme.Spacing.large)
            }
            .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            viewModel.configure(
                progressionService: ProgressionService(modelContext: modelContext),
                streakService: StreakService(modelContext: modelContext),
                readingProgressService: ReadingProgressService(modelContext: modelContext),
                bibleService: BibleService()
            )
            viewModel.loadStats()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("Dashboard")
                    .font(AppTheme.Typography.rounded(.largeTitle, weight: .black))
                    .foregroundStyle(AppTheme.Colors.ink)

                Text(viewModel.streakStatus.hasCompletedToday ? "You are done for today" : "One chapter keeps the fire alive")
                    .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppTheme.Spacing.small)

            CoinBalancePill(coins: viewModel.coins, label: "coins")
        }
    }

    private var streakHero: some View {
        StreakHeroCard(
            streak: viewModel.streakStatus.currentStreak,
            longestStreak: viewModel.streakStatus.longestStreak,
            freezesAvailable: viewModel.streakStatus.streakFreezesAvailable,
            hasCompletedToday: viewModel.streakStatus.hasCompletedToday,
            isAtRisk: viewModel.streakStatus.isAtRisk,
            title: viewModel.statusMessage,
            message: viewModel.urgencyMessage
        )
    }

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            PrimaryGameButton(
                title: viewModel.streakStatus.hasCompletedToday ? "Read another chapter" : "Protect your streak",
                systemImage: viewModel.streakStatus.hasCompletedToday ? "book.fill" : "flame.fill",
                action: onContinueReading
            )

            SecondaryGameButton(title: "Current Plan", systemImage: "calendar", action: onOpenReadingPlan)
        }
    }

    private var progressCard: some View {
        GameCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack(alignment: .center) {
                    LevelBadge(level: viewModel.currentLevel)

                    Spacer()

                    Text("\(viewModel.totalXP) XP")
                        .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.sky)
                        .monospacedDigit()
                }

                XPProgressBar(
                    currentXP: viewModel.xpProgress.currentXP,
                    requiredXP: viewModel.xpProgress.requiredXP
                )

                Text("Keep reading to reach Level \(viewModel.currentLevel + 1).")
                    .font(AppTheme.Typography.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.softText)
            }
        }
    }

    private var todayGoalCard: some View {
        GameCard(gradient: AppTheme.Gradients.creamGlow) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: viewModel.streakStatus.hasCompletedToday ? "checkmark.seal.fill" : "target")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(viewModel.streakStatus.hasCompletedToday ? AppTheme.Colors.meadow : AppTheme.Colors.coral)

                    Text(viewModel.todayGoalTitle)
                        .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.ink)

                    Spacer()

                    Text(viewModel.streakStatus.hasCompletedToday ? "1/1" : "0/1")
                        .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                        .foregroundStyle(viewModel.streakStatus.hasCompletedToday ? AppTheme.Colors.meadow : AppTheme.Colors.coral)
                        .monospacedDigit()
                }

                XPProgressBar(
                    currentXP: Int(viewModel.todayGoalProgress),
                    requiredXP: 1,
                    unitLabel: "Chapter",
                    accessibilityLabel: "Daily goal progress"
                )

                Text(viewModel.todayGoalMessage)
                    .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            SmallStatCard(
                title: "Chapters Read",
                value: viewModel.chapterProgressValue,
                systemImage: "book.pages.fill",
                tint: AppTheme.Colors.meadow
            )

            SmallStatCard(
                title: "Daily Goals",
                value: "\(viewModel.dailyGoalsCompleted)",
                systemImage: "checkmark.seal.fill",
                tint: AppTheme.Colors.sunrise
            )
        }
    }
}

private struct SmallStatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tint)

                Text(value)
                    .font(AppTheme.Typography.rounded(.title3, weight: .heavy))
                    .foregroundStyle(AppTheme.Colors.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(title)
                    .font(AppTheme.Typography.rounded(.caption, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
