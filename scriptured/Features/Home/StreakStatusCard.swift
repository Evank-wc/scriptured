import SwiftUI

struct StreakStatusCard: View {
    let status: StreakStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("\(status.currentStreak)", systemImage: "flame.fill")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.orange)

                Text(status.currentStreak == 1 ? "day streak" : "day streak")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Label("\(status.streakFreezesAvailable)", systemImage: "snowflake")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(status.statusText)
                    .font(.headline)

                if !status.hasCompletedToday {
                    Label("Complete one reading today to protect your streak.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(status.isAtRisk ? .orange : .secondary)
                }

                Text("Longest streak: \(status.longestStreak)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    StreakStatusCard(
        status: StreakStatus(
            currentStreak: 7,
            longestStreak: 12,
            hasCompletedToday: false,
            isAtRisk: true,
            shouldConsumeFreeze: false,
            streakFreezesAvailable: 1
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
