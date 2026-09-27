import SwiftUI

/// Preferences: theme, language, list behaviour, catalog refresh, reset and about.
@MainActor struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.locale) private var locale

    @State private var lastUpdated: Date? = nil
    @State private var isRefreshing = false
    @State private var isResetAlertPresented = false

    private static let catalogWebsite = URL(string: "https://dummyjson.com")!

    init() {}

    var body: some View {
        List {
            themeSection
            languageSection
            listsSection
            catalogSection
            resetSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background {
            BasketColor.surface.ignoresSafeArea()
        }
        .navigationTitle(L10n.tr("settings.title", locale))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BasketColor.surface, for: .navigationBar)
        .onAppear {
            lastUpdated = CatalogMemoryCache.shared.lastUpdated
        }
        .alert(L10n.tr("settings.reset.title", locale), isPresented: $isResetAlertPresented) {
            Button(L10n.tr("common.cancel", locale), role: .cancel) {}
            Button(L10n.tr("settings.reset.confirm", locale), role: .destructive) {
                resetSampleData()
            }
        } message: {
            Text(L10n.tr("settings.reset.message", locale))
        }
    }

    // MARK: - Sections

    private var themeSection: some View {
        Section {
            Picker(L10n.tr("settings.theme", locale), selection: $settings.theme) {
                ForEach(BasketThemeMode.allCases, id: \.self) { mode in
                    Text(themeName(mode))
                        .font(BasketFont.bodyLarge)
                        .foregroundColor(BasketColor.onSurface)
                        .tag(mode)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.theme")
        }
    }

    private var languageSection: some View {
        Section {
            Picker(L10n.tr("settings.language", locale), selection: $settings.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(languageName(language))
                        .font(BasketFont.bodyLarge)
                        .foregroundColor(BasketColor.onSurface)
                        .tag(language)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.language")
        }
    }

    private var listsSection: some View {
        Section {
            Toggle(isOn: $settings.moveTickedDown) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr("settings.moveTicked", locale))
                        .font(BasketFont.bodyLarge)
                        .foregroundColor(BasketColor.onSurface)
                    Text(L10n.tr("settings.moveTicked.subtitle", locale))
                        .font(BasketFont.bodyMedium)
                        .foregroundColor(BasketColor.onSurfaceVariant)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .tint(BasketColor.primary)
            .frame(minHeight: BasketSpacing.rowMinHeight)
            .listRowBackground(BasketColor.surfaceContainerLow)

            NavigationLink(value: Route.categories) {
                Text(L10n.tr("settings.categories", locale))
                    .font(BasketFont.bodyLarge)
                    .foregroundColor(BasketColor.onSurface)
                    .frame(minHeight: BasketSpacing.touchTarget)
            }
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.lists")
        }
    }

    private var catalogSection: some View {
        Section {
            Button {
                refreshCatalog()
            } label: {
                HStack(spacing: BasketSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr("settings.refreshCatalog", locale))
                            .font(BasketFont.bodyLarge)
                            .foregroundColor(BasketColor.onSurface)
                        Text(lastUpdatedText)
                            .font(BasketFont.bodyMedium)
                            .foregroundColor(BasketColor.onSurfaceVariant)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if isRefreshing {
                        ProgressView()
                            .tint(BasketColor.primary)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(BasketColor.primary)
                            .accessibilityHidden(true)
                    }
                }
                .frame(minHeight: BasketSpacing.rowMinHeight)
                .contentShape(Rectangle())
            }
            .disabled(isRefreshing)
            .accessibilityValue(isRefreshing ? L10n.tr("settings.refreshing", locale) : "")
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.catalog")
        }
    }

    private var resetSection: some View {
        Section {
            Button {
                isResetAlertPresented = true
            } label: {
                Text(L10n.tr("settings.reset", locale))
                    .font(BasketFont.bodyLarge)
                    .foregroundColor(BasketColor.error)
                    .frame(maxWidth: .infinity, minHeight: BasketSpacing.touchTarget, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .listRowBackground(BasketColor.surfaceContainerLow)
        }
    }

    private var aboutSection: some View {
        Section {
            Text(L10n.format("settings.version", locale, appVersion))
                .font(BasketFont.bodyLarge)
                .foregroundColor(BasketColor.onSurface)
                .frame(minHeight: BasketSpacing.touchTarget)
                .listRowBackground(BasketColor.surfaceContainerLow)

            Link(destination: Self.catalogWebsite) {
                HStack(spacing: BasketSpacing.md) {
                    Text(L10n.tr("settings.productData", locale))
                        .font(BasketFont.bodyLarge)
                        .foregroundColor(BasketColor.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "globe")
                        .foregroundColor(BasketColor.onSurfaceVariant)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: BasketSpacing.touchTarget)
                .contentShape(Rectangle())
            }
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.about")
        }
    }

    private func sectionHeader(_ key: String) -> some View {
        Text(L10n.tr(key, locale))
            .font(BasketFont.titleSmall)
            .foregroundColor(BasketColor.primary)
            .textCase(nil)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Values

    private func themeName(_ mode: BasketThemeMode) -> String {
        switch mode {
        case .system:
            return L10n.tr("settings.theme.system", locale)
        case .light:
            return L10n.tr("settings.theme.light", locale)
        case .dark:
            return L10n.tr("settings.theme.dark", locale)
        }
    }

    private func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return L10n.tr("settings.language.system", locale)
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .arabic:
            return "العربية"
        }
    }

    private var lastUpdatedText: String {
        guard let lastUpdated else {
            return L10n.tr("settings.notUpdated", locale)
        }
        return L10n.format("settings.lastUpdated", locale, BasketRules.formatUpdated(lastUpdated, locale: locale))
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    }

    // MARK: - Actions

    private func refreshCatalog() {
        guard !isRefreshing else { return }
        isRefreshing = true
        let toastCenter = toast
        let language = locale
        Task {
            do {
                let products = try await CatalogService.shared.fetchGroceries()
                CatalogMemoryCache.shared.update(products)
                lastUpdated = CatalogMemoryCache.shared.lastUpdated
                toastCenter.show(L10n.tr("settings.catalogUpdated", language))
            } catch {
                let message = CatalogError(error) == .offline
                    ? L10n.tr("settings.error.offline", language)
                    : L10n.tr("settings.error.server", language)
                toastCenter.show(message)
            }
            isRefreshing = false
        }
    }

    private func resetSampleData() {
        store.resetSampleData()
        router.popToRoot()
    }
}
