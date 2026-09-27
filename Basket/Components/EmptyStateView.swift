import SwiftUI

/// Centered icon, title, optional message and optional primary action for empty and error states.
@MainActor struct EmptyStateView: View {
    private let systemImage: String
    private let title: String
    private let message: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 56

    init(systemImage: String, title: String, message: String? = nil, actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: BasketSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundColor(BasketColor.onSurfaceVariant)
                .padding(.bottom, BasketSpacing.xs)
                .accessibilityHidden(true)

            Text(title)
                .font(BasketFont.titleLarge)
                .foregroundColor(BasketColor.onSurface)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let message = message {
                Text(message)
                    .font(BasketFont.bodyMedium)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 360)
                .padding(.top, BasketSpacing.sm)
            }
        }
        .padding(BasketSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}
