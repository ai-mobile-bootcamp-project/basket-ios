import XCTest
#if SWIFT_PACKAGE
@testable import BasketCore
#else
@testable import Basket
#endif

/// Sample content from the design brief: default categories, Weekly shop and BBQ Saturday.
enum SampleFixtures {
    static let baseDate = Date(timeIntervalSince1970: 1_790_300_000)

    static let categories: [ItemCategory] = DefaultCategory.allCases.enumerated().map { index, key in
        ItemCategory(name: key.englishName, position: index, defaultKey: key, isOther: key == .other)
    }

    static func categoryId(_ key: DefaultCategory) -> UUID {
        guard let match = categories.first(where: { $0.defaultKey == key }) else { return UUID() }
        return match.id
    }

    static func makeItem(_ name: String, _ quantity: Int, _ priceCents: Int?, productId: Int? = nil,
                         category: DefaultCategory, ticked: Bool = false, note: String = "",
                         listId: UUID, order: Int) -> ListItem {
        ListItem(listId: listId, name: name, quantity: quantity, priceCents: priceCents,
                 catalogProductId: productId, note: note, isTicked: ticked,
                 categoryId: categoryId(category), createdAt: baseDate.addingTimeInterval(Double(order) * 60))
    }

    static let weeklyShopId = UUID()

    static let weeklyShopItems: [ListItem] = [
        makeItem("Apple", 6, 174, productId: 16, category: .fruitVeg, listId: weeklyShopId, order: 0),
        makeItem("Cucumber", 2, 149, productId: 21, category: .fruitVeg, listId: weeklyShopId, order: 1),
        makeItem("Strawberry", 1, 395, productId: 40, category: .fruitVeg, listId: weeklyShopId, order: 2),
        makeItem("Potatoes", 2, 217, productId: 35, category: .fruitVeg, ticked: true, listId: weeklyShopId, order: 3),
        makeItem("Sourdough bread", 1, nil, category: .bakery, note: "sliced", listId: weeklyShopId, order: 4),
        makeItem("Eggs", 1, 266, productId: 23, category: .dairyEggs, ticked: true, listId: weeklyShopId, order: 5),
        makeItem("Milk", 2, 301, productId: 32, category: .dairyEggs, listId: weeklyShopId, order: 6),
        makeItem("Rice", 1, 543, productId: 38, category: .pantry, listId: weeklyShopId, order: 7),
        makeItem("Nescafe Coffee", 1, 786, productId: 34, category: .drinks, listId: weeklyShopId, order: 8),
        makeItem("Tissue Paper Box", 1, 216, productId: 41, category: .householdPets, ticked: true, listId: weeklyShopId, order: 9)
    ]

    static let bbqSaturdayId = UUID()

    static let bbqSaturdayItems: [ListItem] = [
        makeItem("Beef Steak", 4, 1174, productId: 17, category: .meatFish, listId: bbqSaturdayId, order: 0),
        makeItem("Chicken Meat", 2, 862, productId: 19, category: .meatFish, listId: bbqSaturdayId, order: 1),
        makeItem("Red Onions", 3, 179, productId: 37, category: .fruitVeg, listId: bbqSaturdayId, order: 2),
        makeItem("Green Bell Pepper", 4, 129, productId: 25, category: .fruitVeg, listId: bbqSaturdayId, order: 3),
        makeItem("Soft Drinks", 12, 164, productId: 39, category: .drinks, listId: bbqSaturdayId, order: 4),
        makeItem("Charcoal", 1, 850, category: .other, listId: bbqSaturdayId, order: 5)
    ]

    static var weeklyShop: ShoppingList {
        ShoppingList(id: weeklyShopId, name: "Weekly shop", createdAt: baseDate,
                     updatedAt: baseDate.addingTimeInterval(7_200), items: weeklyShopItems)
    }

