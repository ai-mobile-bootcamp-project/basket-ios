import SwiftUI

/// Screen 3 — add an item by hand, or edit any item on the list.
@MainActor struct ItemFormView: View {
    @StateObject private var viewModel: ItemFormViewModel
    @EnvironmentObject private var store: BasketStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var toast: ToastCenter
    @Environment(\.locale) private var locale

    @FocusState private var focusedField: Field?
    @State private var isConfirmingDiscard = false

    private enum Field: Hashable {
        case name, quantity, price, note
    }

    init(listId: UUID, itemId: UUID?) {
        _viewModel = StateObject(wrappedValue: ItemFormViewModel(listId: listId, itemId: itemId, store: .shared, toast: .shared))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BasketSpacing.xl) {
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
                    Button { deleteItem() } label: { Image(systemName: "trash").accessibilityHidden(true) }
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
            fieldLabel(L10n.tr("form.name", locale))

            TextField(L10n.tr("form.namePlaceholder", locale), text: $viewModel.name)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.next)
                .focused($focusedField, equals: .name)
                .onSubmit {
                    focusedField = .price
                }
                .modifier(FormFieldStyle(isError: viewModel.showsNameError))
                .accessibilityLabel(L10n.tr("form.name", locale))

            HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.sm) {
                if viewModel.showsNameError {
                    errorText(L10n.tr("form.nameError", locale))
                }
                Spacer(minLength: 0)
                counterText(count: viewModel.name.count, max: BasketRules.maxItemNameLength)
            }

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
                            Image(systemName: suggestion.product == nil ? "list.bullet" : "tag")
                                .foregroundColor(BasketColor.secondary)
                                .accessibilityHidden(true)
                            Text(suggestion.name)
                                .font(BasketFont.bodyLarge)
                                .foregroundColor(BasketColor.onSurface)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, BasketSpacing.md)
                        .frame(minHeight: BasketSpacing.touchTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(L10n.tr("form.suggestion.hint", locale))

                    if suggestion.id != suggestions.last?.id {
                        Rectangle()
                            .fill(BasketColor.outlineVariant)
                            .frame(height: 1)
                            .padding(.leading, BasketSpacing.md)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                    .fill(BasketColor.surfaceContainerHigh)
            )
        }
    }

    // MARK: - Quantity

    private var quantityField: some View {
        Stepper(value: $viewModel.quantity) {
            HStack(spacing: BasketSpacing.md) {
                Text(L10n.tr("form.quantity", locale))
                    .font(BasketFont.bodyLarge)
                    .foregroundColor(BasketColor.onSurface)
                TextField(L10n.tr("form.quantity", locale), text: quantityText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .font(BasketFont.Money.body)
                    .frame(width: 64)
                    .focused($focusedField, equals: .quantity)
            }
        }
        .padding(.horizontal, BasketSpacing.md)
        .frame(minHeight: BasketSpacing.rowMinHeight)
        .background(
            RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                .fill(BasketColor.surfaceContainerLow)
        )
    }

    private var quantityText: Binding<String> {
        Binding(
            get: { String(viewModel.quantity) },
            set: { newValue in viewModel.quantity = Int(newValue) ?? viewModel.quantity }
        )
    }

    // MARK: - Price

    private var priceField: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            fieldLabel(L10n.tr("form.price", locale))

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
            .modifier(FormFieldStyle(isError: viewModel.showsPriceError))

            if viewModel.showsPriceError {
                errorText(L10n.format("form.priceError", locale,
                                      BasketRules.formatMoney(BasketRules.minPriceCents, locale: locale),
                                      BasketRules.formatMoney(BasketRules.maxPriceCents, locale: locale)))
            }

            if let lineTotal = viewModel.lineTotalText(locale: locale) {
                Text(lineTotal)
                    .font(BasketFont.Money.small)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Category

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            fieldLabel(L10n.tr("form.category", locale))

            Picker(L10n.tr("form.category", locale), selection: $viewModel.categoryId) {
                ForEach(store.categories) { category in
                    Text(category.name)
                        .tag(Optional(category.id))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(FormFieldStyle(isError: false))
        }
    }

    // MARK: - Note

    private var noteField: some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            fieldLabel(L10n.tr("form.note", locale))

            TextField(L10n.tr("form.notePlaceholder", locale), text: $viewModel.note)
                .submitLabel(.done)
                .focused($focusedField, equals: .note)
                .onSubmit {
                    focusedField = nil
                }
                .modifier(FormFieldStyle(isError: false))
                .accessibilityLabel(L10n.tr("form.note", locale))

            HStack {
                Spacer(minLength: 0)
                counterText(count: viewModel.note.count, max: BasketRules.maxNoteLength)
            }
        }
    }

    // MARK: - Save bar

    private var saveBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(BasketColor.outlineVariant)
                .frame(height: 1)

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
            .padding(.top, BasketSpacing.md)
            .padding(.bottom, BasketSpacing.sm)
        }
        .background(BasketColor.surfaceContainerLow.ignoresSafeArea(edges: .bottom))
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

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(BasketFont.labelLarge)
            .foregroundColor(BasketColor.onSurfaceVariant)
            .accessibilityHidden(true)
    }

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

/// Outlined text-field container used by the item form.
private struct FormFieldStyle: ViewModifier {
    let isError: Bool

    func body(content: Content) -> some View {
        content
            .font(BasketFont.bodyLarge)
            .foregroundColor(BasketColor.onSurface)
            .padding(.horizontal, BasketSpacing.md)
            .padding(.vertical, BasketSpacing.sm)
            .frame(minHeight: BasketSpacing.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                    .fill(BasketColor.surfaceContainerLow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                    .stroke(isError ? BasketColor.error : BasketColor.outline, lineWidth: isError ? 2 : 1)
            )
    }
}
