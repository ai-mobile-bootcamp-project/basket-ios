import SwiftUI

/// Grid card for one catalog product: thumbnail, discount and stock badges, name, prices and the add control.
@MainActor
struct ProductCard: View {
    let product: CatalogProduct
    let quantityOnList: Int?
    let onOpen: () -> Void
    let onAdd: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    @Environment(\.locale) private var locale

    init(product: CatalogProduct,
         quantityOnList: Int?,
         onOpen: @escaping () -> Void,
         onAdd: @escaping () -> Void,
         onIncrement: @escaping () -> Void,
         onDecrement: @escaping () -> Void) {
        self.product = product
        self.quantityOnList = quantityOnList
        self.onOpen = onOpen
        self.onAdd = onAdd
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
    }

    private var discountPercent: Int? {
        BasketRules.discountBadgePercent(product.discountPercentage)
    }

    private var isOutOfStock: Bool {
        product.availability == .outOfStock
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.sm) {
            thumbnail
            details
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(height: 280)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                .stroke(BasketColor.outlineVariant, lineWidth: 0.5)
        }
        .opacity(isOutOfStock ? 0.5 : 1)
        .contentShape(RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous))
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .contain)
    }

    // MARK: Thumbnail

    private var thumbnail: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ProductImage(url: product.thumbnailURL)
            }
            .background(BasketColor.surfaceContainerHigh)
            .clipShape(RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous))
            .overlay(alignment: .topLeading) {
                if let percent = discountPercent {
                    DiscountBadge(text: "\u{2212}" + String(percent) + "%")
                        .padding(6)
                        .accessibilitySortPriority(2)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                addControl
                    .padding(4)
                    .accessibilitySortPriority(1)
            }
    }

    @ViewBuilder
    private var addControl: some View {
        if let quantity = quantityOnList {
            QuantityStepper(
                value: quantity,
                canDecrement: true,
                canIncrement: quantity < 99,
                style: .compact,
                onDecrement: onDecrement,
                onIncrement: onIncrement
            )
        } else {
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(BasketColor.onPrimary)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(BasketColor.primary))
                    .accessibilityHidden(true)
            }
            .buttonStyle(.plain)
            .disabled(isOutOfStock)
        }
    }

    // MARK: Name, prices, stock

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.title)
                .font(BasketFont.titleSmall)
                .foregroundColor(BasketColor.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.xs) {
                Text("$" + String(format: "%.2f", product.price * (1 - product.discountPercentage / 100)))
                    .font(BasketFont.Money.title)
                    .foregroundColor(BasketColor.onSurface)
                    .lineLimit(1)
                if discountPercent != nil {
                    Text("$" + String(format: "%.2f", product.price))
                        .font(BasketFont.Money.small)
                        .strikethrough()
                        .foregroundColor(BasketColor.onSurfaceVariant)
                        .lineLimit(1)
                }
            }

            if product.availabilityStatus == "Low stock" {
                StockBadge(
                    availability: .lowStock,
                    lowText: L10n.tr("browse.lowStock", locale),
                    outText: L10n.tr("browse.outOfStock", locale)
                )
            }
            if isOutOfStock {
                StockBadge(
                    availability: .outOfStock,
                    lowText: L10n.tr("browse.lowStock", locale),
                    outText: L10n.tr("browse.outOfStock", locale)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onOpen() }
        .accessibilitySortPriority(3)
    }
}

/// Placeholder card shown while the catalog loads.
@MainActor
struct ProductCardSkeleton: View {
    init() {}

    var body: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.sm) {
            RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous)
                .fill(BasketColor.surfaceContainerHighest)
                .aspectRatio(1, contentMode: .fit)
            Text(verbatim: "Product name")
                .font(BasketFont.titleSmall)
                .lineLimit(2)
            Text(verbatim: "$0.00")
                .font(BasketFont.Money.title)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .redacted(reason: .placeholder)
        .foregroundColor(BasketColor.onSurfaceVariant)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                .fill(BasketColor.surfaceContainerLow)
        )
        .accessibilityHidden(true)
    }
}
