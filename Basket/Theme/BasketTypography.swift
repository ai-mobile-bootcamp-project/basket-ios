import SwiftUI

// Basket — Material 3 type scale mapped onto SwiftUI text styles. System font (SF) on iOS.
// Every style is relative to a system text style, so it scales with Dynamic Type up to the
// accessibility sizes, the same way sp scales on Android.
enum BasketFont {
    static let displaySmall   = Font.largeTitle
    static let headlineMedium = Font.title
    static let headlineSmall  = Font.title2
    static let titleLarge     = Font.title2
    static let titleMedium    = Font.callout.weight(.medium)
    static let titleSmall     = Font.subheadline.weight(.medium)
    static let bodyLarge      = Font.body
    static let bodyMedium     = Font.subheadline
    static let bodySmall      = Font.caption
    static let labelLarge     = Font.subheadline.weight(.medium)
    static let labelMedium    = Font.caption.weight(.medium)
    static let labelSmall     = Font.caption2.weight(.medium)

    /// Money styles: monospaced digits so prices and totals line up.
    enum Money {
        /// Totals footer "Total $45.84", product detail price.
        static let display = Font.title.weight(.medium).monospacedDigit()
        /// List card total, product card price.
        static let title   = Font.title2.weight(.medium).monospacedDigit()
        /// Item row line total, "6 × $1.74".
        static let body    = Font.body.monospacedDigit()
        static let small   = Font.subheadline.monospacedDigit()
    }
}

/// Line heights from the M3 scale, applied as line spacing (lineHeight − fontSize).
enum BasketLineSpacing {
    static let displaySmall: CGFloat = 8
    static let headlineMedium: CGFloat = 8
    static let titleLarge: CGFloat = 6
    static let titleMedium: CGFloat = 8
    static let bodyLarge: CGFloat = 8
    static let bodyMedium: CGFloat = 6
    static let bodySmall: CGFloat = 4
    static let labelLarge: CGFloat = 6
}
