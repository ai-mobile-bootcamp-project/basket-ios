import SwiftUI
import UIKit

@MainActor final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    struct Toast: Identifiable, Equatable {
        let id: UUID
        let message: String
        let actionTitle: String?
        let action: (() -> Void)?

        static func == (lhs: Toast, rhs: Toast) -> Bool {
            lhs.id == rhs.id
        }
    }

    @Published private(set) var current: Toast? = nil

    private var hideTask: Task<Void, Never>?

    /// Shows a toast at the bottom of the screen, replacing any visible one. It hides itself after 5 seconds.
    func show(_ message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        hideTask?.cancel()
        let toast = Toast(id: UUID(), message: message, actionTitle: actionTitle, action: action)
        current = toast
        UIAccessibility.post(notification: .announcement, argument: message)
        let toastId = toast.id
        hideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            self?.hide(toastId)
        }
    }

    func dismiss() {
        hideTask?.cancel()
        hideTask = nil
        current = nil
    }

    private func hide(_ id: UUID) {
        guard current?.id == id else { return }
        current = nil
        hideTask = nil
    }
}

/// Bottom toast with an optional action (e.g. Undo). Placed once at the root of the app.
@MainActor struct ToastOverlay: View {
    @EnvironmentObject private var center: ToastCenter

    var body: some View {
        ZStack(alignment: .bottom) {
            if let toast = center.current {
                ToastBar(toast: toast) {
                    perform(toast)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: center.current?.id)
    }

    private func perform(_ toast: ToastCenter.Toast) {
        toast.action?()
        if center.current?.id == toast.id {
            center.dismiss()
        }
    }
}

@MainActor private struct ToastBar: View {
    let toast: ToastCenter.Toast
    let onAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: BasketSpacing.sm) {
            Text(toast.message)
                .font(BasketFont.bodyMedium)
                .foregroundColor(BasketColor.surface)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, BasketSpacing.md)

            if let actionTitle = toast.actionTitle {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(BasketFont.labelLarge)
                        .foregroundColor(BasketColor.primaryContainer)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BasketSpacing.md)
                        .frame(minWidth: BasketSpacing.touchTarget, minHeight: BasketSpacing.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, BasketSpacing.lg)
        .padding(.trailing, toast.actionTitle == nil ? BasketSpacing.lg : BasketSpacing.xs)
        .frame(minHeight: BasketSpacing.touchTarget)
        .background(
            RoundedRectangle(cornerRadius: BasketShape.medium, style: .continuous)
                .fill(BasketColor.onSurface)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .contain)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
