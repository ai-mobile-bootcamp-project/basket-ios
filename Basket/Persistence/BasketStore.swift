import Foundation
import CoreData
import Combine

/// App-wide store for lists, items and categories. Keeps an in-memory copy of the Core Data contents
/// as value types and refreshes it after every change.
@MainActor
final class BasketStore: ObservableObject {
    static let shared = BasketStore(persistence: .shared)

    @Published private(set) var lists: [ShoppingList] = []
    @Published private(set) var categories: [ItemCategory] = []

    private let persistence: PersistenceController

    private var context: NSManagedObjectContext {
        persistence.container.viewContext
    }

    init(persistence: PersistenceController) {
        self.persistence = persistence
        reload()
    }

    // MARK: - Queries

    func list(id: UUID) -> ShoppingList? {
        lists.first { $0.id == id }
    }

    func item(id: UUID) -> ListItem? {
        for shoppingList in lists {
            if let match = shoppingList.items.first(where: { $0.id == id }) {
                return match
            }
        }
        return nil
    }

    var otherCategory: ItemCategory? {
        categories.first { $0.isOther }
    }

    func category(for key: DefaultCategory) -> ItemCategory? {
        categories.first { $0.defaultKey == key }
    }

    func itemCount(categoryId: UUID) -> Int {
        var count = 0
        for shoppingList in lists {
            count += shoppingList.items.filter { $0.categoryId == categoryId }.count
        }
        return count
    }

    // MARK: - Lists

    @discardableResult
    func createList(name: String) -> UUID {
        let now = Date()
        let id = UUID()
        let object = ShoppingListMO.insert(into: context)
        object.id = id
        object.name = name
        object.createdAt = now
        object.updatedAt = now
        commit()
        return id
    }

    func renameList(id: UUID, name: String) {
        guard let object = fetchList(id) else { return }
        object.name = name
        object.updatedAt = Date()
        commit()
    }

    @discardableResult
    func duplicateList(id: UUID, name: String) -> UUID? {
        guard let source = fetchList(id) else { return nil }
        let now = Date()
        let newId = UUID()
        let copy = ShoppingListMO.insert(into: context)
        copy.id = newId
        copy.name = name
        copy.createdAt = now
        copy.updatedAt = now

        let sourceItems = source.itemObjects.sorted {
            ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
        }
        let count = sourceItems.count
        for (index, original) in sourceItems.enumerated() {
            let item = ItemMO.insert(into: context)
            item.id = UUID()
            item.name = original.name
            item.quantity = original.quantity
            item.priceCents = original.priceCents
            item.catalogProductId = original.catalogProductId
            item.note = original.note
            item.isTicked = false
            item.createdAt = now.addingTimeInterval(-0.001 * Double(count - index))
            item.category = original.category
            item.list = copy
        }
        commit()
        return newId
    }

    func deleteList(id: UUID) {
        guard let object = fetchList(id) else { return }
        context.delete(object)
        commit()
    }

    // MARK: - Items

    @discardableResult
    func addItem(_ draft: ItemDraft, to listId: UUID) -> UUID {
        let id = UUID()
        guard let listObject = fetchList(listId) else { return id }
        let now = Date()
        let object = ItemMO.insert(into: context)
        object.id = id
        object.name = draft.name
        object.quantity = Int32(clamping: draft.quantity)
        object.priceCents = draft.priceCents.map { NSNumber(value: $0) }
        object.catalogProductId = draft.catalogProductId.map { NSNumber(value: $0) }
        object.note = draft.note
        object.isTicked = draft.isTicked
        object.createdAt = now
        object.category = categoryObject(for: draft.categoryId)
        object.list = listObject
        listObject.updatedAt = now
        commit()
        return id
    }

    @discardableResult
    func deleteItem(id: UUID) -> ListItem? {
        guard let object = fetchItem(id) else { return nil }
        let snapshot = object.toModel()
        object.list?.updatedAt = Date()
        context.delete(object)
        commit()
        return snapshot
    }

