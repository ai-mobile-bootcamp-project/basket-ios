import SwiftUI

/// Form state for adding an item by hand or editing an existing one.
@MainActor final class ItemFormViewModel: ObservableObject {
    struct Suggestion: Identifiable, Hashable {
        let name: String
        let product: CatalogProduct?
        var id: String { name }
    }

    @Published var name = ""
    @Published var quantity = 1
    @Published var priceText = ""
    @Published var categoryId: UUID? = nil
    @Published var note = ""
    @Published private(set) var isSaving = false
    @Published var duplicate: ListItem? = nil
    @Published private(set) var isNameTouched = false

    let listId: UUID
    let itemId: UUID?
    var isEditing: Bool { itemId != nil }

    private let store: BasketStore
    private let toast: ToastCenter
    private var hasLoaded = false
    private var listItems: [ListItem] = []
    private var initialFields = Fields(name: "", quantity: 1, priceText: "", categoryId: nil, note: "")

    private static let maxSuggestions = 5

    private struct Fields: Equatable {
        var name: String
        var quantity: Int
        var priceText: String
        var categoryId: UUID?
        var note: String
    }

    init(listId: UUID, itemId: UUID?, store: BasketStore, toast: ToastCenter) {
        self.listId = listId
        self.itemId = itemId
        self.store = store
        self.toast = toast
    }

    // MARK: - Loading

    func load(locale: Locale) {
        guard !hasLoaded else { return }
        hasLoaded = true
        listItems = store.list(id: listId)?.items ?? []

        if let itemId = itemId, let item = store.item(id: itemId) {
            name = item.name
            quantity = item.quantity
            if let cents = item.priceCents {
                priceText = BasketRules.formatPriceInput(cents, locale: locale)
            } else {
                priceText = ""
            }
            categoryId = item.categoryId ?? store.otherCategory?.id
            note = item.note
        } else {
            categoryId = store.otherCategory?.id
        }
        initialFields = currentFields
    }

    private var currentFields: Fields {
        Fields(name: name, quantity: quantity, priceText: priceText, categoryId: categoryId, note: note)
    }

    var hasChanges: Bool {
        currentFields != initialFields
    }

    var listName: String {
        store.list(id: listId)?.name ?? ""
    }

    // MARK: - Field rules

    func nameChanged(_ newValue: String) {
        if newValue.count > BasketRules.maxItemNameLength {
            name = String(newValue.prefix(BasketRules.maxItemNameLength))
            return
        }
        if !newValue.isEmpty {
            isNameTouched = true
        }
    }

    func noteChanged(_ newValue: String) {
        if newValue.count > BasketRules.maxNoteLength {
            note = String(newValue.prefix(BasketRules.maxNoteLength))
        }
    }

    var showsNameError: Bool {
        isNameTouched && BasketRules.trimmedName(name) == nil
    }

    var priceInput: BasketRules.PriceInput {
        let cleaned = priceText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return .empty }
        guard let value = Double(cleaned), value >= 0.01, value <= 9_999.99 else { return .invalid }
        if let dot = cleaned.firstIndex(of: "."), cleaned.distance(from: dot, to: cleaned.endIndex) > 3 { return .invalid }
        return .valid(cents: Int((value * 100).rounded()))
    }

    var showsPriceError: Bool {
        priceInput == .invalid
    }

    var canSave: Bool {
        BasketRules.trimmedName(name) != nil && priceInput != .invalid
    }

    func lineTotalText(locale: Locale) -> String? {
        guard case .valid(let cents) = priceInput else { return nil }
        let total = BasketRules.lineTotalCents(unitCents: cents, quantity: quantity) ?? 0
        return L10n.format("form.lineTotal", locale,
                           quantity,
                           BasketRules.formatMoney(cents, locale: locale),
                           BasketRules.formatMoney(total, locale: locale))
    }

    // MARK: - Suggestions

    func suggestions() -> [Suggestion] {
        let query = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        var seen = Set<String>()
        var results: [Suggestion] = []

        func consider(_ candidate: String, product: CatalogProduct?) {
            guard results.count < ItemFormViewModel.maxSuggestions else { return }
            guard candidate.range(of: query, options: options) != nil else { return }
            guard candidate.compare(query, options: options) != .orderedSame else { return }
            let key = candidate.folding(options: options, locale: nil)
            guard seen.insert(key).inserted else { return }
            results.append(Suggestion(name: candidate, product: product))
        }

        for item in BasketRules.sortedItems(listItems) {
            consider(item.name, product: nil)
        }
        for product in BasketRules.sortedProducts(CatalogMemoryCache.shared.products) {
            consider(product.title, product: product)
        }
        return results
    }

    func applySuggestion(_ suggestion: Suggestion) {
        name = suggestion.name
        if let product = suggestion.product {
            categoryId = store.category(for: product.defaultCategory)?.id ?? store.otherCategory?.id
        }
    }

    // MARK: - Saving

    func save(locale: Locale, onFinished: @escaping () -> Void) {
        guard let trimmed = BasketRules.trimmedName(name) else { return }
        if !isEditing, let match = BasketRules.findDuplicate(in: listItems, name: trimmed, catalogProductId: nil) {
            duplicate = match
            return
        }
        isSaving = true
        let priceCents: Int?
        if case .valid(let cents) = priceInput {
            priceCents = cents
        } else {
            priceCents = nil
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let draft = ItemDraft(name: trimmed, quantity: quantity, priceCents: priceCents, categoryId: categoryId, note: trimmedNote)
        store.addItem(draft, to: listId)
        toast.show(isEditing ? L10n.tr("form.saved", locale) : L10n.format("form.added", locale, trimmed))
        // Let the saving state render before leaving the screen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isSaving = false
            onFinished()
        }
    }

    func addMore(to existing: ListItem, locale: Locale, onFinished: @escaping () -> Void) {
        duplicate = nil
        isSaving = true
        store.setQuantity(itemId: existing.id, BasketRules.mergedQuantity(existing: existing.quantity, adding: quantity))
        toast.show(L10n.format("form.updated", locale, existing.name))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isSaving = false
            onFinished()
        }
    }
}
