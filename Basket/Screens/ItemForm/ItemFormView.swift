import SwiftUI

/// Screen 3 — add an item by hand, or edit any item on the list.
@MainActor struct ItemFormView: View {
    @StateObject private var viewModel: ItemFormViewModel
    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @FocusState private var focusedField: Field?
    @State private var isConfirmingDiscard = false
    @State private var isEnteringQuantity = false
    @State private var quantityEntry = ""

    private enum Field: Hashable {
        case name, price, note
    }

    init(listId: UUID, itemId: UUID?) {
        _viewModel = StateObject(wrappedValue: ItemFormViewModel(listId: listId, itemId: itemId, store: .shared, toast: .shared))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BasketSpacing.lg) {
                nameField
                quantityField
                priceField
                categoryField
                noteField
            }
            .padding(BasketSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .alert(duplicateTitle, isPresented: duplicateBinding, presenting: viewModel.duplicate) { existing in
                Button(L10n.format("form.duplicate.addMore", locale, viewModel.quantity)) {
                    viewModel.addMore(to: existing, locale: locale) {
                        router.pop()
                    }
                }
                Button(L10n.tr("common.cancel", locale), role: .cancel) { }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(BasketColor.surface.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            saveBar
        }
        .navigationTitle(viewModel.isEditing ? L10n.tr("form.editTitle", locale) : L10n.tr("form.addTitle", locale))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel(L10n.tr("common.close", locale))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isEditing {
                    Button { deleteItem() } label: {
                        Image(systemName: "trash")
                            .foregroundColor(BasketColor.error)
                            .accessibilityHidden(true)
                    }
                    .tint(BasketColor.error)
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.tr("common.done", locale)) {
                    focusedField = nil
                }
            }
        }
        .onAppear {
            viewModel.load(locale: locale)
        }
        .task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            await MainActor.run {
                if !viewModel.isEditing && viewModel.name.isEmpty {
                    focusedField = .name
                }
            }
        }
        .onChange(of: viewModel.name) { newValue in
            viewModel.nameChanged(newValue)
        }
        .onChange(of: viewModel.note) { newValue in
            viewModel.noteChanged(newValue)
        }
        .alert(L10n.tr("form.discard.title", locale), isPresented: $isConfirmingDiscard) {
            Button(L10n.tr("common.keepEditing", locale), role: .cancel) { }
            Button(L10n.tr("common.discard", locale), role: .destructive) {
                router.pop()
            }
        }
    }

    // MARK: - Name

    private var nameField: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            TextField(L10n.tr("form.namePlaceholder", locale), text: $viewModel.name)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.next)
                .focused($focusedField, equals: .name)
                .onSubmit {
                    focusedField = .price
                }
                .accessibilityLabel(L10n.tr("form.name", locale))
                .modifier(OutlinedFieldStyle(label: L10n.tr("form.name", locale),
                                             isError: viewModel.showsNameError,
                                             isFocused: focusedField == .name))

            HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.sm) {
                if viewModel.showsNameError {
                    errorText(L10n.tr("form.nameError", locale))
                }
                Spacer(minLength: 0)
                counterText(count: viewModel.name.count, max: BasketRules.maxItemNameLength)
            }
            .padding(.horizontal, BasketSpacing.lg)

            if focusedField == .name {
                suggestionList
            }
        }
    }

    @ViewBuilder
    private var suggestionList: some View {
        let suggestions = viewModel.suggestions()
        if !suggestions.isEmpty {
            VStack(spacing: 0) {
                ForEach(suggestions) { suggestion in
                    Button {
                        viewModel.applySuggestion(suggestion)
                        focusedField = nil
                    } label: {
                        HStack(spacing: BasketSpacing.md) {
                            Image(systemName: suggestion.product == nil ? "list.bullet" : "storefront")
                                .foregroundColor(BasketColor.secondary)
                                .accessibilityHidden(true)
                            Text(suggestion.name)
                                .font(BasketFont.bodyLarge)
                                .foregroundColor(BasketColor.onSurface)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, BasketSpacing.lg)
                        .frame(minHeight: BasketSpacing.touchTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(L10n.tr("form.suggestion.hint", locale))

                    if suggestion.id != suggestions.last?.id {
                        Rectangle()
                            .fill(BasketColor.outlineVariant)
                            .frame(height: 1)
                            .padding(.leading, BasketSpacing.lg)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous)
                    .fill(BasketColor.surfaceContainerHigh)
            )
        }
    }

    // MARK: - Quantity

    @ViewBuilder
    private var quantityField: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BasketSpacing.sm) {
                quantityLabel
                quantityStepper
            }
        } else {
            HStack(spacing: BasketSpacing.md) {
                quantityLabel
                Spacer(minLength: BasketSpacing.sm)
                quantityStepper
            }
        }
    }

    private var quantityLabel: some View {
        Text(L10n.tr("form.quantity", locale))
            .font(BasketFont.bodyLarge)
            .foregroundColor(BasketColor.onSurface)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var quantityStepper: some View {
        QuantityStepper(value: viewModel.quantity,
                        canDecrement: true,
                        canIncrement: true,
                        style: .full,
                        onDecrement: { viewModel.quantity -= 1 },
                        onIncrement: { viewModel.quantity += 1 },
                        onValueTap: {
                            quantityEntry = String(viewModel.quantity)
                            isEnteringQuantity = true
                        })
            .alert(L10n.tr("form.quantity", locale), isPresented: $isEnteringQuantity) {
                TextField(L10n.tr("form.quantity", locale), text: $quantityEntry)
                    .keyboardType(.numberPad)
                Button(L10n.tr("common.cancel", locale), role: .cancel) { }
                Button(L10n.tr("form.quantityEntry.ok", locale)) {
                    viewModel.quantity = Int(quantityEntry) ?? viewModel.quantity
                }
            }
    }

    // MARK: - Price

    private var priceField: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            HStack(spacing: BasketSpacing.sm) {
                Text(BasketRules.currencySymbol(locale: locale))
                    .font(BasketFont.bodyLarge)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .accessibilityHidden(true)
                TextField(BasketRules.formatPriceInput(199, locale: locale), text: $viewModel.priceText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .price)
                    .accessibilityLabel(L10n.tr("form.price", locale))
            }
            .modifier(OutlinedFieldStyle(label: L10n.tr("form.price", locale),
                                         isError: viewModel.showsPriceError,
                                         isFocused: focusedField == .price))

            Group {
                if viewModel.showsPriceError {
                    errorText(L10n.format("form.priceError", locale,
                                          BasketRules.formatMoney(BasketRules.minPriceCents, locale: locale),
                                          BasketRules.formatMoney(BasketRules.maxPriceCents, locale: locale)))
                }

                if let parts = viewModel.lineTotalParts(locale: locale) {
                    (Text(parts.calculation + " ") + Text(parts.total).bold())
                        .font(BasketFont.Money.small)
                        .foregroundColor(BasketColor.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, BasketSpacing.lg)
        }
    }

    // MARK: - Category

    private var categoryField: some View {
        let selected = viewModel.selectedCategory

        return Menu {
            ForEach(store.categories) { category in
                Button {
                    viewModel.categoryId = category.id
                } label: {
                    if category.id == viewModel.categoryId {
                        Label(menuTitle(for: category), systemImage: "checkmark")
                    } else {
                        Text(menuTitle(for: category))
                    }
                }
                .accessibilityLabel(category.name)
            }
        } label: {
            HStack(spacing: BasketSpacing.md) {
                if let emoji = selected?.emoji {
                    Text(emoji)
                        .accessibilityHidden(true)
                }
                Text(selected?.name ?? "")
                    .foregroundColor(BasketColor.onSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: BasketSpacing.sm)
                Image(systemName: "chevron.down")
                    .font(BasketFont.labelLarge)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .modifier(OutlinedFieldStyle(label: L10n.tr("form.category", locale),
                                         isError: false,
                                         isFocused: false))
        }
        .accessibilityLabel(L10n.tr("form.category", locale))
        .accessibilityValue(selected?.name ?? "")
    }

    private func menuTitle(for category: ItemCategory) -> String {
        if let emoji = category.emoji {
            return emoji + " " + category.name
        }
        return category.name
    }

    // MARK: - Note

    private var noteField: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            TextField(L10n.tr("form.notePlaceholder", locale), text: $viewModel.note)
                .submitLabel(.done)
                .focused($focusedField, equals: .note)
                .onSubmit {
                    focusedField = nil
                }
                .accessibilityLabel(L10n.tr("form.note", locale))
                .modifier(OutlinedFieldStyle(label: L10n.tr("form.note", locale),
                                             isError: false,
                                             isFocused: focusedField == .note))

            HStack {
                Spacer(minLength: 0)
                counterText(count: viewModel.note.count, max: BasketRules.maxNoteLength)
            }
            .padding(.horizontal, BasketSpacing.lg)
        }
    }

    // MARK: - Save bar

    private var saveBar: some View {
        Button {
            focusedField = nil
            viewModel.save(locale: locale) {
                router.push(.listDetail(viewModel.listId))
            }
        } label: {
            ZStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(BasketColor.onPrimary)
                        .accessibilityLabel(L10n.tr("form.saving", locale))
                } else {
                    Text(saveTitle)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!viewModel.canSave)
        .padding(.horizontal, BasketSpacing.lg)
        .padding(.top, BasketSpacing.sm)
        .padding(.bottom, BasketSpacing.sm)
        .background(BasketColor.surface.ignoresSafeArea(edges: .bottom))
    }

    private var saveTitle: String {
        if viewModel.isEditing {
            return L10n.tr("form.saveChanges", locale)
        }
        return L10n.format("form.addTo", locale, viewModel.listName)
    }

    // MARK: - Dialogs

    private var duplicateTitle: String {
        L10n.format("form.duplicate.title", locale, viewModel.duplicate?.name ?? "")
    }

    private var duplicateBinding: Binding<Bool> {
        Binding(
            get: { viewModel.duplicate != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.duplicate = nil
                }
            }
        )
    }

    // MARK: - Actions

    private func close() {
        focusedField = nil
        if viewModel.hasChanges {
            isConfirmingDiscard = true
        } else {
            router.pop()
        }
    }

    private func deleteItem() {
        guard let itemId = viewModel.itemId else { return }
        let basketStore = store
        if let removed = basketStore.deleteItem(id: itemId) {
            router.pop()
            toast.show(L10n.format("form.removed", locale, removed.name),
                       actionTitle: L10n.tr("common.undo", locale)) {
                basketStore.restoreItem(removed)
            }
        }
    }

    // MARK: - Small pieces

    private func errorText(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(BasketFont.labelMedium)
                .accessibilityHidden(true)
            Text(text)
                .font(BasketFont.bodySmall)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(BasketColor.error)
    }

    private func counterText(count: Int, max: Int) -> some View {
        Text(String(count) + "/" + String(max))
            .font(BasketFont.labelSmall)
            .monospacedDigit()
            .foregroundColor(BasketColor.onSurfaceVariant)
    }
}

