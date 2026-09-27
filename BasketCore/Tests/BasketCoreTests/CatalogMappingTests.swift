import XCTest
#if SWIFT_PACKAGE
@testable import BasketCore
#else
@testable import Basket
#endif

/// Anchor class used to locate the test bundle when the tests run inside the app's test target.
final class FixtureToken {}

/// Saved response of `GET https://dummyjson.com/products/category/groceries?limit=0`.
enum GroceriesFixture {
    static func loadResponse() throws -> CatalogResponse {
        #if SWIFT_PACKAGE
        let url = Bundle.module.url(forResource: "groceries", withExtension: "json")
        #else
        let url = Bundle(for: FixtureToken.self).url(forResource: "groceries", withExtension: "json")
        #endif
        let fileURL = try XCTUnwrap(url, "groceries.json is not in the test bundle")
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(CatalogResponse.self, from: data)
    }

    static func loadProducts() throws -> [CatalogProduct] {
        try loadResponse().products
    }
}

final class CatalogMappingTests: XCTestCase {
    /// "Pay" column of the brief's catalog table, in cents.
    private let expectedPay: [String: Int] = [
        "Apple": 174,
        "Beef Steak": 1174,
        "Cat Food": 813,
        "Chicken Meat": 862,
        "Cooking Oil": 452,
        "Cucumber": 149,
        "Dog Food": 986,
        "Eggs": 266,
        "Fish Steak": 1436,
        "Green Bell Pepper": 129,
        "Green Chili Pepper": 98,
        "Honey Jar": 598,
        "Ice Cream": 501,
        "Juice": 351,
        "Kiwi": 211,
        "Lemon": 71,
        "Milk": 301,
        "Mulberry": 435,
        "Nescafe Coffee": 786,
        "Potatoes": 217,
        "Protein Powder": 1847,
        "Red Onions": 179,
        "Rice": 543,
        "Soft Drinks": 164,
        "Strawberry": 395,
        "Tissue Paper Box": 216,
        "Water": 84
    ]

    /// "Price" column of the brief's catalog table, in cents.
    private let expectedPrice: [String: Int] = [
        "Apple": 199,
        "Beef Steak": 1299,
        "Cat Food": 899,
        "Chicken Meat": 999,
        "Cooking Oil": 499,
        "Cucumber": 149,
        "Dog Food": 1099,
        "Eggs": 299,
        "Fish Steak": 1499,
        "Green Bell Pepper": 129,
        "Green Chili Pepper": 99,
        "Honey Jar": 699,
        "Ice Cream": 549,
        "Juice": 399,
        "Kiwi": 249,
        "Lemon": 79,
        "Milk": 349,
        "Mulberry": 499,
        "Nescafe Coffee": 799,
        "Potatoes": 229,
        "Protein Powder": 1999,
        "Red Onions": 199,
        "Rice": 599,
        "Soft Drinks": 199,
        "Strawberry": 399,
        "Tissue Paper Box": 249,
        "Water": 99
    ]

    /// "Badge" column of the brief's catalog table; 0 means no badge.
    private let expectedBadge: [String: Int] = [
        "Apple": 13,
        "Beef Steak": 10,
        "Cat Food": 10,
        "Chicken Meat": 14,
        "Cooking Oil": 9,
        "Cucumber": 0,
        "Dog Food": 10,
        "Eggs": 11,
        "Fish Steak": 4,
        "Green Bell Pepper": 0,
        "Green Chili Pepper": 1,
        "Honey Jar": 14,
        "Ice Cream": 9,
        "Juice": 12,
        "Kiwi": 15,
        "Lemon": 10,
        "Milk": 14,
        "Mulberry": 13,
        "Nescafe Coffee": 2,
        "Potatoes": 5,
        "Protein Powder": 8,
        "Red Onions": 10,
        "Rice": 9,
        "Soft Drinks": 17,
        "Strawberry": 1,
        "Tissue Paper Box": 13,
        "Water": 15
    ]

