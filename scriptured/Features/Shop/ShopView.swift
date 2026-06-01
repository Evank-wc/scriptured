import SwiftUI

struct ShopView: View {
    let viewModel: ShopViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    shopHeader
                    feedbackBanner
                    shopSection(title: "Power-ups", items: viewModel.powerUps)
                    shopSection(title: "Outfits", items: viewModel.outfits)
                    shopSection(title: "Frames", items: viewModel.frames)
                    shopSection(title: "Titles", items: viewModel.titles)
                }
                .padding(AppTheme.Spacing.large)
            }
            .background(AppTheme.Gradients.pageGlow.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .toolbarBackground(AppTheme.Colors.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                viewModel.loadShop()
            }
        }
    }

    private var shopHeader: some View {
        GameCard(gradient: AppTheme.Gradients.creamGlow) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Coin Shop")
                        .font(AppTheme.Typography.rounded(.title2, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.ink)

                    Text("Spend coins earned from reading.")
                        .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.softText)
                }

                Spacer(minLength: AppTheme.Spacing.small)

                CoinBalancePill(coins: viewModel.coins, label: "coins")
            }
        }
    }

    @ViewBuilder
    private var feedbackBanner: some View {
        if let message = viewModel.message {
            RewardBanner(message: message, systemImage: "checkmark.seal.fill", tint: AppTheme.Colors.leaf)
                .onTapGesture { viewModel.clearMessage() }
        } else if let errorMessage = viewModel.errorMessage {
            RewardBanner(message: errorMessage, systemImage: "exclamationmark.triangle.fill", tint: AppTheme.Colors.coral)
                .onTapGesture { viewModel.clearMessage() }
        }
    }

    @ViewBuilder
    private func shopSection(title: String, items: [ShopItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text(title)
                    .font(AppTheme.Typography.rounded(.title3, weight: .heavy))
                    .foregroundStyle(AppTheme.Colors.ink)

                VStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(items) { item in
                        ShopItemRow(
                            item: item,
                            canAfford: viewModel.coins >= item.price,
                            onPurchase: { viewModel.purchase(item) },
                            onEquip: { viewModel.equip(item) }
                        )
                    }
                }
            }
        }
    }
}

private struct ShopItemRow: View {
    let item: ShopItem
    let canAfford: Bool
    let onPurchase: () -> Void
    let onEquip: () -> Void

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                    itemIcon

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.small) {
                            Text(item.name)
                                .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                                .foregroundStyle(AppTheme.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)

                            if item.isEquipped {
                                statusPill("Equipped", systemImage: "checkmark.circle.fill", tint: AppTheme.Colors.leaf)
                            } else if item.isOwned, item.type.isCosmetic {
                                statusPill("Owned", systemImage: "checkmark.seal.fill", tint: AppTheme.Colors.sky)
                            }
                        }

                        Text(item.description)
                            .font(AppTheme.Typography.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.softText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: AppTheme.Spacing.medium) {
                    Label("\(item.price)", systemImage: "circle.hexagongrid.fill")
                        .font(AppTheme.Typography.rounded(.headline, weight: .heavy))
                        .foregroundStyle(AppTheme.Colors.sunrise)
                        .monospacedDigit()

                    Spacer(minLength: AppTheme.Spacing.small)

                    actionButton
                }
            }
        }
    }

    private var itemIcon: some View {
        Image(systemName: item.type.systemImage)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundStyle(iconTint)
            .frame(width: 48, height: 48)
            .background(AppTheme.Colors.mint.opacity(0.88), in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .stroke(iconTint.opacity(0.22), lineWidth: 1)
            }
    }

    @ViewBuilder
    private var actionButton: some View {
        if item.type.isConsumable {
            Button(action: onPurchase) {
                Label("Buy", systemImage: "cart.fill")
            }
            .buttonStyle(ShopActionButtonStyle(kind: canAfford ? .primary : .disabled))
            .disabled(!canAfford)
        } else if item.isEquipped {
            Button(action: {}) {
                Label("Equipped", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(ShopActionButtonStyle(kind: .disabled))
            .disabled(true)
        } else if item.isOwned {
            Button(action: onEquip) {
                Label("Equip", systemImage: "sparkles")
            }
            .buttonStyle(ShopActionButtonStyle(kind: .secondary))
        } else {
            Button(action: onPurchase) {
                Label("Buy", systemImage: "cart.fill")
            }
            .buttonStyle(ShopActionButtonStyle(kind: canAfford ? .primary : .disabled))
            .disabled(!canAfford)
        }
    }

    private func statusPill(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(AppTheme.Typography.rounded(.caption, weight: .heavy))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.xSmall)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private var iconTint: Color {
        switch item.type {
        case .streakFreeze:
            AppTheme.Colors.sky
        case .xpBoost:
            AppTheme.Colors.grape
        case .outfit:
            AppTheme.Colors.leaf
        case .profileFrame:
            AppTheme.Colors.sunrise
        case .title:
            AppTheme.Colors.coral
        }
    }
}

private struct ShopActionButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case disabled
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.rounded(.subheadline, weight: .heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed && kind != .disabled ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary:
            .white
        case .secondary:
            AppTheme.Colors.meadow
        case .disabled:
            AppTheme.Colors.softText
        }
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .primary:
            AppTheme.Gradients.meadowGlow
        case .secondary:
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .fill(AppTheme.Colors.mint.opacity(0.88))
        case .disabled:
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .fill(AppTheme.Colors.sand.opacity(0.22))
        }
    }
}

#Preview {
    ShopView(viewModel: ShopViewModel())
}
