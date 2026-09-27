import Foundation
import Combine

enum Route: Hashable {
    case listDetail(UUID)
    case itemForm(listId: UUID, itemId: UUID?)
    case browse(listId: UUID)
    case productDetail(listId: UUID, product: CatalogProduct)
    case settings
    case categories
}

@MainActor final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
