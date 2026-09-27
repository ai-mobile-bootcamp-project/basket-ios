import SwiftUI

/// Bottom sheet that closes a shopping trip: what was bought, what was not, and what to keep.
@MainActor struct FinishShoppingSheet: View {
    let list: ShoppingList
    let onKeepRest: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var didChoose = false

    init(list: ShoppingList, onKeepRest: @escaping () -> Void) {
        self.list = list
        self.onKeepRest = onKeepRest
    }

    var body: some View {
        let progress = BasketRules.progress(for: list.items)
        let totals = BasketRules.totals(for: list.items)
        let notBought = BasketRules.sortedItems(list.items.filter { !$0.isTicked }).map(\.name)
        let spent = BasketRules.formatMoney(totals.inBasketCents, locale: locale)

        return ScrollView {
            VStack(alignment: .leading, spacing: BasketSpacing.lg) {
                Text(L10n.tr("detail.finishShopping", locale))
                    .font(BasketFont.titleLarge)
                    .foregroundColor(BasketColor.onSurface)
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(BasketColor.success)
                        .accessibilityHidden(true)
                    Text(L10n.format("detail.finish.summary", locale, progress.ticked, progress.count, spent))
                        .font(BasketFont.titleMedium)
                        .foregroundColor(BasketColor.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: BasketSpacing.xs) {
                    if notBought.isEmpty {
                        Text(L10n.tr("detail.finish.allBought", locale))
                            .font(BasketFont.bodyLarge)
                            .foregroundColor(BasketColor.onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(L10n.tr("detail.finish.notBought", locale))
                            .font(BasketFont.titleSmall)
                            .foregroundColor(BasketColor.secondary)
                        Text(notBought.joined(separator: ", "))
                            .font(BasketFont.bodyLarge)
                            .foregroundColor(BasketColor.onSurface)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)

                VStack(spacing: BasketSpacing.md) {
                    Button {
                        guard !didChoose else { return }
                        didChoose = true
                        onKeepRest()
                        dismiss()
                    } label: {
                        Text(L10n.tr("detail.finish.keepRest", locale))
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        guard !didChoose else { return }
                        didChoose = true
                        dismiss()
                    } label: {
                        Text(L10n.tr("detail.finish.keepAll", locale))
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(TonalButtonStyle())
                }
                .padding(.top, BasketSpacing.sm)
            }
            .padding(.horizontal, BasketSpacing.lg)
            .padding(.top, BasketSpacing.xl)
            .padding(.bottom, BasketSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(BasketColor.surface.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
