import SwiftUI

/// State and actions for one shopping list: sections, totals, removal with Undo, share text.
@MainActor final class ListDetailViewModel: ObservableObject {
    @Published var isBasketExpanded = true

    let listId: UUID
    private let store: BasketStore
    private let toast: ToastCenter
    private var lastRemoved: ListItem?

    init(listId: UUID, store: BasketStore, toast: ToastCenter) {
        self.listId = listId
        self.store = store
        self.toast = toast
    }

    // MARK: - Sections

    func sections(for list: ShoppingList, categories: [ItemCategory], movingTicked: Bool = false) -> BasketRules.ListSections {
        let toBuyItems = movingTicked ? list.items.filter { !$0.isTicked } : list.items
        let other = categories.first { $0.isOther }

        var categoriesById: [UUID: ItemCategory] = [:]
        var assigned: [(categoryId: UUID, item: ListItem)] = []
        for item in toBuyItems {
            guard let category = categories.first(where: { $0.id == item.categoryId }) ?? other else { continue }
            categoriesById[category.id] = category
            assigned.append((categoryId: category.id, item: item))
        }

        let grouped = Dictionary(grouping: assigned, by: { $0.categoryId })
        let toBuy: [BasketRules.ItemSection] = grouped
            .compactMap { entry -> BasketRules.ItemSection? in
                guard let category = categoriesById[entry.key] else { return nil }
                let items = entry.value.map { $0.item }
                return BasketRules.ItemSection(category: category, items: BasketRules.sortedItems(items))
            }
            .sorted { a, b in
                BasketRules.compareNames(a.category.name, b.category.name) == .orderedAscending
            }

        let inBasket: [ListItem] = movingTicked ? BasketRules.sortedItems(list.items.filter(\.isTicked)) : []
        return BasketRules.ListSections(toBuy: toBuy, inBasket: inBasket)
    }

    // MARK: - Totals

    func totals(for list: ShoppingList) -> (total: Int, inBasket: Int) {
        let total = list.items.reduce(0) { $0 + ($1.priceCents ?? 0) * $1.quantity }
        let inBasket = list.items.filter(\.isTicked).reduce(0) { $0 + ($1.priceCents ?? 0) * $1.quantity }
        return (total: total, inBasket: inBasket)
    }

    // MARK: - Removing items

    func remove(at index: Int, in list: ShoppingList, locale: Locale) {
        guard list.items.indices.contains(index) else { return }
        remove(list.items[index], locale: locale)
    }

    func remove(_ item: ListItem, locale: Locale) {
        lastRemoved = store.deleteItem(id: item.id)
        toast.show(L10n.format("detail.removed", locale, item.name),
                   actionTitle: L10n.tr("common.undo", locale)) { [weak self] in
            self?.undoRemove()
        }
    }

    func undoRemove() {
        lastRemoved = nil
    }

    // MARK: - List actions

    func clearBasket(listId: UUID) {
        store.removeAllItems(listId: listId)
    }

    /// Removes the bought items at once; Undo puts them back.
    func finishShopping(listId: UUID, locale: Locale) {
        let bought = store.list(id: listId)?.items.filter(\.isTicked) ?? []
        store.removeTickedItems(listId: listId)
        let basketStore = store
        toast.show(L10n.tr("detail.finish.done", locale),
                   actionTitle: L10n.tr("common.undo", locale)) {
            basketStore.restoreItems(bought)
        }
    }

    func rename(listId: UUID, to name: String) {
        store.renameList(id: listId, name: name)
    }

    // MARK: - Share

    func shareText(for list: ShoppingList, categories: [ItemCategory], locale: Locale) -> String {
        let toBuy: [ListItem] = BasketRules.sections(items: list.items.filter { !$0.isTicked },
                                                     categories: categories,
                                                     moveTickedDown: false).toBuy.flatMap { $0.items }
        let inBasket: [ListItem] = BasketRules.sections(items: list.items.filter(\.isTicked),
                                                        categories: categories,
                                                        moveTickedDown: false).toBuy.flatMap { $0.items }
        let ordered = toBuy + inBasket

        var lines = [list.name]
        var currentTicked = ordered.first!.isTicked
        lines.append(header(ticked: currentTicked, toBuyCount: toBuy.count, inBasketCount: inBasket.count, locale: locale))
        for item in ordered {
            if item.isTicked != currentTicked {
                currentTicked = item.isTicked
                lines.append(header(ticked: currentTicked, toBuyCount: toBuy.count, inBasketCount: inBasket.count, locale: locale))
            }
            lines.append(line(for: item, locale: locale))
        }

        let totals = BasketRules.totals(for: list.items)
        var totalLine = L10n.format("detail.share.total", locale, BasketRules.formatMoney(totals.totalCents, locale: locale))
        if totals.withoutPriceCount > 0 {
            let withoutPrice = L10n.format("detail.withoutPrice", locale, totals.withoutPriceCount)
            totalLine += " (" + withoutPrice + ")"
        }
        lines.append(totalLine)
        return lines.joined(separator: "\n")
    }

    private func header(ticked: Bool, toBuyCount: Int, inBasketCount: Int, locale: Locale) -> String {
        if ticked {
            return L10n.format("detail.share.inBasket", locale, inBasketCount)
        }
        return L10n.format("detail.share.toBuy", locale, toBuyCount)
    }

    private func line(for item: ListItem, locale: Locale) -> String {
        var text = (item.isTicked ? "\u{2713} " : "\u{2022} ") + item.name
        if !item.note.isEmpty {
            text += " (" + item.note + ")"
        }
        if item.quantity > 1 {
            text += " \u{00D7} " + String(item.quantity)
        }
        if let lineTotal = BasketRules.lineTotalCents(item) {
            text += " \u{2014} " + BasketRules.formatMoney(lineTotal, locale: locale)
        }
        return text
    }
}
