import SwiftUI

/// Screen 5: one catalog product in full, added to the open list with a chosen quantity.
@MainActor
struct ProductDetailView: View {
    let listId: UUID
    let product: CatalogProduct

    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var quantity = 1
    @State private var hasSetInitialQuantity = false
    @State private var isExpanded = false
    @State private var isSubmitting = false

    init(listId: UUID, product: CatalogProduct) {
        self.listId = listId
        self.product = product
    }

    private var existing: ListItem? {
        store.list(id: listId)?.items.first(where: { $0.catalogProductId == product.id })
    }

    private var listName: String {
        store.list(id: listId)?.name ?? ""
    }

    private var isOutOfStock: Bool {
        product.availability == .outOfStock
    }

    private var discountPercent: Int? {
        BasketRules.discountBadgePercent(product.discountPercentage)
    }

    private var payText: String {
        BasketRules.formatMoney(BasketRules.priceYouPayCents(for: product), locale: locale)
    }

    private var originalText: String {
        BasketRules.formatMoney(BasketRules.cents(fromDollars: product.price), locale: locale)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                productImage
                VStack(alignment: .leading, spacing: BasketSpacing.lg) {
                    header
                    priceBlock
                    stockLine
                    descriptionBlock
                    ratingRow
                }
                .padding(BasketSpacing.lg)
                .padding(.bottom, BasketSpacing.md)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(BasketColor.surface.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            guard !hasSetInitialQuantity else { return }
            hasSetInitialQuantity = true
            if let current = existing {
                quantity = current.quantity
            }
        }
    }

    // MARK: Image and header

