import SwiftUI

/// Home screen: every shopping list, most recently changed first.
@MainActor struct ListsView: View {
    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var activeSheet: ListNameSheet? = nil
    @State private var createdListId: UUID? = nil

    init() {}

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                BasketColor.surface.ignoresSafeArea()
            }
            .overlay(alignment: .bottomTrailing) {
                if !store.lists.isEmpty {
                    newListButton
                }
            }
            .navigationTitle(L10n.tr("lists.title", locale))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(BasketColor.surface, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsButton
                }
            }
            .sheet(item: $activeSheet, onDismiss: { openCreatedList() }) { sheet in
                sheetContent(for: sheet)
                    .environment(\.locale, locale)
            }
    }

    // MARK: - Content

    @ViewBuilder private var content: some View {
        if store.lists.isEmpty {
            GeometryReader { proxy in
                ScrollView {
                    EmptyStateView(
                        systemImage: "basket",
                        title: L10n.tr("lists.empty.title", locale),
                        actionTitle: L10n.tr("lists.empty.action", locale)
                    ) {
                        activeSheet = .create
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
            }
        } else {
            ScrollView {
                LazyVStack(spacing: BasketSpacing.md) {
                    ForEach(store.lists) { list in
                        ListCard(
                            list: list,
                            onOpen: { router.push(.listDetail(list.id)) },
                            onRename: { activeSheet = .rename(id: list.id, name: list.name) },
                            onDuplicate: { duplicate(list) },
                            onDelete: { delete(list) }
                        )
                    }
                }
                .padding(BasketSpacing.lg)
                .padding(.bottom, floatingButtonClearance)
                .animation(.default, value: store.lists.map(\.id))
            }
        }
    }

    private var settingsButton: some View {
        Button {
            router.push(.settings)
        } label: {
            Image(systemName: "gearshape")
                .foregroundColor(BasketColor.onSurface)
                .frame(minWidth: BasketSpacing.touchTarget, minHeight: BasketSpacing.touchTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(L10n.tr("common.settings", locale))
    }

    private var newListButton: some View {
        Button {
            activeSheet = .create
        } label: {
            Label(L10n.tr("lists.newList", locale), systemImage: "plus")
        }
        .buttonStyle(FloatingButtonStyle(tonal: true))
        .padding(BasketSpacing.lg)
    }

    private var floatingButtonClearance: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 160 : 88
    }

    @ViewBuilder private func sheetContent(for sheet: ListNameSheet) -> some View {
        switch sheet {
        case .create:
            NameEntrySheet(
                title: L10n.tr("lists.newList", locale),
                placeholder: L10n.tr("lists.namePlaceholder", locale),
                confirmTitle: L10n.tr("common.create", locale),
                initialText: "",
                maxLength: BasketRules.maxListNameLength,
                validate: { _ in nil },
                onConfirm: { name in
                    createdListId = store.createList(name: name)
                }
            )
        case .rename(let listId, let currentName):
            NameEntrySheet(
                title: L10n.tr("lists.rename.title", locale),
                placeholder: L10n.tr("lists.namePlaceholder", locale),
                confirmTitle: L10n.tr("common.save", locale),
                initialText: currentName,
                maxLength: BasketRules.maxListNameLength,
                validate: { _ in nil },
                onConfirm: { name in
                    store.renameList(id: listId, name: name)
                }
            )
        }
    }

    // MARK: - Actions

    private func openCreatedList() {
        guard let listId = createdListId else { return }
        createdListId = nil
        router.push(.listDetail(listId))
    }

    private func duplicate(_ list: ShoppingList) {
        store.duplicateList(id: list.id, name: L10n.format("lists.copyName", locale, list.name))
    }

    private func delete(_ list: ShoppingList) {
        store.deleteList(id: list.id)
        toast.show(L10n.format("lists.deleted", locale, list.name))
    }
}

private enum ListNameSheet: Identifiable {
    case create
    case rename(id: UUID, name: String)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .rename(let listId, _):
            return "rename-" + listId.uuidString
        }
    }
}
