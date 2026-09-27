import SwiftUI

/// One-field sheet used for New list, Rename list, Add category and Rename category.
@MainActor struct NameEntrySheet: View {
    private let title: String
    private let placeholder: String
    private let confirmTitle: String
    private let maxLength: Int
    private let validate: (String) -> String?
    private let onConfirm: (String) -> Void

    @State private var text: String
    @State private var didConfirm = false
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(title: String, placeholder: String, confirmTitle: String, initialText: String, maxLength: Int,
         validate: @escaping (String) -> String?,
         onConfirm: @escaping (String) -> Void) {
        self.title = title
        self.placeholder = placeholder
        self.confirmTitle = confirmTitle
        self.maxLength = maxLength
        self.validate = validate
        self.onConfirm = onConfirm
        _text = State(initialValue: String(initialText.prefix(maxLength)))
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var errorMessage: String? {
        let name = trimmed
        return name.isEmpty ? nil : validate(name)
    }

    private var canConfirm: Bool {
        !trimmed.isEmpty && errorMessage == nil && !didConfirm
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BasketSpacing.lg) {
                Text(title)
                    .font(BasketFont.titleLarge)
                    .foregroundColor(BasketColor.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: BasketSpacing.xs) {
                    field

                    HStack(alignment: .firstTextBaseline, spacing: BasketSpacing.sm) {
                        if let message = errorMessage {
                            Text(message)
                                .font(BasketFont.bodySmall)
                                .foregroundColor(BasketColor.error)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: BasketSpacing.sm)
                        Text(String(text.count) + "/" + String(maxLength))
                            .font(BasketFont.bodySmall.monospacedDigit())
                            .foregroundColor(BasketColor.onSurfaceVariant)
                    }
                    .padding(.horizontal, BasketSpacing.xs)
                }

                buttons
                    .padding(.top, BasketSpacing.sm)
            }
            .padding(.horizontal, BasketSpacing.xl)
            .padding(.top, BasketSpacing.xl)
            .padding(.bottom, BasketSpacing.lg)
        }
        .background(BasketColor.surface.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: text) { newValue in
            if newValue.count > maxLength {
                text = String(newValue.prefix(maxLength))
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                focused = true
            }
        }
    }

    private var field: some View {
        TextField(placeholder, text: $text)
            .font(BasketFont.bodyLarge)
            .foregroundColor(BasketColor.onSurface)
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .focused($focused)
            .onSubmit { confirm() }
            .padding(.horizontal, BasketSpacing.lg)
            .padding(.vertical, BasketSpacing.md)
            .frame(minHeight: BasketSpacing.rowMinHeight)
            .background(
                RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                    .fill(BasketColor.surfaceContainerLow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: focused || errorMessage != nil ? 2 : 1)
            )
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return BasketColor.error
        }
        return focused ? BasketColor.primary : BasketColor.outline
    }

    @ViewBuilder
    private var buttons: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: BasketSpacing.sm) {
                confirmButton
                cancelButton
            }
        } else {
            HStack(spacing: BasketSpacing.md) {
                cancelButton
                confirmButton
            }
        }
    }

    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text(L10n.tr("common.cancel", locale))
                .font(BasketFont.titleMedium)
                .foregroundColor(BasketColor.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BasketSpacing.lg)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var confirmButton: some View {
        Button {
            confirm()
        } label: {
            Text(confirmTitle)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canConfirm)
    }

    private func confirm() {
        guard canConfirm else { return }
        didConfirm = true
        onConfirm(trimmed)
        dismiss()
    }
}
