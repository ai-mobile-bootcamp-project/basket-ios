import SwiftUI

@MainActor struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var store: BasketStore
    @AppStorage("basket.onboardingDone") private var onboardingDone = false

    var body: some View {
        Group {
            if onboardingDone {
                NavigationStack(path: $router.path) {
                    ListsView()
                        .navigationDestination(for: Route.self) { route in
                            destination(for: route)
                        }
                }
            } else {
                WelcomeView(seedSampleData: { store.seedSampleLists() })
            }
        }
        .overlay(alignment: .bottom) { ToastOverlay() }
        .environment(\.locale, settings.locale)
        .environment(\.layoutDirection, .leftToRight)
        .preferredColorScheme(settings.theme.colorScheme)
        .tint(BasketColor.primary)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .listDetail(let listId):
            ListDetailView(listId: listId)
        case .itemForm(let listId, let itemId):
            ItemFormView(listId: listId, itemId: itemId)
        case .browse(let listId):
            BrowseView(listId: listId)
        case .productDetail(let listId, let product):
            ProductDetailView(listId: listId, product: product)
        case .settings:
            SettingsView()
        case .categories:
            CategoriesView()
        }
    }
}