/// Outlined field with its label sitting on the top border, as in the item form mockup.
private struct OutlinedFieldStyle: ViewModifier {
    let label: String
    let isError: Bool
    let isFocused: Bool

    private var borderColor: Color {
        if isError {
            return BasketColor.error
        }
        return isFocused ? BasketColor.primary : BasketColor.outline
    }

    private var labelColor: Color {
        if isError {
            return BasketColor.error
        }
        return isFocused ? BasketColor.primary : BasketColor.onSurfaceVariant
    }

    func body(content: Content) -> some View {
        content
            .font(BasketFont.bodyLarge)
            .foregroundColor(BasketColor.onSurface)
            .padding(.horizontal, BasketSpacing.lg)
            .padding(.vertical, BasketSpacing.md)
            .frame(minHeight: 56)
            .overlay(
                RoundedRectangle(cornerRadius: BasketShape.small, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isError || isFocused ? 2 : 1)
            )
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(BasketFont.bodySmall)
                    .foregroundColor(labelColor)
                    .lineLimit(1)
                    .padding(.horizontal, BasketSpacing.xs)
                    .background(BasketColor.surface)
                    .padding(.leading, BasketSpacing.md)
                    .alignmentGuide(.top) { dimensions in dimensions[VerticalAlignment.center] }
                    .accessibilityHidden(true)
            }
            .padding(.top, BasketSpacing.sm)
    }
}
