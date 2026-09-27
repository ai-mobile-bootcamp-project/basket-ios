import SwiftUI

/// Screen 4: the grocery catalog, adding products straight into the open list.
@MainActor
struct BrowseView: View {
    let listId: UUID

    @StateObject private var viewModel: BrowseViewModel
    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.locale) private var locale

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(listId: UUID) {
        self.listId = listId
        _viewModel = StateObject(wrappedValue: BrowseViewModel(listId: listId, store: .shared, toast: .shared))
    }

    private var listName: String {
        store.list(id: listId)?.name ?? ""
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BasketColor.surface.ignoresSafeArea())
            .navigationTitle(L10n.tr("browse.title", locale))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    titleView
                }
            }
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search groceries"
            )
            .onChange(of: viewModel.query) { newValue in
                viewModel.queryChanged(newValue)
            }
            .onAppear {
                viewModel.loadIfNeeded()
            }
    }

    private var titleView: some View {
        VStack(spacing: 0) {
            Text(L10n.tr("browse.title", locale))
                .font(BasketFont.titleMedium)
                .foregroundColor(BasketColor.onSurface)
            Text(L10n.format("browse.subtitle", locale, listName))
                .font(BasketFont.labelMedium)
                .foregroundColor(BasketColor.onSurfaceVariant)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: States

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            loadingContent
        case .loaded:
            loadedContent
        case .failed(let error):
            failedContent(error)
        }
    }

    private var loadingContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BasketSpacing.md) {
                chipsRow
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<6, id: \.self) { _ in
                        ProductCardSkeleton()
                    }
                }
                .padding(.horizontal, BasketSpacing.lg)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.tr("browse.loading", locale))
            }
            .padding(.vertical, BasketSpacing.sm)
        }
    }

    private var loadedContent: some View {
        let products = viewModel.visibleProducts
        let items = store.list(id: listId)?.items ?? []
        return VStack(spacing: 0) {
            if viewModel.isShowingSavedCopy {
                offlineBanner
            }
            ScrollView {
                VStack(alignment: .leading, spacing: BasketSpacing.md) {
                    chipsRow
                    if products.isEmpty {
                        noResultsView
                    } else {
                        Text(L10n.format("browse.productCount", locale, products.count))
                            .font(BasketFont.labelLarge)
                            .foregroundColor(BasketColor.onSurfaceVariant)
                            .padding(.horizontal, BasketSpacing.lg)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(products) { product in
                                card(for: product, items: items)
                            }
                        }
                        .padding(.horizontal, BasketSpacing.lg)
                    }
                }
                .padding(.vertical, BasketSpacing.sm)
                .padding(.bottom, BasketSpacing.xl)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private func failedContent(_ error: CatalogError) -> some View {
        EmptyStateView(
            systemImage: error == .offline ? "wifi.slash" : "exclamationmark.triangle.fill",
            title: L10n.tr("browse.cantLoad", locale),
            message: L10n.tr(error == .offline ? "browse.offlineMessage" : "browse.serverMessage", locale),
            actionTitle: L10n.tr("common.retry", locale)
        ) {
            Task { await viewModel.refresh() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        EmptyStateView(
            systemImage: "magnifyingglass",
            title: L10n.format("browse.noResults", locale, noResultsTerm),
            actionTitle: L10n.tr("browse.clearSearch", locale)
        ) {
            viewModel.clearFilters()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, BasketSpacing.xl)
    }

    private var noResultsTerm: String {
        let trimmed = viewModel.query.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            return trimmed
        }
        if let category = viewModel.selectedCategory {
            return L10n.tr("category." + category.rawValue, locale)
        }
        return ""
    }

    // MARK: Offline banner

    private var offlineBanner: some View {
        HStack(spacing: BasketSpacing.md) {
            Image(systemName: "wifi.slash")
                .font(BasketFont.titleMedium)
                .accessibilityHidden(true)
            Text(L10n.format("browse.offlineBanner", locale, savedDateText))
                .font(BasketFont.bodyMedium)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Text(L10n.tr("common.retry", locale))
                    .font(BasketFont.labelLarge)
                    .foregroundColor(BasketColor.onWarningContainer)
                    .padding(.horizontal, BasketSpacing.sm)
                    .frame(minWidth: BasketSpacing.touchTarget, minHeight: BasketSpacing.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(BasketColor.onWarningContainer)
        .padding(.leading, BasketSpacing.lg)
        .padding(.trailing, BasketSpacing.sm)
        .padding(.vertical, BasketSpacing.xs)
        .background(BasketColor.warningContainer)
    }

    private var savedDateText: String {
        guard let date = viewModel.savedAt else { return "" }
        let formatter = DateFormatter()
        formatter.locale = BasketRules.latinDigitsLocale(locale)
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    // MARK: Chips

    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BasketSpacing.sm) {
                chip(label: Text(verbatim: "All"), isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(DefaultCategory.browseChips, id: \.self) { category in
                    chip(
                        label: Text(L10n.tr("category." + category.rawValue, locale)),
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, BasketSpacing.lg)
        }
    }

    private func chip(label: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: BasketSpacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(BasketFont.labelMedium)
                        .accessibilityHidden(true)
                }
                label
                    .font(BasketFont.labelLarge)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? BasketColor.onPrimaryContainer : BasketColor.onSurfaceVariant)
            .padding(.horizontal, BasketSpacing.md)
            .padding(.vertical, 6)
            .frame(minHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous)
                    .fill(isSelected ? BasketColor.primaryContainer : Color.clear)
            )
            .overlay {
                RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous)
                    .stroke(isSelected ? Color.clear : BasketColor.outline, lineWidth: 1)
            }
            .frame(minHeight: BasketSpacing.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: Cards

    private func card(for product: CatalogProduct, items: [ListItem]) -> some View {
        let existing = items.first(where: { $0.catalogProductId == product.id })
        return ProductCard(
            product: product,
            quantityOnList: existing?.quantity,
            onOpen: {
                router.push(.productDetail(listId: listId, product: product))
            },
            onAdd: {
                viewModel.add(product, locale: locale)
            },
            onIncrement: {
                viewModel.add(product, locale: locale)
            },
            onDecrement: {
                if let existing = existing {
                    viewModel.decrement(existing, product: product, locale: locale)
                }
            }
        )
    }
}
