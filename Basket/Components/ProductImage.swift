import SwiftUI

/// Catalog product image. Shows the basket placeholder while loading and when the image cannot be loaded.
@MainActor struct ProductImage: View {
    private let url: URL?

    init(url: URL?) {
        self.url = url
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                placeholder
            case .empty:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            BasketColor.surfaceContainerHigh
            Image(systemName: "basket")
                .font(.title)
                .foregroundColor(BasketColor.onSurfaceVariant)
        }
    }
}
