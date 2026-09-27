import SwiftUI

/// Preferences: appearance, list behaviour, catalog refresh, reset and about.
@MainActor struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.locale) private var locale

    @ScaledMetric(relativeTo: .title2) private var iconColumnWidth: CGFloat = 28

    @State private var lastUpdated: Date? = nil
    @State private var isRefreshing = false
    @State private var isResetAlertPresented = false

    private static let catalogWebsite = URL(string: "https://dummyjson.com")!

    init() {}

    var body: some View {
        List {
            appearanceSection
            listsSection
            dataSection
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

    private var appearanceSection: some View {
        Section {
            Menu {
                Picker(L10n.tr("settings.theme", locale), selection: $settings.theme) {
                    ForEach(BasketThemeMode.allCases, id: \.self) { mode in
                        Text(themeName(mode))
                            .tag(mode)
                    }
                }
            } label: {
                settingsRow(
                    systemImage: "circle.lefthalf.filled",
                    title: L10n.tr("settings.theme", locale),
                    subtitle: themeName(settings.theme)
                )
            }
            .accessibilityLabel(L10n.tr("settings.theme", locale))
            .accessibilityValue(themeName(settings.theme))
            .listRowBackground(BasketColor.surfaceContainerLow)

            Menu {
                Picker(L10n.tr("settings.language", locale), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(languageName(language))
                            .tag(language)
                    }
                }
            } label: {
                settingsRow(
                    systemImage: "globe",
                    title: L10n.tr("settings.language", locale),
                    subtitle: languageName(settings.language)
                )
            }
            .accessibilityLabel(L10n.tr("settings.language", locale))
            .accessibilityValue(languageName(settings.language))
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.appearance")
        }
    }

    private var listsSection: some View {
        Section {
            Toggle(isOn: $settings.moveTickedDown) {
                settingsRow(
                    systemImage: "checklist",
                    title: L10n.tr("settings.moveTicked", locale),
                    subtitle: L10n.tr("settings.moveTicked.subtitle", locale)
                )
            }
            .tint(BasketColor.primary)
            .listRowBackground(BasketColor.surfaceContainerLow)

            NavigationLink(value: Route.categories) {
                settingsRow(
                    systemImage: "square.on.circle",
                    title: L10n.tr("settings.categories", locale),
                    subtitle: L10n.tr("settings.categories.subtitle", locale)
                )
            }
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.lists")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                refreshCatalog()
            } label: {
                HStack(spacing: BasketSpacing.md) {
                    settingsRow(
                        systemImage: "arrow.clockwise",
                        title: L10n.tr("settings.refreshCatalog", locale),
                        subtitle: lastUpdatedText
                    )
                    if isRefreshing {
                        ProgressView()
                            .tint(BasketColor.primary)
                    }
                }
                .contentShape(Rectangle())
            }
            .disabled(isRefreshing)
            .accessibilityValue(isRefreshing ? L10n.tr("settings.refreshing", locale) : "")
            .listRowBackground(BasketColor.surfaceContainerLow)

            Button {
                isResetAlertPresented = true
            } label: {
                settingsRow(
                    systemImage: "arrow.counterclockwise",
                    title: L10n.tr("settings.reset", locale),
                    subtitle: L10n.tr("settings.reset.subtitle", locale),
                    accent: BasketColor.error
                )
            }
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.data")
        }
    }

    private var aboutSection: some View {
        Section {
            settingsRow(
                systemImage: "info.circle",
                title: L10n.tr("settings.version", locale),
                subtitle: appVersion
            )
            .accessibilityElement(children: .combine)
            .listRowBackground(BasketColor.surfaceContainerLow)

            Link(destination: Self.catalogWebsite) {
                HStack(spacing: BasketSpacing.md) {
                    settingsRow(
                        systemImage: "tray.full",
                        title: L10n.tr("settings.productData", locale),
                        subtitle: L10n.tr("settings.productData.subtitle", locale)
                    )
                    Image(systemName: "arrow.up.right.square")
                        .font(BasketFont.bodyLarge)
                        .foregroundColor(BasketColor.onSurfaceVariant)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .listRowBackground(BasketColor.surfaceContainerLow)
        } header: {
            sectionHeader("settings.about")
        }
    }

    // MARK: - Rows

    /// Leading icon, title and a secondary line. `accent` colours the icon and title (Reset uses error).
    private func settingsRow(systemImage: String, title: String, subtitle: String,
                             accent: Color? = nil) -> some View {
        HStack(spacing: BasketSpacing.lg) {
            Image(systemName: systemImage)
                .font(BasketFont.titleLarge)
                .foregroundColor(accent ?? BasketColor.onSurfaceVariant)
                .frame(width: iconColumnWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BasketFont.bodyLarge)
                    .foregroundColor(accent ?? BasketColor.onSurface)
                Text(subtitle)
                    .font(BasketFont.bodyMedium)
                    .foregroundColor(BasketColor.onSurfaceVariant)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: BasketSpacing.rowMinHeight)
        .contentShape(Rectangle())
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
