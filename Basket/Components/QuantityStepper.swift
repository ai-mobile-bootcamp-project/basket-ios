import SwiftUI

/// − / number / + stepper. Full style for the item form and product detail, compact style for product cards.
@MainActor struct QuantityStepper: View {
    enum Style { case full, compact }

    private let value: Int
    private let canDecrement: Bool
    private let canIncrement: Bool
    private let style: Style
    private let onDecrement: () -> Void
    private let onIncrement: () -> Void

    init(value: Binding<Int>, range: ClosedRange<Int> = BasketRules.quantityRange, style: Style = .full) {
        let current = min(max(value.wrappedValue, range.lowerBound), range.upperBound)
        self.value = current
        self.canDecrement = current > range.lowerBound
        self.canIncrement = current < range.upperBound
        self.style = style
        self.onDecrement = {
            let clamped = min(max(value.wrappedValue, range.lowerBound), range.upperBound)
            if clamped > range.lowerBound {
                value.wrappedValue = clamped - 1
            }
        }
        self.onIncrement = {
            let clamped = min(max(value.wrappedValue, range.lowerBound), range.upperBound)
            if clamped < range.upperBound {
                value.wrappedValue = clamped + 1
            }
        }
    }

    init(value: Int, canDecrement: Bool, canIncrement: Bool, style: Style = .compact,
         onDecrement: @escaping () -> Void, onIncrement: @escaping () -> Void) {
        self.value = value
        self.canDecrement = canDecrement
        self.canIncrement = canIncrement
        self.style = style
        self.onDecrement = onDecrement
        self.onIncrement = onIncrement
    }

    var body: some View {
        switch style {
        case .full:
            fullStepper
        case .compact:
            compactStepper
        }
    }

    private var fullStepper: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(BasketFont.titleMedium)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .accessibilityHidden(true)
            }
            .buttonStyle(.borderless)
            .disabled(!canDecrement)

            Text(String(value))
                .font(BasketFont.Money.body)
                .foregroundColor(BasketColor.onSurface)
                .lineLimit(1)
                .frame(minWidth: 44)
                .accessibilityLabel(String(value))

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(BasketFont.titleMedium)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .accessibilityHidden(true)
            }
            .buttonStyle(.borderless)
            .disabled(!canIncrement)
        }
        .tint(BasketColor.primary)
        .overlay(
            Capsule()
                .strokeBorder(BasketColor.outlineVariant, lineWidth: 1)
        )
    }

    private var compactStepper: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(BasketFont.labelLarge)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .accessibilityHidden(true)
            }
            .buttonStyle(.borderless)
            .disabled(!canDecrement)

            Text(String(value))
                .font(BasketFont.Money.small)
                .fontWeight(.semibold)
                .foregroundColor(BasketColor.onPrimaryContainer)
                .lineLimit(1)
                .frame(minWidth: 20)
                .accessibilityLabel(String(value))

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(BasketFont.labelLarge)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .accessibilityHidden(true)
            }
            .buttonStyle(.borderless)
            .disabled(!canIncrement)
        }
        .tint(BasketColor.onPrimaryContainer)
        .background(
            Capsule()
                .fill(BasketColor.primaryContainer)
                .padding(.vertical, BasketSpacing.sm)
        )
    }
}
