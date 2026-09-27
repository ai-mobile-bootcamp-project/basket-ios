import Foundation

/// Keeps the latest catalog download.
@MainActor
final class CatalogMemoryCache {
    static let shared = CatalogMemoryCache()

    private(set) var products: [CatalogProduct] = []
    private(set) var lastUpdated: Date?

    func update(_ products: [CatalogProduct], at date: Date = Date()) {
        self.products = products
        lastUpdated = date
    }
}
