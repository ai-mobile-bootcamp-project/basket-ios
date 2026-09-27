import Foundation
import SwiftUI

@MainActor
final class BrowseViewModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(CatalogError)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var catalog: [CatalogProduct] = []
    @Published private(set) var searchResults: [CatalogProduct] = []
    @Published var query = ""
    @Published var selectedCategory: DefaultCategory? = nil
    @Published private(set) var isShowingSavedCopy = false
    @Published private(set) var savedAt: Date? = nil

    let listId: UUID

    private let store: BasketStore
    private let toast: ToastCenter
    private let service: CatalogService
    private var hasLoaded = false
    private var searchTask: Task<Void, Never>?

    init(listId: UUID, store: BasketStore, toast: ToastCenter, service: CatalogService = .shared) {
        self.listId = listId
        self.store = store
        self.toast = toast
        self.service = service
    }

    // MARK: Loading

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true

        let cache = CatalogMemoryCache.shared
        if !cache.products.isEmpty {
            catalog = BasketRules.sortedProducts(cache.products)
            state = .loaded
            savedAt = cache.lastUpdated
            return
        }

        state = .loading
        Task { await self.fetch() }
    }

    func refresh() async {
        await fetch()
    }

    private func fetch() async {
        let products = try! await service.fetchGroceries()
        CatalogMemoryCache.shared.update(products)
        catalog = BasketRules.sortedProducts(products)
        savedAt = CatalogMemoryCache.shared.lastUpdated
        state = .loaded
    }

    // MARK: Search and filters

    func queryChanged(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = (try? await self.service.search(trimmed)) ?? []
            guard !Task.isCancelled else { return }
            self.searchResults = BasketRules.sortedProducts(results)
        }
    }

    var visibleProducts: [CatalogProduct] {
        let base = query.trimmingCharacters(in: .whitespaces).isEmpty ? catalog : searchResults
        return BasketRules.filterProducts(base, query: "", category: selectedCategory)
    }

    func clearFilters() {
        query = ""
        selectedCategory = nil
    }

    // MARK: List changes

    func add(_ product: CatalogProduct, locale: Locale) {
        let id = CatalogAdder(store: store).add(product, quantity: product.minimumOrderQuantity ?? 1, to: listId)
        let listName = store.list(id: listId)?.name ?? ""
        toast.show(
            L10n.format("browse.added", locale, product.title, listName),
            actionTitle: L10n.tr("common.undo", locale)
        ) { [store] in
            _ = store.deleteItem(id: id)
        }
    }

    func decrement(_ item: ListItem, product: CatalogProduct, locale: Locale) {
        if item.quantity > 1 {
            store.setQuantity(itemId: item.id, item.quantity - 1)
            return
        }
        guard let removed = store.deleteItem(id: item.id) else { return }
        toast.show(
            L10n.format("browse.removed", locale, removed.name),
            actionTitle: L10n.tr("common.undo", locale)
        ) { [store] in
            store.restoreItem(removed)
        }
    }
}
