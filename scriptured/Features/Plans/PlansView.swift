import SwiftData
import SwiftUI

struct PlansView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PlansViewModel

    init(viewModel: PlansViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage = viewModel.errorMessage, viewModel.plans.isEmpty {
                    EmptyStateView(
                        title: "Plans unavailable",
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle"
                    )
                } else if viewModel.plans.isEmpty {
                    EmptyStateView(
                        title: "No plans found",
                        message: viewModel.hasDecodingErrors ? viewModel.decodingErrors.joined(separator: "\n") : "Add reading plan JSON files to Resources/ReadingPlans.",
                        systemImage: "calendar.badge.exclamationmark"
                    )
                } else {
                    planList
                }
            }
            .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            viewModel.configure(
                readingPlanService: ReadingPlanService(modelContext: modelContext)
            )
            viewModel.refreshSelectionState()
        }
    }

    private var planList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                header

                if viewModel.hasDecodingErrors {
                    decodingErrorCard
                }

                if let errorMessage = viewModel.errorMessage {
                    selectionErrorCard(errorMessage)
                }

                if let selectedPlan = viewModel.selectedPlan {
                    planSection(title: "Selected Plan") {
                        VStack(spacing: AppTheme.Spacing.medium) {
                            NavigationLink {
                                PlanDetailView(plan: selectedPlan, viewModel: viewModel)
                            } label: {
                                PlanListCard(
                                    plan: selectedPlan,
                                    status: selectedPlanStatus,
                                    isSelected: true
                                )
                            }
                            .buttonStyle(.plain)

                            SecondaryGameButton(
                                title: "Unselect Plan",
                                systemImage: "xmark.circle.fill"
                            ) {
                                viewModel.unselectPlan()
                            }
                        }
                    }
                }

                planSection(title: viewModel.selectedPlan == nil ? "Choose a Plan" : "Other Plans") {
                    ForEach(viewModel.otherPlans) { plan in
                        NavigationLink {
                            PlanDetailView(plan: plan, viewModel: viewModel)
                        } label: {
                            PlanListCard(
                                plan: plan,
                                status: statusText(for: plan),
                                isSelected: false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.top, AppTheme.Spacing.small)
            .padding(.bottom, AppTheme.Spacing.large)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("Reading Plans")
                    .font(AppTheme.Typography.rounded(.largeTitle, weight: .black))
                    .foregroundStyle(AppTheme.Colors.ink)

                Text("Pick a rhythm for daily Scripture reading")
                    .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var selectedPlanStatus: String {
        if let currentDay = viewModel.getCurrentDayForActivePlan() {
            return "Selected • Day \(currentDay)"
        }

        return "Selected"
    }

    private func statusText(for plan: ReadingPlanFile) -> String {
        viewModel.isPlanStarted(planId: plan.id) ? "Progress saved" : "Not started"
    }

    private func planSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(title)
                .font(AppTheme.Typography.rounded(.title3, weight: .black))
                .foregroundStyle(AppTheme.Colors.ink)

            content()
        }
    }

    private func selectionErrorCard(_ message: String) -> some View {
        GameCard {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(AppTheme.Typography.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(AppTheme.Colors.coral)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var decodingErrorCard: some View {
        GameCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Label("Some plans could not be loaded", systemImage: "exclamationmark.triangle.fill")
                    .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                    .foregroundStyle(AppTheme.Colors.coral)

                Text(viewModel.decodingErrors.joined(separator: "\n"))
                    .font(AppTheme.Typography.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct PlanListCard: View {
    let plan: ReadingPlanFile
    let status: String
    let isSelected: Bool

    var body: some View {
        GameCard(gradient: isSelected ? AppTheme.Gradients.creamGlow : nil) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                    Image(systemName: isSelected ? "checkmark.seal.fill" : "calendar")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(isSelected ? AppTheme.Colors.meadow : AppTheme.Colors.sky)
                        .frame(width: 34)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                        Text(plan.name)
                            .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                            .foregroundStyle(AppTheme.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(plan.info)
                            .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.softText)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: AppTheme.Spacing.small) {
                    Label("\(plan.getDurationDays()) days", systemImage: "calendar")
                    Label(status, systemImage: isSelected ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                }
                .font(AppTheme.Typography.rounded(.caption, weight: .heavy))
                .foregroundStyle(isSelected ? AppTheme.Colors.meadow : AppTheme.Colors.softText)
            }
        }
    }
}

private struct PlanDetailView: View {
    let plan: ReadingPlanFile
    @Bindable var viewModel: PlansViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                headerCard
                selectButton
                readingsCard
            }
            .padding(AppTheme.Spacing.large)
        }
        .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var headerCard: some View {
        GameCard(gradient: viewModel.isSelectedPlan(planId: plan.id) ? AppTheme.Gradients.creamGlow : nil) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack(alignment: .center) {
                    Label("\(plan.getDurationDays()) days", systemImage: "calendar")
                        .font(AppTheme.Typography.rounded(.subheadline, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.meadow)
                        .monospacedDigit()

                    Spacer()

                    if viewModel.isSelectedPlan(planId: plan.id) {
                        Label("Selected", systemImage: "checkmark.seal.fill")
                            .font(AppTheme.Typography.rounded(.caption, weight: .black))
                            .foregroundStyle(AppTheme.Colors.meadow)
                    } else if viewModel.isPlanStarted(planId: plan.id) {
                        Label("Progress saved", systemImage: "checkmark.circle.fill")
                            .font(AppTheme.Typography.rounded(.caption, weight: .black))
                            .foregroundStyle(AppTheme.Colors.sky)
                    }
                }

                Text(plan.name)
                    .font(AppTheme.Typography.rounded(.title2, weight: .black))
                    .foregroundStyle(AppTheme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(plan.info)
                    .font(AppTheme.Typography.rounded(.body, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var selectButton: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            PrimaryGameButton(
                title: viewModel.isSelectedPlan(planId: plan.id) ? "Selected Plan" : viewModel.isPlanStarted(planId: plan.id) ? "Select Saved Plan" : "Select Plan",
                systemImage: viewModel.isSelectedPlan(planId: plan.id) ? "checkmark.seal.fill" : "play.fill"
            ) {
                viewModel.startPlan(plan)
            }

            if viewModel.isSelectedPlan(planId: plan.id) {
                SecondaryGameButton(title: "Unselect Plan", systemImage: "xmark.circle.fill") {
                    viewModel.unselectPlan()
                }
            }
        }
    }

    private var readingsCard: some View {
        GameCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                Text("Daily Readings")
                    .font(AppTheme.Typography.rounded(.title3, weight: .heavy))
                    .foregroundStyle(AppTheme.Colors.ink)

                LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    ForEach(1...max(plan.getDurationDays(), 1), id: \.self) { dayNumber in
                        PlanDayRow(
                            dayNumber: dayNumber,
                            readings: plan.getReadingForDay(dayNumber: dayNumber)
                        )
                    }
                }
            }
        }
    }
}

private struct PlanDayRow: View {
    let dayNumber: Int
    let readings: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text("Day \(dayNumber)")
                .font(AppTheme.Typography.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(AppTheme.Colors.ink)

            ForEach(readings, id: \.self) { reading in
                Text(reading)
                    .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }
}

#Preview {
    PlansView(viewModel: PlansViewModel())
}
