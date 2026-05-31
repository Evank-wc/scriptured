import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(ReadingActivitySignal.revisionKey) private var readingActivityRevision = 0
    @State private var viewModel: HomeViewModel

    private let onContinueReading: () -> Void
    private let onOpenReadingPlan: () -> Void
    private let onOpenPlanReading: (PlanReadingReference) -> Void

    init(
        viewModel: HomeViewModel,
        onContinueReading: @escaping () -> Void = {},
        onOpenReadingPlan: @escaping () -> Void = {},
        onOpenPlanReading: @escaping (PlanReadingReference) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onContinueReading = onContinueReading
        self.onOpenReadingPlan = onOpenReadingPlan
        self.onOpenPlanReading = onOpenPlanReading
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
                        currentPlanCard
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
                bibleService: BibleService(),
                readingPlanService: ReadingPlanService(modelContext: modelContext)
            )
            viewModel.loadStats()
        }
        .onChange(of: readingActivityRevision) { _, _ in
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
        PrimaryGameButton(
            title: viewModel.streakStatus.hasCompletedToday ? "Read another chapter" : "Protect your streak",
            systemImage: viewModel.streakStatus.hasCompletedToday ? "book.fill" : "flame.fill",
            action: onContinueReading
        )
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
                    Image(systemName: viewModel.todayPlanAssignment?.isComplete == true ? "checkmark.seal.fill" : "target")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(viewModel.todayPlanAssignment?.isComplete == true ? AppTheme.Colors.meadow : AppTheme.Colors.coral)

                    Text(viewModel.todayGoalTitle)
                        .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.ink)

                    Spacer()

                    Text(viewModel.todayPlanProgressText)
                        .font(AppTheme.Typography.rounded(.caption, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.meadow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                XPProgressBar(
                    currentXP: viewModel.todayPlanAssignment?.completedReadingKeys.count ?? Int(viewModel.todayGoalProgress),
                    requiredXP: max(viewModel.todayPlanAssignment?.readings.count ?? 1, 1),
                    unitLabel: "readings",
                    accessibilityLabel: "Daily plan progress"
                )

                Text(viewModel.todayGoalMessage)
                    .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var currentPlanCard: some View {
        GameCard(gradient: viewModel.todayPlanAssignment == nil ? AppTheme.Gradients.creamGlow : nil) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                if let assignment = viewModel.todayPlanAssignment {
                    selectedPlanContent(assignment)
                } else {
                    noPlanContent
                }
            }
        }
    }

    private func selectedPlanContent(_ assignment: ReadingPlanTodayAssignment) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Current Plan")
                        .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.ink)
                    Text("\(assignment.plan.name) • Day \(assignment.dayNumber)")
                        .font(AppTheme.Typography.rounded(.caption, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.softText)
                }
                Spacer()
                if assignment.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.Colors.meadow)
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ForEach(assignment.readings.prefix(6)) { reading in
                    PlanReadingRow(
                        reading: reading,
                        isComplete: assignment.completedReadingKeys.contains(reading.readingKey)
                    )
                }

                if assignment.readings.count > 6 {
                    Text("+\(assignment.readings.count - 6) more readings")
                        .font(AppTheme.Typography.rounded(.caption, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.softText)
                }
            }

            if let planActionMessage = viewModel.planActionMessage {
                Text(planActionMessage)
                    .font(AppTheme.Typography.rounded(.caption, weight: .heavy))
                    .foregroundStyle(AppTheme.Colors.meadow)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let nextPlanReading = viewModel.nextPlanReading {
                PrimaryGameButton(
                    title: assignment.isComplete ? "Review Assigned Chapter" : "Read Assigned Chapter",
                    systemImage: "book.fill"
                ) {
                    onOpenPlanReading(nextPlanReading)
                }
            }

            SecondaryGameButton(
                title: assignment.isComplete ? "Plan Done Today" : "Mark Today’s Plan Done",
                systemImage: assignment.isComplete ? "checkmark.seal.fill" : "checkmark.circle.fill"
            ) {
                viewModel.completeTodayPlan()
            }
        }
    }

    private var noPlanContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.meadow)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Choose a reading plan")
                        .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.ink)
                    Text("A plan gives you one clear reading target for today.")
                        .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.softText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SecondaryGameButton(title: "Browse Plans", systemImage: "calendar", action: onOpenReadingPlan)
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

private struct PlanReadingRow: View {
    let reading: PlanReadingReference
    let isComplete: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? AppTheme.Colors.meadow : AppTheme.Colors.softText)
            Text(reading.displayText)
                .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.ink)
                .lineLimit(2)
            Spacer(minLength: 0)
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