    /// "Category" column of the brief's catalog table.
    private let expectedCategory: [String: DefaultCategory] = [
        "Apple": .fruitVeg,
        "Kiwi": .fruitVeg,
        "Lemon": .fruitVeg,
        "Mulberry": .fruitVeg,
        "Strawberry": .fruitVeg,
        "Cucumber": .fruitVeg,
        "Green Bell Pepper": .fruitVeg,
        "Green Chili Pepper": .fruitVeg,
        "Potatoes": .fruitVeg,
        "Red Onions": .fruitVeg,
        "Eggs": .dairyEggs,
        "Milk": .dairyEggs,
        "Beef Steak": .meatFish,
        "Chicken Meat": .meatFish,
        "Fish Steak": .meatFish,
        "Cooking Oil": .pantry,
        "Honey Jar": .pantry,
        "Rice": .pantry,
        "Protein Powder": .pantry,
        "Ice Cream": .frozen,
        "Juice": .drinks,
        "Nescafe Coffee": .drinks,
        "Soft Drinks": .drinks,
        "Water": .drinks,
        "Tissue Paper Box": .householdPets,
        "Cat Food": .householdPets,
        "Dog Food": .householdPets
    ]

    private func product(_ title: String, in products: [CatalogProduct]) throws -> CatalogProduct {
        try XCTUnwrap(products.first(where: { $0.title == title }), title)
    }

    // MARK: - Decoding

    func testFixtureDecodes() throws {
        let response = try GroceriesFixture.loadResponse()
        XCTAssertEqual(response.products.count, 27)
        XCTAssertEqual(response.total, 27)
        XCTAssertEqual(response.skip, 0)
        XCTAssertEqual(Set(response.products.map { $0.id }).count, 27)
    }

    func testFixtureProductFields() throws {
        let products = try GroceriesFixture.loadProducts()

        let apple = try product("Apple", in: products)
        XCTAssertEqual(apple.id, 16)
        XCTAssertEqual(apple.price, 1.99, accuracy: 0.000_1)
        XCTAssertEqual(apple.discountPercentage, 12.62, accuracy: 0.000_1)
        XCTAssertEqual(apple.rating, 4.19, accuracy: 0.000_1)
        XCTAssertEqual(apple.minimumOrderQuantity, 7)
        XCTAssertEqual(apple.availabilityStatus, "In Stock")
        XCTAssertEqual(apple.availability, .inStock)
        XCTAssertEqual(apple.tags, ["fruits"])
        XCTAssertFalse(apple.description.isEmpty)
        XCTAssertNotNil(apple.thumbnailURL)
        XCTAssertEqual(apple.imageURL?.absoluteString, apple.images.first)
        XCTAssertEqual(BasketRules.formatRating(apple.rating, locale: Locale(identifier: "en")), "4.2")

        let beefSteak = try product("Beef Steak", in: products)
        XCTAssertEqual(beefSteak.id, 17)
        XCTAssertEqual(beefSteak.minimumOrderQuantity, 43)

        let chiliPepper = try product("Green Chili Pepper", in: products)
        XCTAssertEqual(chiliPepper.availabilityStatus, "Low Stock")
        XCTAssertEqual(chiliPepper.availability, .lowStock)
    }

    func testTolerantDecoding() throws {
        let json = #"{"id": 900, "title": "Mystery Box", "price": 3.5}"#
        let product = try JSONDecoder().decode(CatalogProduct.self, from: Data(json.utf8))
        XCTAssertEqual(product.id, 900)
        XCTAssertEqual(product.title, "Mystery Box")
        XCTAssertEqual(product.price, 3.5, accuracy: 0.000_1)
        XCTAssertEqual(product.description, "")
        XCTAssertEqual(product.discountPercentage, 0, accuracy: 0.000_1)
        XCTAssertEqual(product.rating, 0, accuracy: 0.000_1)
        XCTAssertEqual(product.availabilityStatus, "In Stock")
        XCTAssertEqual(product.availability, .inStock)
        XCTAssertEqual(product.tags, [])
        XCTAssertEqual(product.images, [])
        XCTAssertEqual(product.thumbnail, "")
        XCTAssertNil(product.stock)
        XCTAssertNil(product.minimumOrderQuantity)
        XCTAssertNil(product.thumbnailURL)
        XCTAssertNil(product.imageURL)
        XCTAssertEqual(product.defaultCategory, .other)
        XCTAssertNil(BasketRules.discountBadgePercent(product.discountPercentage))
        XCTAssertEqual(BasketRules.priceYouPayCents(for: product), 350)
    }

