import Foundation

// MARK: - Categories

public enum DefaultCategory: String, CaseIterable, Codable, Hashable {
    case fruitVeg
    case bakery
    case dairyEggs
    case meatFish
    case pantry
    case frozen
    case drinks
    case householdPets
    case other

    /// English name used for seeding and as a non-localized fallback.
    public var englishName: String {
        switch self {
        case .fruitVeg: return "Fruit & veg"
        case .bakery: return "Bakery"
        case .dairyEggs: return "Dairy & eggs"
        case .meatFish: return "Meat & fish"
        case .pantry: return "Pantry"
        case .frozen: return "Frozen"
        case .drinks: return "Drinks"
        case .householdPets: return "Household & pets"
        case .other: return "Other"
        }
    }

    /// Category chips shown on Browse products, after "All".
    public static let browseChips: [DefaultCategory] = [
        .fruitVeg, .dairyEggs, .meatFish, .pantry, .frozen, .drinks, .householdPets
    ]
}

public struct ItemCategory: Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var position: Int
    public var defaultKey: DefaultCategory?
    public var isOther: Bool

    public init(id: UUID = UUID(), name: String, position: Int, defaultKey: DefaultCategory? = nil, isOther: Bool = false) {
        self.id = id
        self.name = name
        self.position = position
        self.defaultKey = defaultKey
        self.isOther = isOther
    }
}

// MARK: - Lists and items

public struct ListItem: Identifiable, Hashable {
    public var id: UUID
    public var listId: UUID
    public var name: String
    public var quantity: Int
    /// Unit price in cents; nil when the item has no price.
    public var priceCents: Int?
    /// Catalog product id when the item was added from Browse.
    public var catalogProductId: Int?
    /// Empty when there is no note.
    public var note: String
    public var isTicked: Bool
    /// nil means the item belongs to Other.
    public var categoryId: UUID?
    /// Insertion order.
    public var createdAt: Date

    public init(id: UUID = UUID(), listId: UUID, name: String, quantity: Int = 1, priceCents: Int? = nil,
                catalogProductId: Int? = nil, note: String = "", isTicked: Bool = false,
                categoryId: UUID? = nil, createdAt: Date = Date()) {
        self.id = id
        self.listId = listId
        self.name = name
        self.quantity = quantity
        self.priceCents = priceCents
        self.catalogProductId = catalogProductId
        self.note = note
        self.isTicked = isTicked
        self.categoryId = categoryId
        self.createdAt = createdAt
    }
}

public struct ShoppingList: Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date
    /// Insertion order (createdAt ascending), not display order.
    public var items: [ListItem]

    public init(id: UUID = UUID(), name: String, createdAt: Date = Date(), updatedAt: Date = Date(), items: [ListItem] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }
}

public struct ItemDraft: Hashable {
    public var name: String
    public var quantity: Int
    public var priceCents: Int?
    public var categoryId: UUID?
    public var note: String
    public var catalogProductId: Int?
    public var isTicked: Bool

    public init(name: String, quantity: Int = 1, priceCents: Int? = nil, categoryId: UUID? = nil,
                note: String = "", catalogProductId: Int? = nil, isTicked: Bool = false) {
        self.name = name
        self.quantity = quantity
        self.priceCents = priceCents
        self.categoryId = categoryId
        self.note = note
        self.catalogProductId = catalogProductId
        self.isTicked = isTicked
    }
}

// MARK: - Catalog

public enum Availability: Hashable {
    case inStock
    case lowStock
    case outOfStock

    /// Maps the exact DummyJSON `availabilityStatus` values; anything else counts as in stock.
    public init(apiValue: String) {
        switch apiValue {
        case "In Stock":
            self = .inStock
        case "Low Stock":
            self = .lowStock
        case "Out of Stock":
            self = .outOfStock
        default:
            self = .inStock
        }
    }
}

public struct CatalogProduct: Identifiable, Hashable, Codable {
    public let id: Int
    public let title: String
    public let description: String
    /// Original price in dollars.
    public let price: Double
    public let discountPercentage: Double
    public let rating: Double
    /// Raw API value, e.g. "In Stock".
    public let availabilityStatus: String
    public let tags: [String]
    public let thumbnail: String
    public let images: [String]
    public let stock: Int?
    public let minimumOrderQuantity: Int?

    public init(id: Int, title: String, description: String, price: Double, discountPercentage: Double,
                rating: Double, availabilityStatus: String, tags: [String], thumbnail: String,
                images: [String], stock: Int?, minimumOrderQuantity: Int?) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.discountPercentage = discountPercentage
        self.rating = rating
        self.availabilityStatus = availabilityStatus
        self.tags = tags
        self.thumbnail = thumbnail
        self.images = images
        self.stock = stock
        self.minimumOrderQuantity = minimumOrderQuantity
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case descriptionText = "description"
        case price
        case discountPercentage
        case rating
        case availabilityStatus
        case tags
        case thumbnail
        case images
        case stock
        case minimumOrderQuantity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .descriptionText) ?? ""
        self.price = try container.decode(Double.self, forKey: .price)
        self.discountPercentage = try container.decodeIfPresent(Double.self, forKey: .discountPercentage) ?? 0
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        self.availabilityStatus = try container.decodeIfPresent(String.self, forKey: .availabilityStatus) ?? "In Stock"
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail) ?? ""
        self.images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        self.stock = try container.decodeIfPresent(Int.self, forKey: .stock)
        self.minimumOrderQuantity = try container.decodeIfPresent(Int.self, forKey: .minimumOrderQuantity)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .descriptionText)
        try container.encode(price, forKey: .price)
        try container.encode(discountPercentage, forKey: .discountPercentage)
        try container.encode(rating, forKey: .rating)
        try container.encode(availabilityStatus, forKey: .availabilityStatus)
        try container.encode(tags, forKey: .tags)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encode(images, forKey: .images)
        try container.encodeIfPresent(stock, forKey: .stock)
        try container.encodeIfPresent(minimumOrderQuantity, forKey: .minimumOrderQuantity)
    }

    public var availability: Availability {
        Availability(apiValue: availabilityStatus)
    }

    public var thumbnailURL: URL? {
        guard !thumbnail.isEmpty else { return nil }
        return URL(string: thumbnail)
    }

    /// First product image, else the thumbnail.
    public var imageURL: URL? {
        if let first = images.first, !first.isEmpty, let url = URL(string: first) {
            return url
        }
        return thumbnailURL
    }

    public var defaultCategory: DefaultCategory {
        BasketRules.category(forTags: tags)
    }
}

public struct CatalogResponse: Codable {
    public let products: [CatalogProduct]
    public let total: Int
    public let skip: Int
    public let limit: Int
}
