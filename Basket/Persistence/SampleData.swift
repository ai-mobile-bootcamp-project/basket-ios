import Foundation
import CoreData

/// Contents of the bundled `sample-data.json`: default categories and the sample lists.
struct SampleData: Decodable {
    struct CategoryEntry: Decodable {
        let key: String
        let nameKey: String?
        let name: String
        let isOther: Bool?
    }

    struct ItemEntry: Decodable {
        let nameKey: String?
        let name: String
        let category: String?
        let quantity: Int?
        let priceCents: Int?
        let catalogProductId: Int?
        let ticked: Bool?
        let noteKey: String?
        let note: String?
    }

    struct ListEntry: Decodable {
        let nameKey: String?
        let name: String
        let items: [ItemEntry]?
    }

    let categories: [CategoryEntry]
    let lists: [ListEntry]

    static func load(bundle: Bundle = .main) -> SampleData? {
        guard let url = bundle.url(forResource: "sample-data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(SampleData.self, from: data)
    }

    /// Default categories built from `DefaultCategory`, used when the bundled file cannot be read.
    static var defaultCategoryEntries: [CategoryEntry] {
        DefaultCategory.allCases.map { key in
            CategoryEntry(
                key: key.rawValue,
                nameKey: "category." + key.rawValue,
                name: key.englishName,
                isOther: key == .other
            )
        }
    }
}

/// Inserts the default categories and sample lists into a context. The caller saves.
@MainActor
enum SampleSeeder {
    static func seed(into context: NSManagedObjectContext, locale: Locale, now: Date = Date()) {
        let sample = SampleData.load()
        var categoryEntries = sample?.categories ?? []
        if categoryEntries.isEmpty {
            categoryEntries = SampleData.defaultCategoryEntries
        }

        var categoriesByKey: [String: CategoryMO] = [:]
        var otherCategory: CategoryMO?
        for (index, entry) in categoryEntries.enumerated() {
            let category = CategoryMO.insert(into: context)
            category.id = UUID()
            category.name = localized(entry.nameKey, fallback: entry.name, locale: locale)
            category.position = Int32(index)
            category.defaultKey = entry.key
            category.isOther = entry.isOther ?? false
            categoriesByKey[entry.key] = category
            if category.isOther {
                otherCategory = category
            }
        }
        if otherCategory == nil {
            otherCategory = categoriesByKey[DefaultCategory.other.rawValue]
        }

        let baseDate = now.addingTimeInterval(-24 * 60 * 60)
        for (listIndex, listEntry) in (sample?.lists ?? []).enumerated() {
            let list = ShoppingListMO.insert(into: context)
            list.id = UUID()
            list.name = localized(listEntry.nameKey, fallback: listEntry.name, locale: locale)
            list.createdAt = baseDate
            list.updatedAt = now.addingTimeInterval(-60 * Double(listIndex))

            for (itemIndex, itemEntry) in (listEntry.items ?? []).enumerated() {
                let item = ItemMO.insert(into: context)
                item.id = UUID()
                item.name = localized(itemEntry.nameKey, fallback: itemEntry.name, locale: locale)
                item.quantity = Int32(BasketRules.clampQuantity(itemEntry.quantity ?? 1))
                item.priceCents = itemEntry.priceCents.map { NSNumber(value: $0) }
                item.catalogProductId = itemEntry.catalogProductId.map { NSNumber(value: $0) }
                item.note = localized(itemEntry.noteKey, fallback: itemEntry.note ?? "", locale: locale)
                item.isTicked = itemEntry.ticked ?? false
                item.createdAt = baseDate.addingTimeInterval(Double(itemIndex))
                item.category = itemEntry.category.flatMap { categoriesByKey[$0] } ?? otherCategory
                item.list = list
            }
        }
    }

    private static func localized(_ key: String?, fallback: String, locale: Locale) -> String {
        guard let key = key, !key.isEmpty else { return fallback }
        let value = L10n.tr(key, locale)
        return (value == key || value.isEmpty) ? fallback : value
    }
}
