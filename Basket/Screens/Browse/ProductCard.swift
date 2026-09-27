import SwiftUI

/// Grid card for one catalog product: photo with discount and stock badges, name, prices and the add control.
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
        VStack(alignment: .leading, spacing: 0) {
            thumbnail
                .layoutPriority(1)
            details
                .padding(.horizontal, BasketSpacing.md)
                .padding(.top, BasketSpacing.md)
            Spacer(minLength: BasketSpacing.xs)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                addControl
                    .accessibilitySortPriority(1)
            }
            .padding(.horizontal, BasketSpacing.sm)
            .padding(.bottom, BasketSpacing.sm)
        }
        .frame(height: 300)
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

    // MARK: Photo

    private var thumbnail: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .overlay {
                ProductImage(url: product.thumbnailURL)
                    .padding(BasketSpacing.sm)
            }
            .background(BasketColor.surfaceContainerHigh)
            .clipped()
            .overlay(alignment: .topLeading) {
                if let percent = discountPercent {
                    DiscountBadge(text: "\u{2212}" + String(percent) + "%")
                        .padding(BasketSpacing.sm)
                        .accessibilitySortPriority(2)
                }
            }
            .overlay(alignment: .bottomLeading) {
                stockBadges
                    .padding(BasketSpacing.sm)
                    .accessibilitySortPriority(2)
            }
    }

    private var stockBadges: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
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
    }

    // MARK: Add control

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

    // MARK: Name and prices

    private var details: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            Text(product.title)
                .font(BasketFont.bodyLarge)
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
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(BasketColor.surfaceContainerHighest)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            VStack(alignment: .leading, spacing: BasketSpacing.xs) {
                Text(verbatim: "Product name")
                    .font(BasketFont.bodyLarge)
                    .lineLimit(2)
                Text(verbatim: "$0.00")
                    .font(BasketFont.Money.title)
                    .lineLimit(1)
            }
            .padding(.horizontal, BasketSpacing.md)
            .padding(.top, BasketSpacing.md)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Circle()
                    .fill(BasketColor.surfaceContainerHighest)
                    .frame(width: 48, height: 48)
            }
            .padding(BasketSpacing.sm)
        }
        .redacted(reason: .placeholder)
        .foregroundColor(BasketColor.onSurfaceVariant)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                .fill(BasketColor.surfaceContainerLow)
        )
        .clipShape(RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous))
        .accessibilityHidden(true)
    }
}
