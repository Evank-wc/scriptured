import SwiftUI

struct GameCard<Content: View>: View {
    private let gradient: LinearGradient?
    private let content: Content

    init(
        gradient: LinearGradient? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppTheme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(AppTheme.Colors.elevatedCard)

                if let gradient {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .fill(gradient)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(AppTheme.Colors.sand.opacity(0.28), lineWidth: 1)
            }
            .modifier(AppTheme.Shadows.card())
    }
}

#Preview {
    VStack {
        GameCard {
            Text("Game Card")
                .font(AppTheme.Typography.rounded(.headline, weight: .bold))
        }

        GameCard(gradient: AppTheme.Gradients.creamGlow) {
            Text("Gradient Card")
                .font(AppTheme.Typography.rounded(.headline, weight: .bold))
        }
    }
    .padding()
    .background(AppTheme.Colors.pageBackground)
}
