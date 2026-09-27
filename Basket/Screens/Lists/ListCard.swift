import SwiftUI

/// One shopping list on the Lists screen: name, progress, estimated total and the overflow menu.
@MainActor struct ListCard: View {
    let list: ShoppingList
    let onOpen: () -> Void
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(list: ShoppingList,
         onOpen: @escaping () -> Void,
         onRename: @escaping () -> Void,
         onDuplicate: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.list = list
        self.onOpen = onOpen
        self.onRename = onRename
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button(action: onOpen) {
                summary
                    .padding(.leading, BasketSpacing.lg)
                    .padding(.vertical, BasketSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                actions
            } label: {
                Image(systemName: "ellipsis")
                    .font(BasketFont.titleMedium)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .frame(width: BasketSpacing.touchTarget, height: BasketSpacing.touchTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L10n.format("lists.card.moreOptions", locale, list.name))
            .padding(.top, BasketSpacing.xs)
            .padding(.trailing, BasketSpacing.xs)
        }
        .background {
            RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                .fill(BasketColor.surfaceContainerLow)
        }
        .contentShape(RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous))
        .contextMenu {
            actions
        }
    }

    // MARK: - Content

    private var summary: some View {
        let progress = BasketRules.progress(for: list.items)
        return VStack(alignment: .leading, spacing: BasketSpacing.sm) {
            if dynamicTypeSize.isAccessibilitySize {
                heading(progress)
                if !list.items.isEmpty {
                    totals(stacked: true)
                }
            } else {
                HStack(alignment: .top, spacing: BasketSpacing.md) {
                    heading(progress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !list.items.isEmpty {
                        totals(stacked: false)
                    }
                }
            }
            if progress.count > 0 {
                progressBar(progress)
            }
            if progress.isDone {
                doneLabel
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func heading(_ progress: BasketRules.Progress) -> some View {
        VStack(alignment: .leading, spacing: BasketSpacing.xs) {
            Text(list.name)
                .font(BasketFont.titleMedium)
                .foregroundColor(BasketColor.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(progressText(progress))
                .font(BasketFont.bodyMedium)
                .foregroundColor(BasketColor.onSurfaceVariant)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func totals(stacked: Bool) -> some View {
        VStack(alignment: stacked ? .leading : .trailing, spacing: 2) {
            Text(BasketRules.formatMoney(totalCents, locale: locale))
                .font(BasketFont.Money.title)
                .foregroundColor(BasketColor.onSurface)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            if missingCount > 0 {
                Text(withoutPriceText)
                    .font(BasketFont.bodySmall)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .multilineTextAlignment(stacked ? .leading : .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func progressBar(_ progress: BasketRules.Progress) -> some View {
        let ticked = progress.ticked
        let count = progress.count
        let percentInBasket = count == 0 ? 0 : Double(ticked) / Double(count) * 100
        return ProgressView(value: percentInBasket, total: 1)
            .progressViewStyle(ListCardProgressStyle())
            .accessibilityValue(String(Int(percentInBasket)) + "%")
    }

    private var doneLabel: some View {
        HStack(spacing: BasketSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .accessibilityHidden(true)
            Text(L10n.tr("lists.card.done", locale))
        }
        .font(BasketFont.labelLarge)
        .foregroundColor(BasketColor.success)
    }

    @ViewBuilder private var actions: some View {
        Button(action: onRename) {
            Label(L10n.tr("common.rename", locale), systemImage: "pencil")
        }
        Button(action: onDuplicate) {
            Label(L10n.tr("lists.duplicate", locale), systemImage: "doc.on.doc")
        }
        Button(role: .destructive, action: onDelete) {
            Label(L10n.tr("common.delete", locale), systemImage: "trash")
        }
    }

    // MARK: - Values

    private var totalCents: Int {
        list.items.compactMap(\.priceCents).reduce(0, +)
    }

    private var missingCount: Int {
        list.items.filter { $0.priceCents == nil }.count
    }

    private var withoutPriceText: String {
        "+ " + String(missingCount) + " " + L10n.tr("lists.card.itemsWithoutPrice", locale)
    }

    private func progressText(_ progress: BasketRules.Progress) -> String {
        if progress.count == 0 {
            return L10n.tr("lists.card.noItems", locale)
        }
        return L10n.format("lists.card.progress", locale, progress.ticked, progress.count)
    }
}

/// Thin rounded bar: primary fill on a primaryContainer track.
private struct ListCardProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let fraction = min(max(configuration.fractionCompleted ?? 0, 0), 1)
        return Capsule()
            .fill(BasketColor.primaryContainer)
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(BasketColor.primary)
                        .frame(width: proxy.size.width * CGFloat(fraction))
                }
            }
    }
}
