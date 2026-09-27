import CoreData

/// Owns the Core Data stack. The managed object model is defined in code and shared by every container.
final class PersistenceController {
    static let shared = PersistenceController()
    static let model: NSManagedObjectModel = makeModel()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Basket", managedObjectModel: PersistenceController.model)
        if inMemory, let description = container.persistentStoreDescriptions.first {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Model

    private static func makeModel() -> NSManagedObjectModel {
        let listEntity = NSEntityDescription()
        listEntity.name = ShoppingListMO.entityName
        listEntity.managedObjectClassName = "ShoppingListMO"

        let itemEntity = NSEntityDescription()
        itemEntity.name = ItemMO.entityName
        itemEntity.managedObjectClassName = "ItemMO"

        let categoryEntity = NSEntityDescription()
        categoryEntity.name = CategoryMO.entityName
        categoryEntity.managedObjectClassName = "CategoryMO"

        let cacheEntity = NSEntityDescription()
        cacheEntity.name = CatalogCacheMO.entityName
        cacheEntity.managedObjectClassName = "CatalogCacheMO"

        // ShoppingList <->> Item
        let listItems = relationship("items", to: itemEntity, toMany: true, deleteRule: .cascadeDeleteRule)
        let itemList = relationship("list", to: listEntity, toMany: false, deleteRule: .nullifyDeleteRule)
        listItems.inverseRelationship = itemList
        itemList.inverseRelationship = listItems

        // Category <->> Item
        let categoryItems = relationship("items", to: itemEntity, toMany: true, deleteRule: .cascadeDeleteRule)
        let itemCategory = relationship("category", to: categoryEntity, toMany: false, deleteRule: .nullifyDeleteRule)
        categoryItems.inverseRelationship = itemCategory
        itemCategory.inverseRelationship = categoryItems

        listEntity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType),
            listItems
        ]

        itemEntity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            attribute("quantity", .integer32AttributeType, defaultValue: 1),
            attribute("priceCents", .integer64AttributeType, optional: true),
            attribute("catalogProductId", .integer64AttributeType, optional: true),
            attribute("note", .stringAttributeType, defaultValue: ""),
            attribute("isTicked", .booleanAttributeType, defaultValue: false),
            attribute("createdAt", .dateAttributeType),
            itemList,
            itemCategory
        ]

        categoryEntity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            attribute("position", .integer32AttributeType, defaultValue: 0),
            attribute("defaultKey", .stringAttributeType, optional: true),
            attribute("isOther", .booleanAttributeType, defaultValue: false),
            categoryItems
        ]

        cacheEntity.properties = [
            attribute("json", .binaryDataAttributeType, optional: true),
            attribute("lastUpdated", .dateAttributeType, optional: true)
        ]

        let model = NSManagedObjectModel()
        model.entities = [listEntity, itemEntity, categoryEntity, cacheEntity]
        return model
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let result = NSAttributeDescription()
        result.name = name
        result.attributeType = type
        result.isOptional = optional
        result.defaultValue = defaultValue
        return result
    }

    private static func relationship(
        _ name: String,
        to destination: NSEntityDescription,
        toMany: Bool,
        deleteRule: NSDeleteRule
    ) -> NSRelationshipDescription {
        let result = NSRelationshipDescription()
        result.name = name
        result.destinationEntity = destination
        result.minCount = 0
        result.maxCount = toMany ? 0 : 1
        result.deleteRule = deleteRule
        result.isOptional = true
        return result
    }
}
