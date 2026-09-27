import SwiftUI

/// Trip totals shown above the List detail actions.
@MainActor struct TotalsFooter: View {
    let totalCents: Int
    let inBasketCents: Int

    init(totalCents: Int, inBasketCents: Int) {
        self.totalCents = totalCents
        self.inBasketCents = inBasketCents
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            Text("Total " + money(totalCents))
                .font(BasketFont.Money.display)
                .foregroundColor(BasketColor.onSurface)
                .fixedSize(horizontal: false, vertical: true)

            Text("In basket " + money(inBasketCents))
                .font(BasketFont.Money.small)
                .foregroundColor(BasketColor.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func money(_ cents: Int) -> String {
        "$" + String(format: "%.2f", Double(cents) / 100)
    }
}
