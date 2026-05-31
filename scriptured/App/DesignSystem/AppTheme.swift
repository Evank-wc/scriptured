import SwiftUI
import UIKit

struct AppTheme {
    struct Colors {
        static let meadow = Color.dynamic(light: UIColor(red: 0.18, green: 0.55, blue: 0.32, alpha: 1), dark: UIColor(red: 0.48, green: 0.82, blue: 0.51, alpha: 1))
        static let leaf = Color.dynamic(light: UIColor(red: 0.36, green: 0.72, blue: 0.38, alpha: 1), dark: UIColor(red: 0.36, green: 0.72, blue: 0.38, alpha: 1))
        static let mint = Color.dynamic(light: UIColor(red: 0.82, green: 0.94, blue: 0.79, alpha: 1), dark: UIColor(red: 0.18, green: 0.34, blue: 0.22, alpha: 1))
        static let cream = Color.dynamic(light: UIColor(red: 0.98, green: 0.94, blue: 0.84, alpha: 1), dark: UIColor(red: 0.22, green: 0.20, blue: 0.15, alpha: 1))
        static let sand = Color.dynamic(light: UIColor(red: 0.91, green: 0.82, blue: 0.62, alpha: 1), dark: UIColor(red: 0.50, green: 0.43, blue: 0.27, alpha: 1))
        static let sunrise = Color.dynamic(light: UIColor(red: 1.00, green: 0.70, blue: 0.25, alpha: 1), dark: UIColor(red: 1.00, green: 0.78, blue: 0.36, alpha: 1))
        static let coral = Color.dynamic(light: UIColor(red: 0.93, green: 0.36, blue: 0.27, alpha: 1), dark: UIColor(red: 1.00, green: 0.48, blue: 0.38, alpha: 1))
        static let sky = Color.dynamic(light: UIColor(red: 0.22, green: 0.58, blue: 0.86, alpha: 1), dark: UIColor(red: 0.46, green: 0.76, blue: 1.00, alpha: 1))
        static let grape = Color.dynamic(light: UIColor(red: 0.49, green: 0.35, blue: 0.80, alpha: 1), dark: UIColor(red: 0.68, green: 0.58, blue: 1.00, alpha: 1))
        static let ink = Color.dynamic(light: UIColor(red: 0.14, green: 0.18, blue: 0.15, alpha: 1), dark: UIColor(red: 0.93, green: 0.96, blue: 0.91, alpha: 1))
        static let softText = Color.dynamic(light: UIColor(red: 0.38, green: 0.43, blue: 0.37, alpha: 1), dark: UIColor(red: 0.76, green: 0.82, blue: 0.73, alpha: 1))
        static let card = Color.dynamic(light: UIColor(red: 1.00, green: 0.98, blue: 0.92, alpha: 1), dark: UIColor(red: 0.13, green: 0.17, blue: 0.14, alpha: 1))
        static let elevatedCard = Color.dynamic(light: UIColor(red: 1.00, green: 0.99, blue: 0.95, alpha: 1), dark: UIColor(red: 0.17, green: 0.22, blue: 0.18, alpha: 1))
        static let pageBackground = Color.dynamic(light: UIColor(red: 0.95, green: 0.92, blue: 0.82, alpha: 1), dark: UIColor(red: 0.07, green: 0.10, blue: 0.08, alpha: 1))
        static let groupedBackground = Color.dynamic(light: UIColor(red: 0.97, green: 0.94, blue: 0.86, alpha: 1), dark: UIColor(red: 0.10, green: 0.13, blue: 0.10, alpha: 1))
    }

    struct Gradients {
        static let meadowGlow = LinearGradient(
            colors: [Colors.leaf, Colors.meadow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let sunriseGlow = LinearGradient(
            colors: [Colors.sunrise, Colors.coral],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let creamGlow = LinearGradient(
            colors: [Colors.cream, Colors.mint.opacity(0.78)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let xpGlow = LinearGradient(
            colors: [Colors.sky, Colors.grape],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let pageGlow = LinearGradient(
            colors: [Colors.pageBackground, Colors.groupedBackground],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    struct Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let xLarge: CGFloat = 24
    }

    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let pill: CGFloat = 999
    }

    struct Typography {
        static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            .system(style, design: .rounded, weight: weight)
        }

        static func reader(size: Double) -> Font {
            .system(size: size, weight: .regular, design: .serif)
        }
    }

    struct Shadows {
        static let cardColor = Color.black.opacity(0.16)
        static let glowColor = Colors.leaf.opacity(0.24)

        static func card(radius: CGFloat = 14, y: CGFloat = 6) -> some ViewModifier {
            ShadowStyle(color: cardColor, radius: radius, x: 0, y: y)
        }

        static func glow(radius: CGFloat = 18, y: CGFloat = 8) -> some ViewModifier {
            ShadowStyle(color: glowColor, radius: radius, x: 0, y: y)
        }
    }
}

private extension Color {
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

private struct ShadowStyle: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: x, y: y)
    }
}
