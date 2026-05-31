import SwiftUI

struct StreakHeroCard: View {
    let streak: Int
    let longestStreak: Int
    let freezesAvailable: Int
    let hasCompletedToday: Bool
    let isAtRisk: Bool
    let title: String
    let message: String

    var body: some View {
        GameCard(gradient: gradient) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                streakCount

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text(title)
                        .font(AppTheme.Typography.rounded(.title3, weight: .heavy))
                        .foregroundStyle(primaryTextColor)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

                    Text(message)
                        .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: AppTheme.Spacing.medium) {
                    LevelStatPill(title: "Best", value: "\(longestStreak)", systemImage: "trophy.fill", tint: AppTheme.Colors.sunrise)
                    LevelStatPill(title: "Freezes", value: "\(freezesAvailable)", systemImage: "snowflake", tint: AppTheme.Colors.sky)
                }
            }
        }
    }

    private var streakCount: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.small) {
                Image(systemName: hasCompletedToday ? "checkmark.seal.fill" : "flame.fill")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(hasCompletedToday ? AppTheme.Colors.mint : AppTheme.Colors.sunrise)
                    .symbolEffect(.pulse, options: .repeating, value: isAtRisk)

                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xSmall) {
                    Text("\(streak)")
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(streak == 1 ? "day" : "days")
                        .font(AppTheme.Typography.rounded(.title3, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(primaryTextColor)
            }
            .layoutPriority(1)

            Text("streak")
                .font(AppTheme.Typography.rounded(.headline, weight: .bold))
                .foregroundStyle(secondaryTextColor)
        }
    }

    private var gradient: LinearGradient {
        if hasCompletedToday {
            AppTheme.Gradients.meadowGlow
        } else if isAtRisk {
            AppTheme.Gradients.sunriseGlow
        } else {
            AppTheme.Gradients.creamGlow
        }
    }

    private var primaryTextColor: Color {
        hasCompletedToday || isAtRisk ? .white : AppTheme.Colors.ink
    }

    private var secondaryTextColor: Color {
        hasCompletedToday || isAtRisk ? .white.opacity(0.86) : AppTheme.Colors.softText
    }
}

struct XPProgressBar: View {
    let currentXP: Int
    let requiredXP: Int
    var unitLabel = "XP"
    var accessibilityLabel = "Experience progress"

    private var progress: Double {
        guard requiredXP > 0 else { return 0 }
        return min(max(Double(currentXP) / Double(requiredXP), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.sand.opacity(0.24))

                    Capsule()
                        .fill(AppTheme.Gradients.xpGlow)
                        .frame(width: max(geometry.size.width * progress, progress > 0 ? 8 : 0))
                        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: progress)
                }
            }
            .frame(height: 14)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue("\(currentXP) of \(requiredXP) \(unitLabel)")

            Text("\(currentXP) / \(requiredXP) \(unitLabel)")
                .font(AppTheme.Typography.rounded(.caption, weight: .bold))
                .foregroundStyle(AppTheme.Colors.softText)
                .monospacedDigit()
        }
    }
}

struct CoinBalancePill: View {
    let coins: Int
    let label: String

    var body: some View {
        Label {
            Text("\(coins) \(label)")
                .monospacedDigit()
        } icon: {
            Image(systemName: "circle.hexagongrid.fill")
                .foregroundStyle(AppTheme.Colors.sunrise)
        }
        .font(AppTheme.Typography.rounded(.subheadline, weight: .heavy))
        .foregroundStyle(AppTheme.Colors.ink)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.cream, in: Capsule())
        .overlay {
            Capsule().stroke(AppTheme.Colors.sunrise.opacity(0.35), lineWidth: 1)
        }
    }
}

struct LevelBadge: View {
    let level: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: "star.circle.fill")
                .foregroundStyle(AppTheme.Colors.sunrise)
            Text("Level \(level)")
                .monospacedDigit()
        }
        .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
        .foregroundStyle(.white)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Gradients.xpGlow, in: Capsule())
    }
}

struct RewardBanner: View {
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)

            Text(message)
                .font(AppTheme.Typography.rounded(.subheadline, weight: .bold))
                .foregroundStyle(AppTheme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.medium)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        }
        .modifier(AppTheme.Shadows.card(radius: 12, y: 4))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.leaf)

            Text(title)
                .font(AppTheme.Typography.rounded(.title3, weight: .heavy))
                .multilineTextAlignment(.center)

            Text(message)
                .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.softText)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LevelStatPill: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AppTheme.Typography.rounded(.caption, weight: .heavy))
                    .monospacedDigit()
                Text(title)
                    .font(AppTheme.Typography.rounded(.caption2, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.softText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.elevatedCard.opacity(0.88), in: Capsule())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            StreakHeroCard(
                streak: 7,
                longestStreak: 12,
                freezesAvailable: 1,
                hasCompletedToday: false,
                isAtRisk: true,
                title: "Your streak is at risk",
                message: "One chapter keeps the fire alive."
            )

            GameCard {
                LevelBadge(level: 3)
                XPProgressBar(currentXP: 80, requiredXP: 150)
                CoinBalancePill(coins: 42, label: "coins")
            }

            RewardBanner(message: "+10 XP and +1 coin earned", systemImage: "sparkles", tint: AppTheme.Colors.sunrise)
            EmptyStateView(title: "No verses loaded", message: "Choose a book and chapter to begin reading.", systemImage: "book.closed")
        }
        .padding()
    }
    .background(AppTheme.Colors.pageBackground)
}
