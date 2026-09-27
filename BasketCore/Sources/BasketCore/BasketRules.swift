import Foundation

/// Product rules shared by every screen: money, totals, ordering, duplicates, validation, catalog mapping and sharing.
public enum BasketRules {
    public static let quantityRange: ClosedRange<Int> = 1...99
    public static let maxListNameLength = 40
    public static let maxItemNameLength = 60
    public static let maxNoteLength = 80
    public static let maxCategoryNameLength = 30
    public static let minPriceCents = 1
    public static let maxPriceCents = 999_999

    // MARK: - Money

    /// Converts a dollar amount to whole cents, rounding halves away from zero (1.99 → 199).
    public static func cents(fromDollars dollars: Double) -> Int {
        guard dollars.isFinite else { return 0 }
        let exact = Decimal(string: String(dollars)) ?? Decimal(dollars)
        return roundedInteger(exact * 100)
    }

    /// Catalog price minus the discount, in whole cents, rounded to the nearest cent with halves up.
    public static func priceYouPayCents(price: Double, discountPercentage: Double) -> Int {
        let priceCents = cents(fromDollars: price)
        let basisPoints = min(max(cents(fromDollars: discountPercentage), 0), 10_000)
        return (priceCents * (10_000 - basisPoints) + 5_000) / 10_000
    }

    public static func priceYouPayCents(for product: CatalogProduct) -> Int {
        priceYouPayCents(price: product.price, discountPercentage: product.discountPercentage)
    }

    /// Discount rounded to a whole percent; nil when it rounds to zero.
    public static func discountBadgePercent(_ discountPercentage: Double) -> Int? {
        guard discountPercentage.isFinite else { return nil }
        let exact = Decimal(string: String(discountPercentage)) ?? Decimal(discountPercentage)
        let percent = roundedInteger(exact)
        return percent > 0 ? percent : nil
    }

    public static func lineTotalCents(unitCents: Int?, quantity: Int) -> Int? {
        guard let unitCents = unitCents else { return nil }
        return unitCents * quantity
    }

    public static func lineTotalCents(_ item: ListItem) -> Int? {
        lineTotalCents(unitCents: item.priceCents, quantity: item.quantity)
    }

    /// The same locale with Western (Latin) digits forced.
    public static func latinDigitsLocale(_ locale: Locale) -> Locale {
        let identifier = locale.identifier
        let base: String
        if let keywordStart = identifier.firstIndex(of: "@") {
            base = String(identifier[..<keywordStart])
        } else {
            base = identifier
        }
        return Locale(identifier: base + "@numbers=latn")
    }

    /// US dollars in the locale's currency format with Western digits: en "$1.74", es "1,74 US$".
    public static func formatMoney(_ cents: Int, locale: Locale) -> String {
        let formatter = currencyFormatter(locale: locale)
        let amount = NSDecimalNumber(decimal: Decimal(cents) / 100)
        if let text = formatter.string(from: amount) {
            return text
        }
        return "$" + plainAmount(cents, separator: ".")
    }

    public static func currencySymbol(locale: Locale) -> String {
        let symbol = currencyFormatter(locale: locale).currencySymbol ?? "$"
        return symbol.isEmpty ? "$" : symbol
    }

    /// Amount for a price text field: 174 → "1.74" (en) / "1,74" (es). No symbol, no grouping.
    public static func formatPriceInput(_ cents: Int, locale: Locale) -> String {
        plainAmount(cents, separator: decimalSeparator(locale: locale))
    }