    func testDecodingRequiresIdTitleAndPrice() {
        let missingTitle = #"{"id": 1, "price": 2}"#
        let missingPrice = #"{"id": 1, "title": "Salt"}"#
        let missingId = #"{"title": "Salt", "price": 2}"#
        XCTAssertThrowsError(try JSONDecoder().decode(CatalogProduct.self, from: Data(missingTitle.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(CatalogProduct.self, from: Data(missingPrice.utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(CatalogProduct.self, from: Data(missingId.utf8)))
    }

    func testImageURLFallsBackToThumbnail() {
        let product = CatalogProduct(id: 1, title: "Salt", description: "", price: 1, discountPercentage: 0,
                                     rating: 0, availabilityStatus: "In Stock", tags: [],
                                     thumbnail: "https://example.com/salt/thumbnail.webp",
                                     images: [], stock: nil, minimumOrderQuantity: nil)
        XCTAssertEqual(product.imageURL?.absoluteString, "https://example.com/salt/thumbnail.webp")
    }

    func testEncodingRoundTrip() throws {
        let products = try GroceriesFixture.loadProducts()
        let apple = try product("Apple", in: products)
        let data = try JSONEncoder().encode(apple)
        let decoded = try JSONDecoder().decode(CatalogProduct.self, from: data)
        XCTAssertEqual(decoded.id, apple.id)
        XCTAssertEqual(decoded.title, apple.title)
        XCTAssertEqual(decoded.description, apple.description)
        XCTAssertEqual(decoded.tags, apple.tags)
        XCTAssertEqual(decoded.images, apple.images)
        XCTAssertEqual(decoded.thumbnail, apple.thumbnail)
        XCTAssertEqual(decoded.availabilityStatus, apple.availabilityStatus)
        XCTAssertEqual(decoded.stock, apple.stock)
        XCTAssertEqual(decoded.minimumOrderQuantity, 7)
        XCTAssertEqual(decoded.price, apple.price, accuracy: 0.000_1)
        XCTAssertEqual(BasketRules.priceYouPayCents(for: decoded), 174)
    }

    // MARK: - Prices

    func testPriceYouPayForEveryFixtureProduct() throws {
        let products = try GroceriesFixture.loadProducts()
        XCTAssertEqual(Set(products.map { $0.title }), Set(expectedPay.keys))
        for product in products {
            XCTAssertEqual(BasketRules.priceYouPayCents(for: product), expectedPay[product.title], product.title)
        }
    }

    func testOriginalPriceForEveryFixtureProduct() throws {
        let products = try GroceriesFixture.loadProducts()
        XCTAssertEqual(Set(products.map { $0.title }), Set(expectedPrice.keys))
        for product in products {
            XCTAssertEqual(BasketRules.cents(fromDollars: product.price), expectedPrice[product.title], product.title)
        }
    }

    func testDiscountBadgeForEveryFixtureProduct() throws {
        let products = try GroceriesFixture.loadProducts()
        XCTAssertEqual(Set(products.map { $0.title }), Set(expectedBadge.keys))
        for product in products {
            let badge = BasketRules.discountBadgePercent(product.discountPercentage) ?? 0
            XCTAssertEqual(badge, expectedBadge[product.title], product.title)
        }
    }

    // MARK: - Categories

    func testCategoryForEveryFixtureProduct() throws {
        let products = try GroceriesFixture.loadProducts()
        XCTAssertEqual(Set(products.map { $0.title }), Set(expectedCategory.keys))
        for product in products {
            XCTAssertEqual(product.defaultCategory, expectedCategory[product.title], product.title)
            XCTAssertEqual(BasketRules.category(forTags: product.tags), expectedCategory[product.title], product.title)
        }
    }

    func testCategoryForTags() {
        XCTAssertEqual(BasketRules.category(forTags: ["fruits"]), .fruitVeg)
        XCTAssertEqual(BasketRules.category(forTags: ["vegetables"]), .fruitVeg)
        XCTAssertEqual(BasketRules.category(forTags: ["dairy"]), .dairyEggs)
        XCTAssertEqual(BasketRules.category(forTags: ["meat"]), .meatFish)
        XCTAssertEqual(BasketRules.category(forTags: ["seafood"]), .meatFish)
        XCTAssertEqual(BasketRules.category(forTags: ["cooking essentials"]), .pantry)
        XCTAssertEqual(BasketRules.category(forTags: ["condiments"]), .pantry)
        XCTAssertEqual(BasketRules.category(forTags: ["grains"]), .pantry)
        XCTAssertEqual(BasketRules.category(forTags: ["health supplements"]), .pantry)
        XCTAssertEqual(BasketRules.category(forTags: ["desserts"]), .frozen)
        XCTAssertEqual(BasketRules.category(forTags: ["beverages"]), .drinks)
        XCTAssertEqual(BasketRules.category(forTags: ["coffee"]), .drinks)
        XCTAssertEqual(BasketRules.category(forTags: ["household essentials"]), .householdPets)
        XCTAssertEqual(BasketRules.category(forTags: ["pet supplies"]), .householdPets)
        XCTAssertEqual(BasketRules.category(forTags: ["Beverages"]), .drinks)
        XCTAssertEqual(BasketRules.category(forTags: ["cat food", "pet supplies"]), .householdPets)
        XCTAssertEqual(BasketRules.category(forTags: ["coffee", "dairy"]), .drinks)
        XCTAssertEqual(BasketRules.category(forTags: ["snacks"]), .other)
        XCTAssertEqual(BasketRules.category(forTags: []), .other)
    }

    func testDefaultCategoryNamesAndChips() {
        XCTAssertEqual(DefaultCategory.allCases.map { $0.englishName }, [
            "Fruit & veg", "Bakery", "Dairy & eggs", "Meat & fish", "Pantry",
            "Frozen", "Drinks", "Household & pets", "Other"
        ])
        XCTAssertEqual(DefaultCategory.browseChips,
                       [.fruitVeg, .dairyEggs, .meatFish, .pantry, .frozen, .drinks, .householdPets])
    }

    // MARK: - Availability

    func testAvailabilityExactValues() {
        XCTAssertEqual(Availability(apiValue: "In Stock"), .inStock)
        XCTAssertEqual(Availability(apiValue: "Low Stock"), .lowStock)
        XCTAssertEqual(Availability(apiValue: "Out of Stock"), .outOfStock)
        XCTAssertEqual(Availability(apiValue: "Low stock"), .inStock)
        XCTAssertEqual(Availability(apiValue: "out of stock"), .inStock)
        XCTAssertEqual(Availability(apiValue: ""), .inStock)
    }

    // MARK: - Browse ordering and filtering

    func testSortedProductsAToZ() throws {
        let products = try GroceriesFixture.loadProducts()
        let titles = BasketRules.sortedProducts(Array(products.reversed())).map { $0.title }
        XCTAssertEqual(titles.count, 27)
        XCTAssertEqual(titles.first, "Apple")
        XCTAssertEqual(titles.last, "Water")
        XCTAssertEqual(Array(titles.prefix(4)), ["Apple", "Beef Steak", "Cat Food", "Chicken Meat"])
    }

    func testFilterProducts() throws {
        let products = try GroceriesFixture.loadProducts()

        let berries = BasketRules.filterProducts(products, query: "berry", category: .fruitVeg)
        XCTAssertEqual(berries.map { $0.title }, ["Mulberry", "Strawberry"])

        XCTAssertTrue(BasketRules.filterProducts(products, query: "shampoo", category: nil).isEmpty)

        let apples = BasketRules.filterProducts(products, query: "APPLE", category: nil)
        XCTAssertEqual(apples.map { $0.title }, ["Apple"])

        let everything = BasketRules.filterProducts(products, query: "", category: nil)
        XCTAssertEqual(everything.count, 27)
        XCTAssertEqual(everything.first?.title, "Apple")
        XCTAssertEqual(everything.last?.title, "Water")

        let padded = BasketRules.filterProducts(products, query: "  kiwi ", category: nil)
        XCTAssertEqual(padded.map { $0.title }, ["Kiwi"])

        let drinks = BasketRules.filterProducts(products, query: "", category: .drinks)
        XCTAssertEqual(drinks.map { $0.title }, ["Juice", "Nescafe Coffee", "Soft Drinks", "Water"])

        let pets = BasketRules.filterProducts(products, query: "", category: .householdPets)
        XCTAssertEqual(pets.map { $0.title }, ["Cat Food", "Dog Food", "Tissue Paper Box"])

        let bakery = BasketRules.filterProducts(products, query: "", category: .bakery)
        XCTAssertTrue(bakery.isEmpty)

        let nothingInDairy = BasketRules.filterProducts(products, query: "berry", category: .dairyEggs)
        XCTAssertTrue(nothingInDairy.isEmpty)
    }

    func testFilterIgnoresAccents() {
        let cafe = CatalogProduct(id: 500, title: "Café Latte", description: "", price: 3, discountPercentage: 0,
                                  rating: 4, availabilityStatus: "In Stock", tags: ["coffee"], thumbnail: "",
                                  images: [], stock: nil, minimumOrderQuantity: nil)
        let result = BasketRules.filterProducts([cafe], query: "cafe", category: .drinks)
        XCTAssertEqual(result.map { $0.id }, [500])
    }
}
