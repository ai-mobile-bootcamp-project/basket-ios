import SwiftUI

// Basket — theme container: palette, shapes and spacing on a 4 pt grid, plus the Theme setting.

enum BasketThemeMode: String, CaseIterable, Codable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum BasketShape {
    /// Chips, badges.
    static let small: CGFloat = 8
    /// Cards, item rows, text fields.
    static let medium: CGFloat = 12
    /// Sheets, dialogs, FAB.
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 28
}

enum BasketSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    /// Minimum touch target for every control (checkbox, stepper buttons, Add +).
    static let touchTarget: CGFloat = 48
    /// Item row minimum height; grows with text.
    static let rowMinHeight: CGFloat = 56
}

private struct BasketPaletteKey: EnvironmentKey {
    static let defaultValue = BasketPalette.light
}

extension EnvironmentValues {
    var basket: BasketPalette {
        get { self[BasketPaletteKey.self] }
        set { self[BasketPaletteKey.self] = newValue }
    }
}

/// Wrap the root view: applies the user's Theme setting (System / Light / Dark) app-wide at once
/// and injects the matching palette. The setting is persisted with @AppStorage so it survives restart.
struct BasketTheme<Content: View>: View {
    @AppStorage("basket.themeMode") private var mode: BasketThemeMode = .system
    @Environment(\.colorScheme) private var systemScheme
    let content: () -> Content

    var body: some View {
        let scheme = mode.colorScheme ?? systemScheme
        content()
            .environment(\.basket, BasketPalette.resolve(scheme))
            .preferredColorScheme(mode.colorScheme)
            .tint(BasketPalette.resolve(scheme).primary)
    }
}
