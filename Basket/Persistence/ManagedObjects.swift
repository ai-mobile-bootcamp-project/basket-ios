import CoreData

// MARK: - ShoppingList

@objc(ShoppingListMO)
final class ShoppingListMO: NSManagedObject {
    static let entityName = "ShoppingList"

    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var items: NSSet?

    static func request() -> NSFetchRequest<ShoppingListMO> {
        NSFetchRequest<ShoppingListMO>(entityName: entityName)
    }

    static func insert(into context: NSManagedObjectContext) -> ShoppingListMO {
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        return ShoppingListMO(entity: entity, insertInto: context)
    }

    var itemObjects: [ItemMO] {
        Array((items as? Set<ItemMO>) ?? [])
    }

    func toModel() -> ShoppingList {
        let listId = id ?? UUID()
        let mappedItems = itemObjects
            .map { $0.toModel(listId: listId) }
            .sorted { $0.createdAt < $1.createdAt }
        return ShoppingList(
            id: listId,
            name: name ?? "",
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            items: mappedItems
        )
    }
}

// MARK: - Item

@objc(ItemMO)
final class ItemMO: NSManagedObject {
    static let entityName = "Item"

    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var quantity: Int32
    @NSManaged var priceCents: NSNumber?
    @NSManaged var catalogProductId: NSNumber?
    @NSManaged var note: String?
    @NSManaged var isTicked: Bool
    @NSManaged var createdAt: Date?
    @NSManaged var list: ShoppingListMO?
    @NSManaged var category: CategoryMO?

    static func request() -> NSFetchRequest<ItemMO> {
        NSFetchRequest<ItemMO>(entityName: entityName)
    }

    static func insert(into context: NSManagedObjectContext) -> ItemMO {
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        return ItemMO(entity: entity, insertInto: context)
    }

    func toModel() -> ListItem {
        toModel(listId: list?.id ?? UUID())
    }

    func toModel(listId: UUID) -> ListItem {
        ListItem(
            id: id ?? UUID(),
            listId: listId,
            name: name ?? "",
            quantity: Int(quantity),
            priceCents: priceCents?.intValue,
            catalogProductId: catalogProductId?.intValue,
            note: note ?? "",
            isTicked: isTicked,
            categoryId: category?.id,
            createdAt: createdAt ?? Date()
        )
    }
}

// MARK: - Category

@objc(CategoryMO)
final class CategoryMO: NSManagedObject {
    static let entityName = "Category"

    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var position: Int32
    @NSManaged var defaultKey: String?
    @NSManaged var isOther: Bool
    @NSManaged var items: NSSet?

    static func request() -> NSFetchRequest<CategoryMO> {
        NSFetchRequest<CategoryMO>(entityName: entityName)
    }

    static func insert(into context: NSManagedObjectContext) -> CategoryMO {
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        return CategoryMO(entity: entity, insertInto: context)
    }

    func toModel() -> ItemCategory {
        ItemCategory(
            id: id ?? UUID(),
            name: name ?? "",
            position: Int(position),
            defaultKey: defaultKey.flatMap { DefaultCategory(rawValue: $0) },
            isOther: isOther
        )
    }
}

// MARK: - CatalogCache

@objc(CatalogCacheMO)
final class CatalogCacheMO: NSManagedObject {
    static let entityName = "CatalogCache"

    @NSManaged var json: Data?
    @NSManaged var lastUpdated: Date?

    static func request() -> NSFetchRequest<CatalogCacheMO> {
        NSFetchRequest<CatalogCacheMO>(entityName: entityName)
    }
}
