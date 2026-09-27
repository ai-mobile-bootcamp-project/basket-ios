import SwiftUI

/// One item on List detail: checkbox, name, note, quantity × unit price, line total, catalog mark.
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

            HStack(alignment: .center, spacing: BasketSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(BasketFont.bodyLarge)
                        .foregroundColor(BasketColor.onSurface)
                        .strikethrough(item.isTicked)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(BasketFont.bodySmall)
                            .foregroundColor(BasketColor.onSurfaceVariant)
                            .lineLimit(1)
                    }

                    Text(quantityPriceText)
                        .font(BasketFont.Money.small)
                        .foregroundColor(BasketColor.onSurfaceVariant)
                        .lineLimit(1)
                }

                Spacer(minLength: BasketSpacing.sm)

                if item.catalogProductId != nil {
                    Image(systemName: "tag")
                        .font(BasketFont.labelMedium)
                        .foregroundColor(BasketColor.secondary)
                        .accessibilityHidden(true)
                }

                Text(lineTotalText)
                    .font(BasketFont.Money.body)
                    .foregroundColor(BasketColor.onSurface)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit()
            }
        }
        .frame(height: 56)
        .opacity(item.isTicked ? 0.6 : 1)
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

    private var checkbox: some View {
        Button {
            onToggle()
        } label: {
            Image(systemName: item.isTicked ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(item.isTicked ? BasketColor.primary : BasketColor.outline)
                .frame(width: BasketSpacing.touchTarget, height: BasketSpacing.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