    func restoreItem(_ item: ListItem) {
        guard let listObject = fetchList(item.listId), fetchItem(item.id) == nil else { return }
        let object = ItemMO.insert(into: context)
        object.id = item.id
        object.name = item.name
        object.quantity = Int32(clamping: item.quantity)
        object.priceCents = item.priceCents.map { NSNumber(value: $0) }
        object.catalogProductId = item.catalogProductId.map { NSNumber(value: $0) }
        object.note = item.note
        object.isTicked = item.isTicked
        object.createdAt = item.createdAt
        object.category = categoryObject(for: item.categoryId)
        object.list = listObject
        listObject.updatedAt = Date()
        commit()
    }

    /// Restores several removed items at once; items that still exist or whose list is gone are skipped.
    func restoreItems(_ items: [ListItem]) {
        let now = Date()
        var restoredAny = false
        for item in items {
            guard let listObject = fetchList(item.listId), fetchItem(item.id) == nil else { continue }
            let object = ItemMO.insert(into: context)
            object.id = item.id
            object.name = item.name
            object.quantity = Int32(clamping: item.quantity)
            object.priceCents = item.priceCents.map { NSNumber(value: $0) }
            object.catalogProductId = item.catalogProductId.map { NSNumber(value: $0) }
            object.note = item.note
            object.isTicked = item.isTicked
            object.createdAt = item.createdAt
            object.category = categoryObject(for: item.categoryId)
            object.list = listObject
            listObject.updatedAt = now
            restoredAny = true
        }
        guard restoredAny else { return }
        commit()
    }

    func setTicked(itemId: UUID, _ isTicked: Bool) {
        guard let object = fetchItem(itemId) else { return }
        object.isTicked = isTicked
        object.list?.updatedAt = Date()
        commit()
    }

    func setQuantity(itemId: UUID, _ quantity: Int) {
        guard let object = fetchItem(itemId) else { return }
        object.quantity = Int32(clamping: quantity)
        object.list?.updatedAt = Date()
        commit()
    }

    func removeTickedItems(listId: UUID) {
        guard let listObject = fetchList(listId) else { return }
        for object in listObject.itemObjects where object.isTicked {
            context.delete(object)
        }
        listObject.updatedAt = Date()
        commit()
    }

    func removeAllItems(listId: UUID) {
        guard let listObject = fetchList(listId) else { return }
        for object in listObject.itemObjects {
            context.delete(object)
        }
        listObject.updatedAt = Date()
        commit()
    }

    // MARK: - Categories

    @discardableResult
    func addCategory(name: String) -> UUID {
        var movable = movableCategoryObjects()
        let id = UUID()
        let object = CategoryMO.insert(into: context)
        object.id = id
        object.name = name
        object.defaultKey = nil
        object.isOther = false
        movable.append(object)
        renumber(movable)
        commit()
        return id
    }

    func renameCategory(id: UUID, name: String) {
        guard let object = fetchCategory(id), !object.isOther else { return }
        object.name = name
        commit()
    }

    @discardableResult
    func deleteCategory(id: UUID) -> ItemCategory? {
        guard let object = fetchCategory(id), !object.isOther else { return nil }
        let snapshot = object.toModel()
        let remaining = movableCategoryObjects().filter { $0.objectID != object.objectID }
        context.delete(object)
        renumber(remaining)
        commit()
        return snapshot
    }

    func restoreCategory(_ category: ItemCategory) {
        guard fetchCategory(category.id) == nil else { return }
        var movable = movableCategoryObjects()
        let object = CategoryMO.insert(into: context)
        object.id = category.id
        object.name = category.name
        object.defaultKey = category.defaultKey?.rawValue
        object.isOther = false
        let index = min(max(category.position, 0), movable.count)
        movable.insert(object, at: index)
        renumber(movable)
        commit()
    }

