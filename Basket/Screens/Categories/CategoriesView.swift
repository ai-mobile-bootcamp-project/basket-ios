import SwiftUI

/// The aisle order that groups every list. "Other" is always last and locked.
@MainActor struct CategoriesView: View {
    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.locale) private var locale

    @State private var activeSheet: CategoryNameSheet? = nil

    init() {}

    var body: some View {
        List {
            Section {
                ForEach(movable) { category in
                    categoryRow(
                        category,
                        isFirst: category.id == movable.first?.id,
                        isLast: category.id == movable.last?.id
                    )
                    .listRowBackground(BasketColor.surfaceContainerLow)
                }
                .onMove { offsets, destination in
                    store.moveCategories(fromOffsets: offsets, toOffset: destination)
                }

                if let other = store.otherCategory {
                    otherRow(other)
                        .moveDisabled(true)
                        .listRowBackground(BasketColor.surfaceContainerLow)
                }
            } footer: {
                addButton
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background {
            BasketColor.surface.ignoresSafeArea()
        }
        .navigationTitle(L10n.tr("categories.title", locale))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BasketColor.surface, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                titleView
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
                .environment(\.locale, locale)
        }
    }

    // MARK: - Rows

    private var movable: [ItemCategory] {
        store.categories.filter { !$0.isOther }
    }

    private var titleView: some View {
        VStack(spacing: 0) {
            Text(L10n.tr("categories.title", locale))
                .font(BasketFont.titleMedium)
                .foregroundColor(BasketColor.onSurface)
            Text(L10n.tr("categories.subtitle", locale))
                .font(BasketFont.labelMedium)
                .foregroundColor(BasketColor.onSurfaceVariant)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func categoryRow(_ category: ItemCategory, isFirst: Bool, isLast: Bool) -> some View {
        HStack(spacing: BasketSpacing.sm) {
            rowText(category)
                .accessibilityElement(children: .combine)
                .accessibilityAction(named: L10n.tr("common.moveUp", locale)) {
                    store.moveCategory(id: category.id, by: -1)
                }
                .accessibilityAction(named: L10n.tr("common.moveDown", locale)) {
                    store.moveCategory(id: category.id, by: 1)
                }

            Menu {
                Button {
                    activeSheet = .rename(id: category.id, name: category.name)
                } label: {
                    Label(L10n.tr("common.rename", locale), systemImage: "pencil")
                }
                Button {
                    store.moveCategory(id: category.id, by: -1)
                } label: {
                    Label(L10n.tr("common.moveUp", locale), systemImage: "arrow.up")
                }
                .disabled(isFirst)
                Button {
                    store.moveCategory(id: category.id, by: 1)
                } label: {
                    Label(L10n.tr("common.moveDown", locale), systemImage: "arrow.down")
                }
                .disabled(isLast)
                Button(role: .destructive) {
                    delete(category)
                } label: {
                    Label(L10n.tr("common.delete", locale), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(BasketFont.titleMedium)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .frame(width: BasketSpacing.touchTarget, height: BasketSpacing.touchTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L10n.format("categories.moreOptions", locale, category.name))
        }
        .frame(minHeight: BasketSpacing.rowMinHeight)
    }

    private func otherRow(_ category: ItemCategory) -> some View {
        HStack(spacing: BasketSpacing.sm) {
            rowText(category)
            Image(systemName: "lock.fill")
                .font(BasketFont.bodyLarge)
                .foregroundColor(BasketColor.onSurfaceVariant)
                .frame(width: BasketSpacing.touchTarget, height: BasketSpacing.touchTarget)
                .accessibilityLabel(L10n.tr("categories.locked", locale))
        }
        .frame(minHeight: BasketSpacing.rowMinHeight)
        .accessibilityElement(children: .combine)
    }

    private func rowText(_ category: ItemCategory) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(category.name)
                .font(BasketFont.bodyLarge)
                .foregroundColor(BasketColor.onSurface)
            Text(L10n.format("categories.itemCount", locale, store.itemCount(categoryId: category.id)))
                .font(BasketFont.bodyMedium)
                .foregroundColor(BasketColor.onSurfaceVariant)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addButton: some View {
        Button {
            activeSheet = .add
        } label: {
            Label(L10n.tr("categories.add", locale), systemImage: "plus")
        }
        .buttonStyle(TonalButtonStyle())
        .padding(.top, BasketSpacing.md)
    }

    // MARK: - Sheets

    @ViewBuilder private func sheetContent(for sheet: CategoryNameSheet) -> some View {
        switch sheet {
        case .add:
            NameEntrySheet(
                title: L10n.tr("categories.add", locale),
                placeholder: L10n.tr("categories.placeholder", locale),
                confirmTitle: L10n.tr("categories.add.confirm", locale),
                initialText: "",
                maxLength: BasketRules.maxCategoryNameLength,
                validate: { text in
                    duplicateMessage(for: text, excluding: nil)
                },
                onConfirm: { name in
                    _ = store.addCategory(name: name)
                }
            )
        case .rename(let categoryId, let currentName):
            NameEntrySheet(
                title: L10n.tr("categories.rename.title", locale),
                placeholder: L10n.tr("categories.placeholder", locale),
                confirmTitle: L10n.tr("common.save", locale),
                initialText: currentName,
                maxLength: BasketRules.maxCategoryNameLength,
                validate: { text in
                    duplicateMessage(for: text, excluding: categoryId)
                },
                onConfirm: { name in
                    store.renameCategory(id: categoryId, name: name)
                }
            )
        }
    }

    private func duplicateMessage(for text: String, excluding categoryId: UUID?) -> String? {
        guard let trimmed = BasketRules.trimmedName(text) else { return nil }
        let error = BasketRules.validateCategoryName(trimmed, existing: store.categories, excluding: categoryId)
        if error == .duplicate {
            return L10n.format("categories.exists", locale, trimmed)
        }
        return nil
    }

    // MARK: - Actions

    private func delete(_ category: ItemCategory) {
        let basketStore = store
        if let removed = basketStore.deleteCategory(id: category.id) {
            toast.show(L10n.format("categories.deleted", locale, removed.name), actionTitle: L10n.tr("common.undo", locale)) {
                basketStore.restoreCategory(removed)
            }
        }
    }
}

private enum CategoryNameSheet: Identifiable {
    case add
    case rename(id: UUID, name: String)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .rename(let categoryId, _):
            return "rename-" + categoryId.uuidString
        }
    }
}
