import Foundation

/// Adds catalog products to a shopping list with their price and mapped category.
@MainActor
struct CatalogAdder {
    let store: BasketStore

    @discardableResult
    func add(_ product: CatalogProduct, quantity: Int, to listId: UUID) -> UUID {
        let unitPrice = product.price * (1 - product.discountPercentage / 100)
        let category = store.category(for: product.defaultCategory) ?? store.otherCategory
        let draft = ItemDraft(
            name: product.title,
            quantity: quantity,
            priceCents: Int(unitPrice * 100),
            categoryId: category?.id,
            catalogProductId: product.id
        )
        return store.addItem(draft, to: listId)
    }
}