    /// One fraction digit, halves up: 4.19 → "4.2" (es "4,2").
    public static func formatRating(_ rating: Double, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = latinDigitsLocale(locale)
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: rating)) ?? String(format: "%.1f", rating)
    }

    /// Short date and 24-hour time, e.g. "25 Sep, 09:14".
    public static func formatUpdated(_ date: Date, locale: Locale, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = latinDigitsLocale(locale)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }

    private static func roundedInteger(_ value: Decimal) -> Int {
        var source = value
        var result = Decimal()
        NSDecimalRound(&result, &source, 0, .plain)
        return NSDecimalNumber(decimal: result).intValue
    }

    private static func currencyFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = latinDigitsLocale(locale)
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private static func decimalSeparator(locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = latinDigitsLocale(locale)
        formatter.numberStyle = .decimal
        let separator = formatter.decimalSeparator ?? "."
        return separator.isEmpty ? "." : separator
    }

    private static func plainAmount(_ cents: Int, separator: String) -> String {
        let sign = cents < 0 ? "-" : ""
        let magnitude = cents.magnitude
        let whole = magnitude / 100
        let fraction = magnitude % 100
        let fractionText = fraction < 10 ? "0" + String(fraction) : String(fraction)
        return sign + String(whole) + separator + fractionText
    }

    // MARK: - Totals and progress

    public struct Totals: Equatable {
        /// Sum of the line totals of priced items.
        public let totalCents: Int
        /// Sum of the line totals of priced, ticked items.
        public let inBasketCents: Int
        /// Number of items without a price.
        public let withoutPriceCount: Int
    }

    public static func totals(for items: [ListItem]) -> Totals {
        var total = 0
        var inBasket = 0
        var withoutPrice = 0
        for item in items {
            guard let line = lineTotalCents(item) else {
                withoutPrice += 1
                continue
            }
            total += line
            if item.isTicked {
                inBasket += line
            }
        }
        return Totals(totalCents: total, inBasketCents: inBasket, withoutPriceCount: withoutPrice)
    }

    public struct Progress: Equatable {
        public let ticked: Int
        public let count: Int

        /// Share of ticked items, 0 when the list is empty.
        public var fraction: Double {
            count == 0 ? 0 : Double(ticked) / Double(count)
        }

        public var isDone: Bool {
            count > 0 && ticked == count
        }
    }

    public static func progress(for items: [ListItem]) -> Progress {
        let tickedCount = items.filter { $0.isTicked }.count
        return Progress(ticked: tickedCount, count: items.count)
    }

    // MARK: - Quantity

    public static func clampQuantity(_ quantity: Int) -> Int {
        min(max(quantity, quantityRange.lowerBound), quantityRange.upperBound)
    }

    public static func canDecrement(_ quantity: Int) -> Bool {
        quantity > quantityRange.lowerBound
    }

    public static func canIncrement(_ quantity: Int) -> Bool {
        quantity < quantityRange.upperBound
    }

    public static func mergedQuantity(existing: Int, adding: Int) -> Int {
        clampQuantity(existing + adding)
    }

    // MARK: - Sorting and grouping

    /// Name order ignoring case and accents.
    public static func compareNames(_ a: String, _ b: String) -> ComparisonResult {
        a.compare(b, options: [.caseInsensitive, .diacriticInsensitive])
    }

    /// Name A→Z, ties by insertion order.
    public static func sortedItems(_ items: [ListItem]) -> [ListItem] {
        items.sorted { lhs, rhs in
            let order = compareNames(lhs.name, rhs.name)
            if order != .orderedSame {
                return order == .orderedAscending
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    /// Most recently changed first.
    public static func sortedLists(_ lists: [ShoppingList]) -> [ShoppingList] {
        lists.sorted { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }
            let order = compareNames(lhs.name, rhs.name)
            if order != .orderedSame {
                return order == .orderedAscending
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    /// Aisle order: position ascending, Other always last.
    public static func orderedCategories(_ categories: [ItemCategory]) -> [ItemCategory] {
        let regular = categories
            .filter { !$0.isOther }
            .sorted { lhs, rhs in
                if lhs.position != rhs.position {
                    return lhs.position < rhs.position
                }
                let order = compareNames(lhs.name, rhs.name)
                if order != .orderedSame {
                    return order == .orderedAscending
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
        let others = categories.filter { $0.isOther }
        return regular + others
    }

    public struct ItemSection: Identifiable, Hashable {
        public let category: ItemCategory
        public let items: [ListItem]

        public var id: UUID {
            category.id
        }

        public init(category: ItemCategory, items: [ListItem]) {
            self.category = category
            self.items = items
        }
    }

    public struct ListSections: Hashable {
        /// Aisle order, empty sections hidden, items A→Z.
        public let toBuy: [ItemSection]
        /// Ticked items A→Z; empty when ticked items stay in their aisle.
        public let inBasket: [ListItem]

        public init(toBuy: [ItemSection], inBasket: [ListItem]) {
            self.toBuy = toBuy
            self.inBasket = inBasket
        }
    }

    private static let standInOtherId = UUID(uuidString: "6B1E0C2A-5D3F-4A8E-9C71-0F2B3D4E5A60") ?? UUID()

    private static var standInOther: ItemCategory {
        ItemCategory(id: standInOtherId, name: "Other", position: Int.max, defaultKey: .other, isOther: true)
    }

    public static func sections(items: [ListItem], categories: [ItemCategory], moveTickedDown: Bool) -> ListSections {
        var ordered = orderedCategories(categories)
        let otherCategory: ItemCategory
        if let existing = ordered.first(where: { $0.isOther }) {
            otherCategory = existing
        } else {
            otherCategory = standInOther
            ordered.append(otherCategory)
        }
        let knownIds = Set(ordered.map { $0.id })

        var grouped: [UUID: [ListItem]] = [:]
        for item in items where !(moveTickedDown && item.isTicked) {
            let categoryId: UUID
            if let id = item.categoryId, knownIds.contains(id) {
                categoryId = id
            } else {
                categoryId = otherCategory.id
            }
            grouped[categoryId, default: []].append(item)
        }

        let toBuy: [ItemSection] = ordered.compactMap { category -> ItemSection? in
            guard let group = grouped[category.id], !group.isEmpty else { return nil }
            return ItemSection(category: category, items: sortedItems(group))
        }
        let inBasket = moveTickedDown ? sortedItems(items.filter { $0.isTicked }) : []
        return ListSections(toBuy: toBuy, inBasket: inBasket)
    }

    /// Title A→Z, ties by id.
    public static func sortedProducts(_ products: [CatalogProduct]) -> [CatalogProduct] {
        products.sorted { lhs, rhs in
            let order = compareNames(lhs.title, rhs.title)
            if order != .orderedSame {
                return order == .orderedAscending
            }
            return lhs.id < rhs.id
        }
    }

    /// Local search and chip filter over the saved catalog, A→Z.
    public static func filterProducts(_ products: [CatalogProduct], query: String, category: DefaultCategory?) -> [CatalogProduct] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = products.filter { product in
            if !trimmedQuery.isEmpty,
               product.title.range(of: trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive]) == nil {
                return false
            }
            if let category = category, product.defaultCategory != category {
                return false
            }
            return true
        }
        return sortedProducts(matches)
    }

    // MARK: - Duplicates and names

    public static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// The row a new entry merges into: same catalog product, or same name ignoring case and outer spaces.
    public static func findDuplicate(in items: [ListItem], name: String, catalogProductId: Int?) -> ListItem? {
        let key = normalizedName(name)
        return sortedItems(items).first { item in
            if let productId = catalogProductId, item.catalogProductId == productId {
                return true
            }
            return normalizedName(item.name) == key
        }
    }

    public static func trimmedName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Validation

    public enum PriceInput: Equatable {
        case empty
        case valid(cents: Int)
        case invalid
    }

    /// Parses a price typed with the locale's decimal separator: en "1.99" / es "1,99" → 199.
    public static func parsePrice(_ text: String, locale: Locale) -> PriceInput {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .empty
        }
        let separator = decimalSeparator(locale: locale)
        let parts = trimmed.components(separatedBy: separator)
        guard parts.count <= 2 else { return .invalid }

        let wholeText = parts[0]
        let fractionText = parts.count == 2 ? parts[1] : ""
        guard isAsciiDigits(wholeText), isAsciiDigits(fractionText) else { return .invalid }
        guard fractionText.count <= 2 else { return .invalid }
        guard !wholeText.isEmpty || !fractionText.isEmpty else { return .invalid }

        let significantWhole = wholeText.drop(while: { $0 == "0" })
        guard significantWhole.count <= 7 else { return .invalid }
        let whole = significantWhole.isEmpty ? 0 : (Int(String(significantWhole)) ?? 0)

        var fraction = 0
        if fractionText.count == 1 {
            fraction = (Int(fractionText) ?? 0) * 10
        } else if fractionText.count == 2 {
            fraction = Int(fractionText) ?? 0
        }

        let cents = whole * 100 + fraction
        guard cents >= minPriceCents && cents <= maxPriceCents else { return .invalid }
        return .valid(cents: cents)
    }

    private static func isAsciiDigits(_ text: String) -> Bool {
        text.unicodeScalars.allSatisfy { $0.value >= 48 && $0.value <= 57 }
    }

    public enum CategoryNameError: Equatable {
        case empty
        case tooLong
        case duplicate
    }

    public static func validateCategoryName(_ name: String, existing: [ItemCategory], excluding id: UUID?) -> CategoryNameError? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .empty
        }
        if trimmed.count > maxCategoryNameLength {
            return .tooLong
        }
        let key = normalizedName(trimmed)
        let clash = existing.contains { category in
            category.id != id && normalizedName(category.name) == key
        }
        return clash ? .duplicate : nil
    }

    // MARK: - Catalog mapping

    /// Basket category for DummyJSON tags; the first matching tag wins.
    public static func category(forTags tags: [String]) -> DefaultCategory {
        for tag in tags {
            switch tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "fruits", "vegetables":
                return .fruitVeg
            case "dairy":
                return .dairyEggs
            case "meat", "seafood":
                return .meatFish
            case "cooking essentials", "condiments", "grains", "health supplements":
                return .pantry
            case "desserts":
                return .frozen
            case "beverages", "coffee":
                return .drinks
            case "household essentials", "pet supplies":
                return .householdPets
            default:
                continue
            }
        }
        return .other
    }

    // MARK: - Share text

    public struct ShareLabels {
        public var toBuy: (Int) -> String
        public var inBasket: (Int) -> String
        public var total: (String) -> String
        public var withoutPrice: (Int) -> String

        public init(toBuy: @escaping (Int) -> String, inBasket: @escaping (Int) -> String,
                    total: @escaping (String) -> String, withoutPrice: @escaping (Int) -> String) {
            self.toBuy = toBuy
            self.inBasket = inBasket
            self.total = total
            self.withoutPrice = withoutPrice
        }

        public static let english = ShareLabels(
            toBuy: { count in "To buy (\(count))" },
            inBasket: { count in "In basket (\(count))" },
            total: { amount in "Total \(amount)" },
            withoutPrice: { count in count == 1 ? "1 item without price" : "\(count) items without price" }
        )
    }

    /// Plain-text list for the share sheet.
    public static func shareText(listName: String, items: [ListItem], categories: [ItemCategory],
                                 locale: Locale, labels: ShareLabels) -> String {
        var lines: [String] = [listName]

        let toBuyItems = aisleOrder(items.filter { !$0.isTicked }, categories: categories)
        if !toBuyItems.isEmpty {
            lines.append(labels.toBuy(toBuyItems.count))
            for item in toBuyItems {
                lines.append(shareLine(item, bullet: "\u{2022}", locale: locale))
            }
        }

        let basketItems = aisleOrder(items.filter { $0.isTicked }, categories: categories)
        if !basketItems.isEmpty {
            lines.append(labels.inBasket(basketItems.count))
            for item in basketItems {
                lines.append(shareLine(item, bullet: "\u{2713}", locale: locale))
            }
        }

        let summary = totals(for: items)
        var totalLine = labels.total(formatMoney(summary.totalCents, locale: locale))
        if summary.withoutPriceCount > 0 {
            totalLine += " (" + labels.withoutPrice(summary.withoutPriceCount) + ")"
        }
        lines.append(totalLine)
        return lines.joined(separator: "\n")
    }

    private static func aisleOrder(_ items: [ListItem], categories: [ItemCategory]) -> [ListItem] {
        sections(items: items, categories: categories, moveTickedDown: false).toBuy.flatMap { $0.items }
    }

    private static func shareLine(_ item: ListItem, bullet: String, locale: Locale) -> String {
        var line = bullet + " " + item.name
        if !item.note.isEmpty {
            line += " (" + item.note + ")"
        }
        if item.quantity > 1 {
            line += " \u{00D7} " + String(item.quantity)
        }
        if let lineCents = lineTotalCents(item) {
            line += " \u{2014} " + formatMoney(lineCents, locale: locale)
        }
        return line
    }
}
