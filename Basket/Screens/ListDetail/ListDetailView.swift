import SwiftUI

/// Screen 2 — one list grouped by aisle, with totals, share and the end-of-trip actions.
@MainActor struct ListDetailView: View {
    let listId: UUID

    @StateObject private var viewModel: ListDetailViewModel
    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.locale) private var locale
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var isRenaming = false
    @State private var isFinishing = false
    @State private var shareContent: ShareContent? = nil

    init(listId: UUID) {
        self.listId = listId
        _viewModel = StateObject(wrappedValue: ListDetailViewModel(listId: listId, store: .shared, toast: .shared))
    }

    var body: some View {
        if let list = store.list(id: listId) {
            content(for: list)
        } else {
            BasketColor.surface
                .ignoresSafeArea()
        }
    }

    // MARK: - Content

    private func content(for list: ShoppingList) -> some View {
        let sections = viewModel.sections(for: list, categories: store.categories)
        let progress = BasketRules.progress(for: list.items)

        return Group {
            if list.items.isEmpty {
                EmptyStateView(systemImage: "basket", title: L10n.tr("detail.empty", locale))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                itemList(list: list, sections: sections)
            }
        }
        .background(BasketColor.surface.ignoresSafeArea())
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    presentShare(for: list)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityHidden(true)
                }

                Menu {
                    Button {
                        isRenaming = true
                    } label: {
                        Label(L10n.tr("common.rename", locale), systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        viewModel.clearBasket(listId: list.id)
                    } label: {
                        Label(L10n.tr("detail.clearBasket", locale), systemImage: "trash")
                    }
                    .disabled(progress.ticked == 0)

                    Button {
                        isFinishing = true
                    } label: {
                        Label(L10n.tr("detail.finishShopping", locale), systemImage: "checkmark.circle")
                    }
                    .disabled(list.items.isEmpty)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel(L10n.tr("common.more", locale))
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar(list: list, progress: progress)
        }
        .sheet(isPresented: $isRenaming) {
            NameEntrySheet(title: L10n.tr("detail.rename.title", locale),
                           placeholder: L10n.tr("detail.rename.placeholder", locale),
                           confirmTitle: L10n.tr("common.save", locale),
                           initialText: list.name,
                           maxLength: BasketRules.maxListNameLength,
                           validate: { _ in nil },
                           onConfirm: { name in
                               viewModel.rename(listId: list.id, to: name)
                           })
                .environment(\.locale, locale)
        }
        .sheet(isPresented: $isFinishing) {
            FinishShoppingSheet(list: list, onKeepRest: {
                viewModel.finishShopping(listId: list.id, locale: locale)
            })
            .environment(\.locale, locale)
        }
        .sheet(item: $shareContent) {
            ShareSheet(items: [$0.text])
                .presentationDetents([.medium, .large])
        }
    }

    private func itemList(list: ShoppingList, sections: BasketRules.ListSections) -> some View {
        List {
            ForEach(sections.toBuy) { section in
                Section {
                    ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                        row(item: item, index: index, list: list)
                    }
                } header: {
                    aisleHeader(section)
                }
            }

            if !sections.inBasket.isEmpty {
                Section {
                    if viewModel.isBasketExpanded {
                        ForEach(Array(sections.inBasket.enumerated()), id: \.element.id) { index, item in
                            row(item: item, index: index, list: list)
                        }
                    }
                } header: {
                    inBasketHeader(count: sections.inBasket.count)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BasketColor.surface)
    }

    private func row(item: ListItem, index: Int, list: ShoppingList) -> some View {
        ItemRow(item: item,
                onToggle: { store.setTicked(itemId: item.id, !item.isTicked) },
                onEdit: { router.push(.itemForm(listId: list.id, itemId: item.id)) },
                onRemove: { viewModel.remove(item, locale: locale) })
            .listRowBackground(Color.white)
            .listRowInsets(EdgeInsets(top: 0, leading: BasketSpacing.xs, bottom: 0, trailing: BasketSpacing.lg))
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    viewModel.remove(at: index, in: list, locale: locale)
                } label: {
                    Label(L10n.tr("common.delete", locale), systemImage: "trash")
                }
            }
    }

    private func aisleHeader(_ section: BasketRules.ItemSection) -> some View {
        HStack(spacing: BasketSpacing.sm) {
            if let emoji = section.category.emoji {
                Text(emoji)
                    .font(BasketFont.titleSmall)
                    .accessibilityHidden(true)
            }
            Text(L10n.format("detail.sectionHeader", locale, section.category.name, section.items.count))
                .font(BasketFont.titleSmall)
                .foregroundColor(BasketColor.secondary)
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.leading, BasketSpacing.xs)
    }

    private func inBasketHeader(count: Int) -> some View {
        let isExpanded = viewModel.isBasketExpanded
        let collapsedAngle: Double = layoutDirection == .rightToLeft ? 90 : -90

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.isBasketExpanded.toggle()
            }
        } label: {
            HStack(spacing: BasketSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(BasketColor.success)
                    .accessibilityHidden(true)
                Text(L10n.format("detail.inBasketHeader", locale, count))
                    .font(BasketFont.titleSmall)
                    .foregroundColor(BasketColor.onSurface)
                    .textCase(nil)
                Spacer(minLength: BasketSpacing.sm)
                Image(systemName: "chevron.down")
                    .font(BasketFont.labelLarge)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .rotationEffect(.degrees(isExpanded ? 0 : collapsedAngle))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: BasketSpacing.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? L10n.tr("detail.expanded", locale) : L10n.tr("detail.collapsed", locale))
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Bottom bar

    private func bottomBar(list: ShoppingList, progress: BasketRules.Progress) -> some View {
        let totals = viewModel.totals(for: list)

        return VStack(spacing: 0) {
            Rectangle()
                .fill(BasketColor.outlineVariant)
                .frame(height: 1)

            VStack(spacing: BasketSpacing.md) {
                if !list.items.isEmpty {
                    TotalsFooter(totalCents: totals.total, inBasketCents: totals.inBasket)
                }

                if progress.isDone {
                    Button {
                        isFinishing = true
                    } label: {
                        Label(L10n.tr("detail.finishShopping", locale), systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                actionButtons(listId: list.id)
            }
            .padding(.horizontal, BasketSpacing.lg)
            .padding(.top, BasketSpacing.md)
            .padding(.bottom, BasketSpacing.sm)
        }
        .background(BasketColor.surface.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private func actionButtons(listId: UUID) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: BasketSpacing.sm) {
                addButton(listId: listId)
                    .buttonStyle(PrimaryButtonStyle())
                browseButton(listId: listId)
            }
        } else {
            HStack(spacing: BasketSpacing.md) {
                browseButton(listId: listId)
                addButton(listId: listId)
                    .buttonStyle(FloatingButtonStyle())
                    .layoutPriority(1)
            }
        }
    }

    private func browseButton(listId: UUID) -> some View {
        Button {
            router.push(.browse(listId: listId))
        } label: {
            Label(L10n.tr("detail.browse", locale), systemImage: "storefront")
        }
        .buttonStyle(TonalButtonStyle())
    }

    private func addButton(listId: UUID) -> some View {
        Button {
            router.push(.itemForm(listId: listId, itemId: nil))
        } label: {
            Label(L10n.tr("detail.addItem", locale), systemImage: "plus")
        }
    }

    // MARK: - Share

    private func presentShare(for list: ShoppingList) {
        shareContent = ShareContent(text: viewModel.shareText(for: list, categories: store.categories, locale: locale))
    }
}

private struct ShareContent: Identifiable {
    let id = UUID()
    let text: String
}
