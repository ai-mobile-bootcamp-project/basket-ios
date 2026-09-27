import SwiftUI

@main
struct BasketApp: App {
    @StateObject private var store = BasketStore.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var router = AppRouter.shared
    @StateObject private var toast = ToastCenter.shared

    init() {
        // Shared cache backs AsyncImage (URLSession.shared) for catalog thumbnails and images.
        URLCache.shared = URLCache(memoryCapacity: 20 * 1024 * 1024,
                                   diskCapacity: 150 * 1024 * 1024,
                                   directory: nil)
        BasketStore.shared.seedDefaultCategoriesIfNeeded()
        // Installs that already have lists skip the Welcome screen.
        if !UserDefaults.standard.bool(forKey: "basket.onboardingDone") && !BasketStore.shared.lists.isEmpty {
            UserDefaults.standard.set(true, forKey: "basket.onboardingDone")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(settings)
                .environmentObject(router)
                .environmentObject(toast)
        }
    }
}
