import SwiftUI

struct PrimaryGameButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTheme.Typography.rounded(.headline, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.medium)
        }
        .buttonStyle(GameButtonStyle(kind: .primary))
    }
}

struct SecondaryGameButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTheme.Typography.rounded(.subheadline, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.small)
        }
        .buttonStyle(GameButtonStyle(kind: .secondary))
    }
}

private struct GameButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundStyle)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
            .modifier(ButtonShadowStyle(kind: kind))
    }

    private var foregroundStyle: Color {
        switch kind {
        case .primary:
            .white
        case .secondary:
            AppTheme.Colors.meadow
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
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                        .stroke(AppTheme.Colors.leaf.opacity(0.35), lineWidth: 1)
                }
        }
    }
}

private struct ButtonShadowStyle: ViewModifier {
    let kind: GameButtonStyle.Kind

    func body(content: Content) -> some View {
        switch kind {
        case .primary:
            content.modifier(AppTheme.Shadows.glow(radius: 10, y: 4))
        case .secondary:
            content.modifier(AppTheme.Shadows.card(radius: 8, y: 3))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryGameButton(title: "Protect your streak", systemImage: "flame.fill") {}
        SecondaryGameButton(title: "Current Plan", systemImage: "calendar") {}
    }
    .padding()
}
