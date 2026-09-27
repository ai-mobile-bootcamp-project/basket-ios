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

/// Extended floating action button: primary / onPrimary capsule with a shadow.
struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FloatingButtonBody(configuration: configuration)
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
                RoundedRectangle(cornerRadius: BasketShape.large, style: .continuous)
                    .fill(isEnabled ? BasketColor.primary : BasketColor.surfaceContainerHighest)
            )
            .contentShape(RoundedRectangle(cornerRadius: BasketShape.large, style: .continuous))
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
                RoundedRectangle(cornerRadius: BasketShape.large, style: .continuous)
                    .fill(isEnabled ? BasketColor.primaryContainer : BasketColor.surfaceContainerHighest)
            )
            .contentShape(RoundedRectangle(cornerRadius: BasketShape.large, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct FloatingButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(BasketFont.titleMedium)
            .multilineTextAlignment(.center)
            .foregroundColor(isEnabled ? BasketColor.onPrimary : BasketColor.onSurface.opacity(0.38))
            .padding(.horizontal, 20)
            .padding(.vertical, BasketSpacing.md)
            .frame(minHeight: 56)
            .background(
                Capsule()
                    .fill(isEnabled ? BasketColor.primary : BasketColor.surfaceContainerHighest)
                    .shadow(color: Color.black.opacity(configuration.isPressed ? 0.14 : 0.24),
                            radius: configuration.isPressed ? 3 : 6, x: 0, y: 3)
            )
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