    func moveCategories(fromOffsets source: IndexSet, toOffset destination: Int) {
        var movable = movableCategoryObjects()
        let offsets = Array(source).filter { $0 >= 0 && $0 < movable.count }
        guard !offsets.isEmpty else { return }
        let moving = offsets.map { movable[$0] }
        let insertionIndex = destination - offsets.filter { $0 < destination }.count
        for offset in offsets.sorted(by: >) {
            movable.remove(at: offset)
        }
        let target = min(max(insertionIndex, 0), movable.count)
        movable.insert(contentsOf: moving, at: target)
        renumber(movable)
        commit()
    }

    func moveCategory(id: UUID, by delta: Int) {
        var movable = movableCategoryObjects()
        guard let index = movable.firstIndex(where: { $0.id == id }) else { return }
        let target = index + delta
        guard delta != 0, target >= 0, target < movable.count else { return }
        let object = movable.remove(at: index)
        movable.insert(object, at: target)
        renumber(movable)
        commit()
    }

    // MARK: - Sample data

    /// Inserts the default categories when there are none yet.
    func seedDefaultCategoriesIfNeeded() {
        guard categoryObjectCount() == 0 else { return }
        SampleSeeder.seedCategories(into: context, locale: AppSettings.shared.locale)
        commit()
    }

    /// Adds the sample lists; their items use the existing default categories.
    func seedSampleLists() {
        let locale = AppSettings.shared.locale
        if categoryObjectCount() == 0 {
            SampleSeeder.seedCategories(into: context, locale: locale)
            save()
        }
        SampleSeeder.seedLists(into: context, locale: locale)
        commit()
    }

    func resetSampleData() {
        for object in (try? context.fetch(ItemMO.request())) ?? [] {
            context.delete(object)
        }
        for object in (try? context.fetch(ShoppingListMO.request())) ?? [] {
            context.delete(object)
        }
        for object in (try? context.fetch(CategoryMO.request())) ?? [] {
            context.delete(object)
        }
        save()
        let locale = AppSettings.shared.locale
        SampleSeeder.seedCategories(into: context, locale: locale)
        save()
        SampleSeeder.seedLists(into: context, locale: locale)
        commit()
    }

    // MARK: - Persistence helpers

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    private func commit() {
        save()
        reload()
    }

    private func reload() {
        let listObjects = (try? context.fetch(ShoppingListMO.request())) ?? []
        lists = BasketRules.sortedLists(listObjects.map { $0.toModel() })
        let categoryObjects = (try? context.fetch(CategoryMO.request())) ?? []
        categories = BasketRules.orderedCategories(categoryObjects.map { $0.toModel() })
    }

    private func categoryObjectCount() -> Int {
        (try? context.count(for: CategoryMO.request())) ?? 0
    }

    private func fetchList(_ id: UUID) -> ShoppingListMO? {
        let request = ShoppingListMO.request()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func fetchItem(_ id: UUID) -> ItemMO? {
        let request = ItemMO.request()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func fetchCategory(_ id: UUID) -> CategoryMO? {
        let request = CategoryMO.request()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func fetchOtherCategory() -> CategoryMO? {
        let request = CategoryMO.request()
        request.predicate = NSPredicate(format: "isOther == YES")
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    /// The category with `id`, or Other when `id` is nil or unknown.
    private func categoryObject(for id: UUID?) -> CategoryMO? {
        if let id = id, let match = fetchCategory(id) {
            return match
        }
        return fetchOtherCategory()
    }

    /// Non-Other categories in aisle order.
    private func movableCategoryObjects() -> [CategoryMO] {
        let request = CategoryMO.request()
        request.predicate = NSPredicate(format: "isOther == NO")
        request.sortDescriptors = [
            NSSortDescriptor(key: "position", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        return (try? context.fetch(request)) ?? []
    }

    /// Positions 0…n-1 for `movable` in the given order, Other last.
    private func renumber(_ movable: [CategoryMO]) {
        for (index, object) in movable.enumerated() {
            object.position = Int32(index)
        }
        let request = CategoryMO.request()
        request.predicate = NSPredicate(format: "isOther == YES")
        for other in (try? context.fetch(request)) ?? [] {
            other.position = Int32(movable.count)
        }
    }
}
