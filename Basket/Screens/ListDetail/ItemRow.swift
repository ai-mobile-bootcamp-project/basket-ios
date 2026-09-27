import SwiftUI

/// One item on List detail: checkbox, name with catalog mark, note, quantity × unit price, line total.
@MainActor struct ItemRow: View {
    let item: ListItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onRemove: () -> Void

    @Environment(\.locale) private var locale

    init(item: ListItem,
         onToggle: @escaping () -> Void,
         onEdit: @escaping () -> Void,
         onRemove: @escaping () -> Void) {
        self.item = item
        self.onToggle = onToggle
        self.onEdit = onEdit
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(alignment: .center, spacing: BasketSpacing.xs) {
            checkbox

            HStack(alignment: .center, spacing: BasketSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    nameLine
                    detailLine
                }

                Spacer(minLength: BasketSpacing.sm)

                Text(lineTotalText)
                    .font(BasketFont.Money.body)
                    .foregroundColor(item.isTicked ? BasketColor.onSurfaceVariant : BasketColor.onSurface)
                    .strikethrough(item.isTicked)
                    .lineLimit(1)
            }
            .opacity(item.isTicked ? 0.7 : 1)
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit()
            }
        }
        .frame(height: 56)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default) {
            onToggle()
        }
        .accessibilityAction(named: L10n.tr("common.edit", locale)) {
            onEdit()
        }
        .accessibilityAction(named: L10n.tr("common.remove", locale)) {
            onRemove()
        }
    }

    // MARK: - Pieces

    private var checkbox: some View {
        Button {
            onToggle()
        } label: {
            Image(systemName: item.isTicked ? "checkmark.square.fill" : "square")
                .font(.title2)
                .foregroundColor(item.isTicked ? BasketColor.primary : BasketColor.onSurfaceVariant)
                .frame(width: BasketSpacing.touchTarget, height: BasketSpacing.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var nameLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.sm) {
            Text(item.name)
                .font(BasketFont.bodyLarge)
                .foregroundColor(item.isTicked ? BasketColor.onSurfaceVariant : BasketColor.onSurface)
                .strikethrough(item.isTicked)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if item.catalogProductId != nil {
                Image(systemName: "storefront")
                    .font(BasketFont.labelMedium)
                    .foregroundColor(BasketColor.secondary)
                    .accessibilityHidden(true)
            }
        }
    }

    private var detailLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.xs) {
            if !item.note.isEmpty {
                Text(item.note + " \u{00B7}")
                    .font(BasketFont.bodyMedium)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .lineLimit(1)
            }

            Text(quantityPriceText)
                .font(BasketFont.Money.small)
                .foregroundColor(BasketColor.onSurfaceVariant)
                .lineLimit(1)
                .layoutPriority(1)
        }
    }

    // MARK: - Texts

    private var unitPriceText: String {
        BasketRules.formatMoney(item.priceCents ?? 0, locale: locale)
    }

    private var quantityPriceText: String {
        if item.quantity == 1 {
            return unitPriceText
        }
        return L10n.format("detail.row.qtyPrice", locale, item.quantity, unitPriceText)
    }

    private var lineTotalText: String {
        BasketRules.formatMoney((item.priceCents ?? 0) * item.quantity, locale: locale)
    }

    private var accessibilityText: String {
        var parts: [String] = [item.name]
        if !item.note.isEmpty {
            parts.append(item.note)
        }
        if let unitCents = item.priceCents {
            let unit = BasketRules.formatMoney(unitCents, locale: locale)
            parts.append(L10n.format("detail.row.a11y.qtyPrice", locale, item.quantity, unit))
            if let lineCents = BasketRules.lineTotalCents(item) {
                parts.append(BasketRules.formatMoney(lineCents, locale: locale))
            }
        } else {
            parts.append(L10n.format("detail.row.a11y.quantity", locale, item.quantity))
            parts.append(L10n.tr("detail.row.a11y.noPrice", locale))
        }
        if item.isTicked {
            parts.append(L10n.tr("detail.row.a11y.inBasket", locale))
        } else {
            parts.append(L10n.tr("detail.row.a11y.notInBasket", locale))
        }
        return parts.joined(separator: ", ")
    }
}