    private var productImage: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ProductImage(url: product.imageURL)
            }
            .frame(maxWidth: .infinity)
            .background(BasketColor.surfaceContainerHigh)
            .clipped()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.md) {
            Text(product.title)
                .font(BasketFont.headlineMedium)
                .foregroundColor(BasketColor.onSurface)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            categoryTag
        }
    }

    private var categoryTag: some View {
        HStack(spacing: BasketSpacing.sm) {
            Text(product.defaultCategory.emoji)
                .accessibilityHidden(true)
            Text(L10n.tr("category." + product.defaultCategory.rawValue, locale))
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(BasketFont.labelLarge)
        .foregroundColor(BasketColor.onSecondaryContainer)
        .padding(.horizontal, BasketSpacing.md)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous)
                .fill(BasketColor.secondaryContainer)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: Price

    private var priceBlock: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: BasketSpacing.md) {
                pricePair
                saveBadge
            }
            VStack(alignment: .leading, spacing: BasketSpacing.sm) {
                pricePair
                saveBadge
            }
            VStack(alignment: .leading, spacing: BasketSpacing.sm) {
                VStack(alignment: .leading, spacing: BasketSpacing.xs) {
                    payPrice
                    originalPrice
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(priceAccessibilityLabel)
                saveBadge
            }
        }
    }

    private var pricePair: some View {
        HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.sm) {
            payPrice
            originalPrice
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(priceAccessibilityLabel)
    }

    @ViewBuilder
    private var saveBadge: some View {
        if let percent = discountPercent {
            DiscountBadge(text: L10n.format("product.save", locale, percent))
                .fixedSize()
        }
    }

    private var payPrice: some View {
        Text(payText)
            .font(BasketFont.Money.display)
            .foregroundColor(BasketColor.onSurface)
            .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private var originalPrice: some View {
        if discountPercent != nil {
            Text(originalText)
                .font(BasketFont.Money.body)
                .strikethrough()
                .foregroundColor(BasketColor.onSurfaceVariant)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var priceAccessibilityLabel: String {
        if discountPercent != nil {
            return L10n.format("product.price.a11y", locale, payText, originalText)
        }
        return payText
    }

    // MARK: Stock

    private var stockText: String {
        switch product.availability {
        case .inStock: return "In stock"
        case .lowStock: return "Low stock"
        case .outOfStock: return "Out of stock"
        }
    }

    private var stockIcon: String {
        switch product.availability {
        case .inStock: return "checkmark.circle"
        case .lowStock: return "exclamationmark.triangle"
        case .outOfStock: return "xmark.circle"
        }
    }

    private var stockColor: Color {
        switch product.availability {
        case .inStock: return BasketColor.success
        case .lowStock: return BasketColor.warning
        case .outOfStock: return BasketColor.error
        }
    }

    private var stockLine: some View {
        HStack(spacing: BasketSpacing.sm) {
            Image(systemName: stockIcon)
                .font(BasketFont.titleMedium)
                .accessibilityHidden(true)
            Text(stockText)
                .font(BasketFont.bodyLarge)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(stockColor)
        .accessibilityElement(children: .combine)
    }

    // MARK: Description

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(product.description)
                .font(BasketFont.bodyLarge)
                .foregroundColor(BasketColor.onSurfaceVariant)
                .lineLimit(isExpanded ? nil : 4)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Text(verbatim: isExpanded ? "Less" : "More")
                    .font(BasketFont.labelLarge)
                    .foregroundColor(BasketColor.primary)
                    .frame(minHeight: BasketSpacing.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Rating

    private var ratingText: String {
        BasketRules.formatRating(product.rating, locale: locale)
    }

    private var ratingRow: some View {
        HStack(spacing: BasketSpacing.xs) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: starSymbol(at: index))
                    .foregroundColor(BasketColor.warning)
            }
            Text(ratingText)
                .font(BasketFont.titleSmall)
                .foregroundColor(BasketColor.onSurface)
                .padding(.leading, BasketSpacing.xs)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("product.rating.a11y", locale, ratingText))
    }

    private func starSymbol(at index: Int) -> String {
        let remainder = product.rating - Double(index)
        if remainder >= 0.75 {
            return "star.fill"
        }
        if remainder >= 0.25 {
            return "star.leadinghalf.filled"
        }
        return "star"
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        let current = existing
        return VStack(alignment: .leading, spacing: BasketSpacing.sm) {
            if let current = current {
                Text(L10n.format("product.onList", locale, current.quantity))
                    .font(BasketFont.titleSmall)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: BasketSpacing.md) {
                    quantityStepper
                    submitButton(current: current)
                }
            } else {
                HStack(spacing: BasketSpacing.md) {
                    quantityStepper
                    submitButton(current: current)
                }
            }
        }
        .padding(.horizontal, BasketSpacing.lg)
        .padding(.top, BasketSpacing.md)
        .padding(.bottom, BasketSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            BasketColor.surface
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BasketColor.outlineVariant)
                .frame(height: 0.5)
        }
    }

    private var quantityStepper: some View {
        QuantityStepper(value: $quantity)
            .fixedSize()
            .disabled(isOutOfStock)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.tr("product.quantity", locale))
    }

    private func submitButton(current: ListItem?) -> some View {
        Button {
            submit(current: current)
        } label: {
            Text(primaryTitle(current: current))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isOutOfStock || isSubmitting)
    }

    private func primaryTitle(current: ListItem?) -> String {
        if isOutOfStock {
            return L10n.tr("product.outOfStock", locale)
        }
        if current != nil {
            return L10n.tr("product.update", locale)
        }
        let totalCents = BasketRules.priceYouPayCents(for: product) * quantity
        return L10n.format("product.addTo", locale, listName, BasketRules.formatMoney(totalCents, locale: locale))
    }

    private func submit(current: ListItem?) {
        guard !isSubmitting, !isOutOfStock else { return }
        isSubmitting = true

        let undoTitle = L10n.tr("common.undo", locale)
        if let current = current {
            let itemId = current.id
            let oldQuantity = current.quantity
            store.setQuantity(itemId: itemId, quantity)
            router.pop()
            toast.show(L10n.format("product.updated", locale, product.title), actionTitle: undoTitle) { [store] in
                store.setQuantity(itemId: itemId, oldQuantity)
            }
        } else {
            let name = listName
            let id = CatalogAdder(store: store).add(product, quantity: quantity, to: listId)
            router.pop()
            toast.show(L10n.format("browse.added", locale, product.title, name), actionTitle: undoTitle) { [store] in
                _ = store.deleteItem(id: id)
            }
        }
    }
}