    static var bbqSaturday: ShoppingList {
        ShoppingList(id: bbqSaturdayId, name: "BBQ Saturday", createdAt: baseDate,
                     updatedAt: baseDate.addingTimeInterval(3_600), items: bbqSaturdayItems)
    }

    static var campingTrip: ShoppingList {
        ShoppingList(name: "Camping trip", createdAt: baseDate, updatedAt: baseDate.addingTimeInterval(1_800))
    }
}

final class BasketRulesTests: XCTestCase {
    private let english = Locale(identifier: "en")
    private let spanish = Locale(identifier: "es")
    private let arabic = Locale(identifier: "ar")

    private func plainSpaces(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    // MARK: - Money

    func testCentsFromDollars() {
        XCTAssertEqual(BasketRules.cents(fromDollars: 1.99), 199)
        XCTAssertEqual(BasketRules.cents(fromDollars: 0.79), 79)
        XCTAssertEqual(BasketRules.cents(fromDollars: 12.99), 1299)
        XCTAssertEqual(BasketRules.cents(fromDollars: 19.99), 1999)
        XCTAssertEqual(BasketRules.cents(fromDollars: 0.99), 99)
        XCTAssertEqual(BasketRules.cents(fromDollars: 0), 0)
        XCTAssertEqual(BasketRules.cents(fromDollars: 5), 500)
        XCTAssertEqual(BasketRules.cents(fromDollars: 1.005), 101)
        XCTAssertEqual(BasketRules.cents(fromDollars: 2.675), 268)
    }

    func testPriceYouPayNamedExamples() {
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 1.99, discountPercentage: 12.62), 174)
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 2.99, discountPercentage: 11.05), 266)
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 9.99, discountPercentage: 13.7), 862)
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 1.49, discountPercentage: 0.16), 149)
    }

    func testPriceYouPayEdges() {
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 4.00, discountPercentage: 0), 400)
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 4.00, discountPercentage: 100), 0)
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 4.00, discountPercentage: 150), 0)
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 4.00, discountPercentage: -5), 400)
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 0.10, discountPercentage: 5), 10)
        XCTAssertEqual(BasketRules.priceYouPayCents(price: 0.10, discountPercentage: 15), 9)
    }

    func testDiscountBadgeRoundsAndHides() {
        XCTAssertEqual(BasketRules.discountBadgePercent(12.62), 13)
        XCTAssertNil(BasketRules.discountBadgePercent(0.16))
        XCTAssertEqual(BasketRules.discountBadgePercent(1), 1)
        XCTAssertEqual(BasketRules.discountBadgePercent(13.7), 14)
        XCTAssertEqual(BasketRules.discountBadgePercent(9.61), 10)
        XCTAssertEqual(BasketRules.discountBadgePercent(0.5), 1)
        XCTAssertEqual(BasketRules.discountBadgePercent(12.5), 13)
        XCTAssertNil(BasketRules.discountBadgePercent(0.49))
        XCTAssertNil(BasketRules.discountBadgePercent(0))
    }

    func testLineTotals() {
        XCTAssertEqual(BasketRules.lineTotalCents(unitCents: 174, quantity: 6), 1044)
        XCTAssertEqual(BasketRules.lineTotalCents(unitCents: 164, quantity: 12), 1968)
        XCTAssertNil(BasketRules.lineTotalCents(unitCents: nil, quantity: 3))
        XCTAssertEqual(BasketRules.lineTotalCents(SampleFixtures.weeklyShopItems[0]), 1044)
        XCTAssertNil(BasketRules.lineTotalCents(SampleFixtures.weeklyShopItems[4]))
    }

    func testLatinDigitsLocale() {
        XCTAssertTrue(BasketRules.latinDigitsLocale(arabic).identifier.contains("numbers=latn"))
        let replaced = BasketRules.latinDigitsLocale(Locale(identifier: "ar@numbers=arab")).identifier
        XCTAssertTrue(replaced.contains("latn"))
        XCTAssertFalse(replaced.contains("arab"))
    }

    func testFormatMoneyEnglish() {
        XCTAssertEqual(BasketRules.formatMoney(174, locale: english), "$1.74")
        XCTAssertEqual(BasketRules.formatMoney(123_456, locale: english), "$1,234.56")
        XCTAssertEqual(BasketRules.formatMoney(1044, locale: english), "$10.44")
        XCTAssertEqual(BasketRules.formatMoney(4584, locale: english), "$45.84")
        XCTAssertEqual(BasketRules.formatMoney(10_291, locale: english), "$102.91")
        XCTAssertEqual(BasketRules.formatMoney(0, locale: english), "$0.00")
        XCTAssertEqual(BasketRules.formatMoney(5, locale: english), "$0.05")
    }

    func testFormatMoneySpanish() {
        XCTAssertEqual(plainSpaces(BasketRules.formatMoney(174, locale: spanish)), "1,74 US$")
        let thousands = plainSpaces(BasketRules.formatMoney(123_456, locale: spanish))
        XCTAssertTrue(["1234,56 US$", "1.234,56 US$"].contains(thousands), thousands)
    }

    func testFormatMoneyArabicUsesWesternDigits() {
        let arabicIndicDigits: ClosedRange<UInt32> = 0x0660...0x0669
        let extendedArabicIndicDigits: ClosedRange<UInt32> = 0x06F0...0x06F9
        let text = BasketRules.formatMoney(174, locale: arabic)
        XCTAssertFalse(text.unicodeScalars.contains { arabicIndicDigits.contains($0.value) })
        XCTAssertFalse(text.unicodeScalars.contains { extendedArabicIndicDigits.contains($0.value) })
        XCTAssertTrue(text.contains("1"))
        XCTAssertTrue(text.contains("74"))
    }

    func testCurrencySymbol() {
        XCTAssertEqual(BasketRules.currencySymbol(locale: english), "$")
        let spanishSymbol = BasketRules.currencySymbol(locale: spanish)
        XCTAssertFalse(spanishSymbol.isEmpty)
        XCTAssertTrue(BasketRules.formatMoney(174, locale: spanish).contains(spanishSymbol))
    }

    func testFormatPriceInput() {
        XCTAssertEqual(BasketRules.formatPriceInput(174, locale: english), "1.74")
        XCTAssertEqual(BasketRules.formatPriceInput(174, locale: spanish), "1,74")
        XCTAssertEqual(BasketRules.formatPriceInput(5, locale: english), "0.05")
        XCTAssertEqual(BasketRules.formatPriceInput(850, locale: english), "8.50")
        XCTAssertEqual(BasketRules.formatPriceInput(999_999, locale: english), "9999.99")
        XCTAssertEqual(BasketRules.formatPriceInput(123_456, locale: spanish), "1234,56")
    }

    func testFormatPriceInputRoundTripsThroughParsePrice() {
        for cents in [1, 99, 174, 850, 1044, 999_999] {
            for locale in [english, spanish] {
                let text = BasketRules.formatPriceInput(cents, locale: locale)
                XCTAssertEqual(BasketRules.parsePrice(text, locale: locale), .valid(cents: cents), text)
            }
        }
    }

    func testFormatRating() {
        XCTAssertEqual(BasketRules.formatRating(4.19, locale: english), "4.2")
        XCTAssertEqual(BasketRules.formatRating(4.19, locale: spanish), "4,2")
        XCTAssertEqual(BasketRules.formatRating(3.13, locale: english), "3.1")
        XCTAssertEqual(BasketRules.formatRating(5, locale: english), "5.0")
    }

    func testFormatUpdated() {
        let date = Date(timeIntervalSince1970: 1_790_327_640)
        let utc = TimeZone(secondsFromGMT: 0) ?? .current
        XCTAssertEqual(BasketRules.formatUpdated(date, locale: english, timeZone: utc), "25 Sep, 09:14")
    }

    // MARK: - Totals and progress

    func testWeeklyShopTotals() {
        let totals = BasketRules.totals(for: SampleFixtures.weeklyShopItems)
        XCTAssertEqual(totals.totalCents, 4584)
        XCTAssertEqual(totals.inBasketCents, 916)
        XCTAssertEqual(totals.withoutPriceCount, 1)
        XCTAssertEqual(totals.totalCents - totals.inBasketCents, 3668)

        let toBuy = BasketRules.totals(for: SampleFixtures.weeklyShopItems.filter { !$0.isTicked })
        XCTAssertEqual(toBuy.totalCents, 3668)
        XCTAssertEqual(toBuy.inBasketCents, 0)
        XCTAssertEqual(toBuy.withoutPriceCount, 1)
    }

    func testBBQSaturdayTotals() {
        let totals = BasketRules.totals(for: SampleFixtures.bbqSaturdayItems)
        XCTAssertEqual(totals.totalCents, 10_291)
        XCTAssertEqual(totals.inBasketCents, 0)
        XCTAssertEqual(totals.withoutPriceCount, 0)
    }

    func testEmptyListTotals() {
        let totals = BasketRules.totals(for: [])
        XCTAssertEqual(totals.totalCents, 0)
        XCTAssertEqual(totals.inBasketCents, 0)
        XCTAssertEqual(totals.withoutPriceCount, 0)
    }

    func testProgressThreeOfTen() {
        let progress = BasketRules.progress(for: SampleFixtures.weeklyShopItems)
        XCTAssertEqual(progress.ticked, 3)
        XCTAssertEqual(progress.count, 10)
        XCTAssertEqual(progress.fraction, 0.3, accuracy: 0.000_1)
        XCTAssertFalse(progress.isDone)
    }

    func testProgressEmptyList() {
        let progress = BasketRules.progress(for: [])
        XCTAssertEqual(progress.ticked, 0)
        XCTAssertEqual(progress.count, 0)
        XCTAssertEqual(progress.fraction, 0, accuracy: 0.000_1)
        XCTAssertFalse(progress.isDone)
    }

    func testProgressAllTicked() {
        let allTicked = SampleFixtures.weeklyShopItems.map { item -> ListItem in
            var copy = item
            copy.isTicked = true
            return copy
        }
        let progress = BasketRules.progress(for: allTicked)
        XCTAssertEqual(progress.ticked, 10)
        XCTAssertEqual(progress.count, 10)
        XCTAssertEqual(progress.fraction, 1, accuracy: 0.000_1)
        XCTAssertTrue(progress.isDone)
    }

    // MARK: - Quantity

    func testQuantityBounds() {
        XCTAssertEqual(BasketRules.clampQuantity(0), 1)
        XCTAssertEqual(BasketRules.clampQuantity(-4), 1)
        XCTAssertEqual(BasketRules.clampQuantity(100), 99)
        XCTAssertEqual(BasketRules.clampQuantity(42), 42)
        XCTAssertFalse(BasketRules.canDecrement(1))
        XCTAssertTrue(BasketRules.canDecrement(2))
        XCTAssertFalse(BasketRules.canIncrement(99))
        XCTAssertTrue(BasketRules.canIncrement(98))
        XCTAssertEqual(BasketRules.quantityRange, 1...99)
    }

    func testMergedQuantity() {
        XCTAssertEqual(BasketRules.mergedQuantity(existing: 6, adding: 1), 7)
        XCTAssertEqual(BasketRules.mergedQuantity(existing: 98, adding: 5), 99)
        XCTAssertEqual(BasketRules.mergedQuantity(existing: 99, adding: 1), 99)
        XCTAssertEqual(BasketRules.mergedQuantity(existing: 1, adding: 1), 2)
    }

    // MARK: - Grouping

    func testSectionsWithTickedItemsMovedDown() {
        let result = BasketRules.sections(items: SampleFixtures.weeklyShopItems,
                                          categories: SampleFixtures.categories,
                                          moveTickedDown: true)
        XCTAssertEqual(result.toBuy.map { $0.category.name },
                       ["Fruit & veg", "Bakery", "Dairy & eggs", "Pantry", "Drinks"])
        XCTAssertEqual(result.toBuy.map { $0.items.count }, [3, 1, 1, 1, 1])
        XCTAssertEqual(result.toBuy.first?.items.map { $0.name }, ["Apple", "Cucumber", "Strawberry"])
        XCTAssertEqual(result.inBasket.map { $0.name }, ["Eggs", "Potatoes", "Tissue Paper Box"])
        XCTAssertEqual(result.toBuy.first?.id, SampleFixtures.categoryId(.fruitVeg))
    }

    func testSectionsWithTickedItemsInPlace() {
        let result = BasketRules.sections(items: SampleFixtures.weeklyShopItems,
                                          categories: SampleFixtures.categories,
                                          moveTickedDown: false)
        XCTAssertEqual(result.toBuy.count, 6)
        XCTAssertEqual(result.toBuy.map { $0.category.name },
                       ["Fruit & veg", "Bakery", "Dairy & eggs", "Pantry", "Drinks", "Household & pets"])
        XCTAssertEqual(result.toBuy.first?.items.map { $0.name }, ["Apple", "Cucumber", "Potatoes", "Strawberry"])
        XCTAssertEqual(result.toBuy[2].items.map { $0.name }, ["Eggs", "Milk"])
        XCTAssertTrue(result.inBasket.isEmpty)
    }

    func testSectionsFollowCustomPositions() {
        var categories = SampleFixtures.categories
        if let index = categories.firstIndex(where: { $0.defaultKey == .bakery }) {
            categories[index].position = -1
        }
        let result = BasketRules.sections(items: SampleFixtures.weeklyShopItems,
                                          categories: categories,
                                          moveTickedDown: true)
        XCTAssertEqual(result.toBuy.map { $0.category.name },
                       ["Bakery", "Fruit & veg", "Dairy & eggs", "Pantry", "Drinks"])
        XCTAssertEqual(BasketRules.orderedCategories(categories).first?.name, "Bakery")
    }

    func testOtherAlwaysLast() {
        var categories = SampleFixtures.categories
        if let index = categories.firstIndex(where: { $0.isOther }) {
            categories[index].position = -5
        }
        let ordered = BasketRules.orderedCategories(categories)
        XCTAssertEqual(ordered.count, 9)
        XCTAssertEqual(ordered.first?.name, "Fruit & veg")
        XCTAssertEqual(ordered.last?.name, "Other")
        XCTAssertEqual(ordered.last?.isOther, true)

        let result = BasketRules.sections(items: SampleFixtures.bbqSaturdayItems,
                                          categories: categories,
                                          moveTickedDown: true)
        XCTAssertEqual(result.toBuy.map { $0.category.name }, ["Fruit & veg", "Meat & fish", "Drinks", "Other"])
        XCTAssertEqual(result.toBuy.last?.items.map { $0.name }, ["Charcoal"])
        XCTAssertEqual(result.toBuy[1].items.map { $0.name }, ["Beef Steak", "Chicken Meat"])
    }

    func testOrderedCategoriesDefaultOrder() {
        let ordered = BasketRules.orderedCategories(Array(SampleFixtures.categories.reversed()))
        XCTAssertEqual(ordered.map { $0.name }, [
            "Fruit & veg", "Bakery", "Dairy & eggs", "Meat & fish", "Pantry",
            "Frozen", "Drinks", "Household & pets", "Other"
        ])
    }

    func testUnknownOrMissingCategoryGoesToOther() {
        let listId = UUID()
        let items = [
            ListItem(listId: listId, name: "Batteries", categoryId: UUID(), createdAt: SampleFixtures.baseDate),
            ListItem(listId: listId, name: "Candles", categoryId: nil, createdAt: SampleFixtures.baseDate),
            ListItem(listId: listId, name: "Apple", categoryId: SampleFixtures.categoryId(.fruitVeg),
                     createdAt: SampleFixtures.baseDate)
        ]
        let result = BasketRules.sections(items: items, categories: SampleFixtures.categories, moveTickedDown: true)
        XCTAssertEqual(result.toBuy.map { $0.category.name }, ["Fruit & veg", "Other"])
        XCTAssertEqual(result.toBuy.last?.id, SampleFixtures.categoryId(.other))
        XCTAssertEqual(result.toBuy.last?.items.map { $0.name }, ["Batteries", "Candles"])
    }

    func testOtherIsSynthesizedWhenMissing() {
        let listId = UUID()
        let items = [
            ListItem(listId: listId, name: "Candles", categoryId: nil, createdAt: SampleFixtures.baseDate),
            ListItem(listId: listId, name: "Milk", categoryId: SampleFixtures.categoryId(.dairyEggs),
                     createdAt: SampleFixtures.baseDate)
        ]
        let categories = SampleFixtures.categories.filter { !$0.isOther }
        let result = BasketRules.sections(items: items, categories: categories, moveTickedDown: true)
        XCTAssertEqual(result.toBuy.count, 2)
        XCTAssertEqual(result.toBuy.first?.category.name, "Dairy & eggs")
        XCTAssertEqual(result.toBuy.last?.category.isOther, true)
        XCTAssertEqual(result.toBuy.last?.category.name, "Other")
        XCTAssertEqual(result.toBuy.last?.items.map { $0.name }, ["Candles"])
    }

    // MARK: - Sorting

    func testSortingIgnoresCaseAndAccents() {
        let listId = UUID()
        let names = ["Fig", "apple", "Donut", "Éclair", "Apple", "banana"]
        let items = names.enumerated().map { index, name in
            ListItem(listId: listId, name: name, createdAt: SampleFixtures.baseDate.addingTimeInterval(Double(index)))
        }
        let sorted = BasketRules.sortedItems(items).map { $0.name }
        XCTAssertEqual(sorted, ["apple", "Apple", "banana", "Donut", "Éclair", "Fig"])
    }

    func testCompareNames() {
        XCTAssertEqual(BasketRules.compareNames("apple", "Apple"), .orderedSame)
        XCTAssertEqual(BasketRules.compareNames("Éclair", "eclair"), .orderedSame)
        XCTAssertEqual(BasketRules.compareNames("Donut", "Éclair"), .orderedAscending)
        XCTAssertEqual(BasketRules.compareNames("Fig", "Éclair"), .orderedDescending)
    }

    func testSortedItemsWeeklyShop() {
        let names = BasketRules.sortedItems(SampleFixtures.weeklyShopItems).map { $0.name }
        XCTAssertEqual(names, [
            "Apple", "Cucumber", "Eggs", "Milk", "Nescafe Coffee", "Potatoes",
            "Rice", "Sourdough bread", "Strawberry", "Tissue Paper Box"
        ])
    }

    func testSortedListsMostRecentFirst() {
        let lists = [SampleFixtures.campingTrip, SampleFixtures.weeklyShop, SampleFixtures.bbqSaturday]
        let names = BasketRules.sortedLists(lists).map { $0.name }
        XCTAssertEqual(names, ["Weekly shop", "BBQ Saturday", "Camping trip"])
    }

    // MARK: - Duplicates and names

    func testFindDuplicate() {
        let items = SampleFixtures.weeklyShopItems
        XCTAssertEqual(BasketRules.findDuplicate(in: items, name: " milk ", catalogProductId: nil)?.name, "Milk")
        XCTAssertEqual(BasketRules.findDuplicate(in: items, name: "MILK", catalogProductId: nil)?.name, "Milk")
        XCTAssertEqual(BasketRules.findDuplicate(in: items, name: "Red apples", catalogProductId: 16)?.name, "Apple")
        XCTAssertEqual(BasketRules.findDuplicate(in: items, name: "sourdough bread", catalogProductId: nil)?.name,
                       "Sourdough bread")
        XCTAssertNil(BasketRules.findDuplicate(in: items, name: "Bananas", catalogProductId: 99))
        XCTAssertNil(BasketRules.findDuplicate(in: items, name: "Butter", catalogProductId: nil))
        XCTAssertNil(BasketRules.findDuplicate(in: [], name: "Milk", catalogProductId: 32))
    }

    func testNormalizedAndTrimmedNames() {
        XCTAssertEqual(BasketRules.normalizedName("  Milk \n"), "milk")
        XCTAssertEqual(BasketRules.trimmedName("  Oat milk  "), "Oat milk")
        XCTAssertNil(BasketRules.trimmedName("   "))
        XCTAssertNil(BasketRules.trimmedName(""))
    }

    // MARK: - Price input

    func testParsePriceEnglish() {
        XCTAssertEqual(BasketRules.parsePrice("1.99", locale: english), .valid(cents: 199))
        XCTAssertEqual(BasketRules.parsePrice("1,99", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("12345", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("0", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("0.00", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("0.01", locale: english), .valid(cents: 1))
        XCTAssertEqual(BasketRules.parsePrice("9999.99", locale: english), .valid(cents: 999_999))
        XCTAssertEqual(BasketRules.parsePrice("10000", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("1.999", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice(".5", locale: english), .valid(cents: 50))
        XCTAssertEqual(BasketRules.parsePrice("5.", locale: english), .valid(cents: 500))
        XCTAssertEqual(BasketRules.parsePrice(" 2.50 ", locale: english), .valid(cents: 250))
        XCTAssertEqual(BasketRules.parsePrice("8.5", locale: english), .valid(cents: 850))
        XCTAssertEqual(BasketRules.parsePrice("1,000", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("1.2.3", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice(".", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("-1", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("abc", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("$1.99", locale: english), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("", locale: english), .empty)
        XCTAssertEqual(BasketRules.parsePrice("   ", locale: english), .empty)
    }

    func testParsePriceSpanish() {
        XCTAssertEqual(BasketRules.parsePrice("1,99", locale: spanish), .valid(cents: 199))
        XCTAssertEqual(BasketRules.parsePrice("1.99", locale: spanish), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("9999,99", locale: spanish), .valid(cents: 999_999))
        XCTAssertEqual(BasketRules.parsePrice("0,01", locale: spanish), .valid(cents: 1))
        XCTAssertEqual(BasketRules.parsePrice("12345", locale: spanish), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("0", locale: spanish), .invalid)
        XCTAssertEqual(BasketRules.parsePrice("1,999", locale: spanish), .invalid)
        XCTAssertEqual(BasketRules.parsePrice(",5", locale: spanish), .valid(cents: 50))
        XCTAssertEqual(BasketRules.parsePrice("5,", locale: spanish), .valid(cents: 500))
        XCTAssertEqual(BasketRules.parsePrice("", locale: spanish), .empty)
    }

    // MARK: - Category names

    func testValidateCategoryName() {
        let existing = SampleFixtures.categories
        let bakeryId = SampleFixtures.categoryId(.bakery)
        XCTAssertEqual(BasketRules.validateCategoryName("bakery", existing: existing, excluding: nil), .duplicate)
        XCTAssertEqual(BasketRules.validateCategoryName("  OTHER ", existing: existing, excluding: nil), .duplicate)
        XCTAssertEqual(BasketRules.validateCategoryName(String(repeating: "a", count: 31), existing: existing, excluding: nil),
                       .tooLong)
        XCTAssertNil(BasketRules.validateCategoryName(String(repeating: "a", count: 30), existing: existing, excluding: nil))
        XCTAssertEqual(BasketRules.validateCategoryName("   ", existing: existing, excluding: nil), .empty)
        XCTAssertNil(BasketRules.validateCategoryName("Bakery", existing: existing, excluding: bakeryId))
        XCTAssertEqual(BasketRules.validateCategoryName("Pantry", existing: existing, excluding: bakeryId), .duplicate)
        XCTAssertNil(BasketRules.validateCategoryName(" Snacks ", existing: existing, excluding: nil))
    }

    // MARK: - Share text

    func testWeeklyShopShareText() {
        let text = BasketRules.shareText(listName: "Weekly shop",
                                         items: SampleFixtures.weeklyShopItems,
                                         categories: SampleFixtures.categories,
                                         locale: english,
                                         labels: .english)
        let expected = [
            "Weekly shop",
            "To buy (7)",
            "\u{2022} Apple \u{00D7} 6 \u{2014} $10.44",
            "\u{2022} Cucumber \u{00D7} 2 \u{2014} $2.98",
            "\u{2022} Strawberry \u{2014} $3.95",
            "\u{2022} Sourdough bread (sliced)",
            "\u{2022} Milk \u{00D7} 2 \u{2014} $6.02",
            "\u{2022} Rice \u{2014} $5.43",
            "\u{2022} Nescafe Coffee \u{2014} $7.86",
            "In basket (3)",
            "\u{2713} Potatoes \u{00D7} 2 \u{2014} $4.34",
            "\u{2713} Eggs \u{2014} $2.66",
            "\u{2713} Tissue Paper Box \u{2014} $2.16",
            "Total $45.84 (1 item without price)"
        ].joined(separator: "\n")
        XCTAssertEqual(text, expected)
    }

    func testEmptyListShareText() {
        let text = BasketRules.shareText(listName: "Camping trip",
                                         items: [],
                                         categories: SampleFixtures.categories,
                                         locale: english,
                                         labels: .english)
        XCTAssertEqual(text, "Camping trip\nTotal $0.00")
    }

    func testBBQSaturdayShareText() {
        let text = BasketRules.shareText(listName: "BBQ Saturday",
                                         items: SampleFixtures.bbqSaturdayItems,
                                         categories: SampleFixtures.categories,
                                         locale: english,
                                         labels: .english)
        let expected = [
            "BBQ Saturday",
            "To buy (6)",
            "\u{2022} Green Bell Pepper \u{00D7} 4 \u{2014} $5.16",
            "\u{2022} Red Onions \u{00D7} 3 \u{2014} $5.37",
            "\u{2022} Beef Steak \u{00D7} 4 \u{2014} $46.96",
            "\u{2022} Chicken Meat \u{00D7} 2 \u{2014} $17.24",
            "\u{2022} Soft Drinks \u{00D7} 12 \u{2014} $19.68",
            "\u{2022} Charcoal \u{2014} $8.50",
            "Total $102.91"
        ].joined(separator: "\n")
        XCTAssertEqual(text, expected)
    }

    func testEnglishShareLabels() {
        let labels = BasketRules.ShareLabels.english
        XCTAssertEqual(labels.toBuy(7), "To buy (7)")
        XCTAssertEqual(labels.inBasket(3), "In basket (3)")
        XCTAssertEqual(labels.total("$45.84"), "Total $45.84")
        XCTAssertEqual(labels.withoutPrice(1), "1 item without price")
        XCTAssertEqual(labels.withoutPrice(2), "2 items without price")
    }

    // MARK: - Limits

    func testLimits() {
        XCTAssertEqual(BasketRules.maxListNameLength, 40)
        XCTAssertEqual(BasketRules.maxItemNameLength, 60)
        XCTAssertEqual(BasketRules.maxNoteLength, 80)
        XCTAssertEqual(BasketRules.maxCategoryNameLength, 30)
        XCTAssertEqual(BasketRules.minPriceCents, 1)
        XCTAssertEqual(BasketRules.maxPriceCents, 999_999)
    }
}
