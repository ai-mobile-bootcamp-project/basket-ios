import SwiftUI

/// Full-width filled button: primary / onPrimary, large corners.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration)
    }
}

/// Full-width tonal button: primaryContainer / onPrimaryContainer.
struct TonalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TonalButtonBody(configuration: configuration)
    }
}

/// Extended floating action button: capsule with a shadow. Primary by default, primaryContainer when tonal.
struct FloatingButtonStyle: ButtonStyle {
    var tonal: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        FloatingButtonBody(configuration: configuration, tonal: tonal)
    }
}

/// Outlined capsule button that hugs its content: outline border, primary label.
struct OutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OutlinedButtonBody(configuration: configuration)
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(BasketFont.titleMedium)
            .multilineTextAlignment(.center)
            .foregroundColor(isEnabled ? BasketColor.onPrimary : BasketColor.onSurface.opacity(0.38))
            .padding(.horizontal, BasketSpacing.xl)
            .padding(.vertical, BasketSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                Capsule()
                    .fill(isEnabled ? BasketColor.primary : BasketColor.surfaceContainerHighest)
            )
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct TonalButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(BasketFont.titleMedium)
            .multilineTextAlignment(.center)
            .foregroundColor(isEnabled ? BasketColor.onPrimaryContainer : BasketColor.onSurface.opacity(0.38))
            .padding(.horizontal, BasketSpacing.xl)
            .padding(.vertical, BasketSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                Capsule()
                    .fill(isEnabled ? BasketColor.primaryContainer : BasketColor.surfaceContainerHighest)
            )
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct FloatingButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let tonal: Bool
    @Environment(\.isEnabled) private var isEnabled

    private var fill: Color {
        guard isEnabled else { return BasketColor.surfaceContainerHighest }
        return tonal ? BasketColor.primaryContainer : BasketColor.primary
    }

    private var content: Color {
        guard isEnabled else { return BasketColor.onSurface.opacity(0.38) }
        return tonal ? BasketColor.onPrimaryContainer : BasketColor.onPrimary
    }

    var body: some View {
        configuration.label
            .font(BasketFont.titleMedium)
            .multilineTextAlignment(.center)
            .foregroundColor(content)
            .padding(.horizontal, 20)
            .padding(.vertical, BasketSpacing.md)
            .frame(minHeight: 56)
            .background(
                Capsule()
                    .fill(fill)
                    .shadow(color: Color.black.opacity(configuration.isPressed ? 0.14 : 0.24),
                            radius: configuration.isPressed ? 3 : 6, x: 0, y: 3)
            )
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct OutlinedButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(BasketFont.titleMedium)
            .multilineTextAlignment(.center)
            .foregroundColor(isEnabled ? BasketColor.primary : BasketColor.onSurface.opacity(0.38))
            .padding(.horizontal, BasketSpacing.xl)
            .padding(.vertical, BasketSpacing.md)
            .frame(minHeight: 52)
            .overlay(
                Capsule()
                    .strokeBorder(isEnabled ? BasketColor.outline : BasketColor.outlineVariant, lineWidth: 1)
            )
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
