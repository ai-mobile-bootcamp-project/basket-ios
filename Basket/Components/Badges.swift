import SwiftUI

/// Discount pill, e.g. "−13%" on a product card or "Save 13%" on product detail.
@MainActor struct DiscountBadge: View {
    private let text: String

    init(text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: BasketSpacing.xs) {
            Image(systemName: "tag")
                .font(BasketFont.labelSmall)
                .accessibilityHidden(true)
            Text(text)
                .font(BasketFont.labelMedium.monospacedDigit())
                .lineLimit(1)
        }
        .foregroundColor(BasketColor.onTertiaryContainer)
        .padding(.horizontal, BasketSpacing.sm)
        .padding(.vertical, BasketSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous)
                .fill(BasketColor.tertiaryContainer)
        )
        .accessibilityElement(children: .combine)
    }
}

/// Stock badge: icon and text for low stock and out of stock; nothing when the product is in stock.
@MainActor struct StockBadge: View {
    private let availability: Availability
    private let lowText: String
    private let outText: String

    init(availability: Availability, lowText: String, outText: String) {
        self.availability = availability
        self.lowText = lowText
        self.outText = outText
    }

    var body: some View {
        switch availability {
        case .inStock:
            EmptyView()
        case .lowStock:
            badge(systemImage: "exclamationmark.triangle.fill",
                  text: lowText,
                  foreground: BasketColor.onWarningContainer,
                  background: BasketColor.warningContainer)
        case .outOfStock:
            badge(systemImage: "xmark",
                  text: outText,
                  foreground: BasketColor.onSurfaceVariant,
                  background: BasketColor.surfaceContainerHighest)
        }
    }

    private func badge(systemImage: String, text: String, foreground: Color, background: Color) -> some View {
        HStack(spacing: BasketSpacing.xs) {
            Image(systemName: systemImage)
                .font(BasketFont.labelSmall)
                .accessibilityHidden(true)
            Text(text)
                .font(BasketFont.labelMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(foreground)
        .padding(.horizontal, BasketSpacing.sm)
        .padding(.vertical, BasketSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous)
                .fill(background)
        )
        .accessibilityElement(children: .combine)
    }
}
