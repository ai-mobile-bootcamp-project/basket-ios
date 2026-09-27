import SwiftUI

/// Trip totals shown above the List detail actions: label on the leading side, amount on the trailing side.
@MainActor struct TotalsFooter: View {
    let totalCents: Int
    let inBasketCents: Int

    init(totalCents: Int, inBasketCents: Int) {
        self.totalCents = totalCents
        self.inBasketCents = inBasketCents
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.sm) {
                Text(verbatim: "Total")
                    .font(BasketFont.bodyLarge)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: BasketSpacing.sm)

                Text(money(totalCents))
                    .font(BasketFont.Money.display)
                    .foregroundColor(BasketColor.onSurface)
                    .multilineTextAlignment(.trailing)
                    .layoutPriority(1)
            }

            HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.sm) {
                Text(verbatim: "In basket")
                    .font(BasketFont.bodyLarge)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: BasketSpacing.sm)

                Text(money(inBasketCents))
                    .font(BasketFont.Money.body)
                    .foregroundColor(BasketColor.onSurface)
                    .multilineTextAlignment(.trailing)
                    .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func money(_ cents: Int) -> String {
        "$" + String(format: "%.2f", Double(cents) / 100)
    }
}
