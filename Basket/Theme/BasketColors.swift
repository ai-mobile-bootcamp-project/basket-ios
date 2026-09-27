import SwiftUI
import UIKit

// Basket — colour tokens named by Material 3 role, resolved per colour scheme.
// Same hex values as the Android Color.kt; keep both files in step.
struct BasketPalette {
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let secondary: Color
    let onSecondary: Color
    let secondaryContainer: Color
    let onSecondaryContainer: Color
    let tertiary: Color
    let onTertiary: Color
    let tertiaryContainer: Color
    let onTertiaryContainer: Color
    let surface: Color
    let surfaceContainerLow: Color
    let surfaceContainerHigh: Color
    let surfaceContainerHighest: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let outline: Color
    let outlineVariant: Color
    let error: Color
    let onError: Color
    let errorContainer: Color
    let onErrorContainer: Color
    let success: Color
    let onSuccess: Color
    let warning: Color
    let onWarning: Color
    let warningContainer: Color
    let onWarningContainer: Color

    static let light = BasketPalette(
        primary: Color(hex: 0x1E6B3F),
        onPrimary: Color(hex: 0xFFFFFF),
        primaryContainer: Color(hex: 0xA8F5C0),
        onPrimaryContainer: Color(hex: 0x00210E),
        secondary: Color(hex: 0x4F6353),
        onSecondary: Color(hex: 0xFFFFFF),
        secondaryContainer: Color(hex: 0xD2E8D4),
        onSecondaryContainer: Color(hex: 0x0D1F12),
        tertiary: Color(hex: 0x3A646F),
        onTertiary: Color(hex: 0xFFFFFF),
        tertiaryContainer: Color(hex: 0xBEEAF6),
        onTertiaryContainer: Color(hex: 0x001F26),
        surface: Color(hex: 0xF6FBF3),
        surfaceContainerLow: Color(hex: 0xF0F5ED),
        surfaceContainerHigh: Color(hex: 0xE5EAE2),
        surfaceContainerHighest: Color(hex: 0xDFE4DC),
        onSurface: Color(hex: 0x181D18),
        onSurfaceVariant: Color(hex: 0x414941),
        outline: Color(hex: 0x717970),
        outlineVariant: Color(hex: 0xC1C9BE),
        error: Color(hex: 0xBA1A1A),
        onError: Color(hex: 0xFFFFFF),
        errorContainer: Color(hex: 0xFFDAD6),
        onErrorContainer: Color(hex: 0x410002),
        success: Color(hex: 0x2E7D32),
        onSuccess: Color(hex: 0xFFFFFF),
        warning: Color(hex: 0x7A5900),
        onWarning: Color(hex: 0xFFFFFF),
        warningContainer: Color(hex: 0xFFDF9E),
        onWarningContainer: Color(hex: 0x261900)
    )

    static let dark = BasketPalette(
        primary: Color(hex: 0x8DD8A5),
        onPrimary: Color(hex: 0x003919),
        primaryContainer: Color(hex: 0x005229),
        onPrimaryContainer: Color(hex: 0xA8F5C0),
        secondary: Color(hex: 0xB6CCB8),
        onSecondary: Color(hex: 0x223527),
        secondaryContainer: Color(hex: 0x374B3B),
        onSecondaryContainer: Color(hex: 0xD2E8D4),
        tertiary: Color(hex: 0xA2CDD9),
        onTertiary: Color(hex: 0x00363F),
        tertiaryContainer: Color(hex: 0x204C56),
        onTertiaryContainer: Color(hex: 0xBEEAF6),
        surface: Color(hex: 0x101410),
        surfaceContainerLow: Color(hex: 0x181D18),
        surfaceContainerHigh: Color(hex: 0x272B27),
        surfaceContainerHighest: Color(hex: 0x323632),
        onSurface: Color(hex: 0xDFE4DC),
        onSurfaceVariant: Color(hex: 0xC1C9BE),
        outline: Color(hex: 0x8B938A),
        outlineVariant: Color(hex: 0x414941),
        error: Color(hex: 0xFFB4AB),
        onError: Color(hex: 0x690005),
        errorContainer: Color(hex: 0x93000A),
        onErrorContainer: Color(hex: 0xFFDAD6),
        success: Color(hex: 0x7CD98A),
        onSuccess: Color(hex: 0x003912),
        warning: Color(hex: 0xF5BE48),
        onWarning: Color(hex: 0x402D00),
        warningContainer: Color(hex: 0x5C4300),
        onWarningContainer: Color(hex: 0xFFDF9E)
    )

    static func resolve(_ scheme: ColorScheme) -> BasketPalette { scheme == .dark ? .dark : .light }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Adaptive colours usable without reading the environment (Asset-catalog-free).
enum BasketColor {
    static let primary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x8DD8A5) : UIColor(hex: 0x1E6B3F) })
    static let onPrimary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x003919) : UIColor(hex: 0xFFFFFF) })
    static let primaryContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x005229) : UIColor(hex: 0xA8F5C0) })
    static let onPrimaryContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xA8F5C0) : UIColor(hex: 0x00210E) })
    static let secondary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xB6CCB8) : UIColor(hex: 0x4F6353) })
    static let onSecondary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x223527) : UIColor(hex: 0xFFFFFF) })
    static let secondaryContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x374B3B) : UIColor(hex: 0xD2E8D4) })
    static let onSecondaryContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xD2E8D4) : UIColor(hex: 0x0D1F12) })
    static let tertiary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xA2CDD9) : UIColor(hex: 0x3A646F) })
    static let onTertiary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x00363F) : UIColor(hex: 0xFFFFFF) })
    static let tertiaryContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x204C56) : UIColor(hex: 0xBEEAF6) })
    static let onTertiaryContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xBEEAF6) : UIColor(hex: 0x001F26) })
    static let surface = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x101410) : UIColor(hex: 0xF6FBF3) })
    static let surfaceContainerLow = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x181D18) : UIColor(hex: 0xF0F5ED) })
    static let surfaceContainerHigh = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x272B27) : UIColor(hex: 0xE5EAE2) })
    static let surfaceContainerHighest = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x323632) : UIColor(hex: 0xDFE4DC) })
    static let onSurface = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xDFE4DC) : UIColor(hex: 0x181D18) })
    static let onSurfaceVariant = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xC1C9BE) : UIColor(hex: 0x414941) })
    static let outline = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x8B938A) : UIColor(hex: 0x717970) })
    static let outlineVariant = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x414941) : UIColor(hex: 0xC1C9BE) })
    static let error = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xFFB4AB) : UIColor(hex: 0xBA1A1A) })
    static let onError = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x690005) : UIColor(hex: 0xFFFFFF) })
    static let errorContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x93000A) : UIColor(hex: 0xFFDAD6) })
    static let onErrorContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xFFDAD6) : UIColor(hex: 0x410002) })
    static let success = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x7CD98A) : UIColor(hex: 0x2E7D32) })
    static let onSuccess = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x003912) : UIColor(hex: 0xFFFFFF) })
    static let warning = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xF5BE48) : UIColor(hex: 0x7A5900) })
    static let onWarning = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x402D00) : UIColor(hex: 0xFFFFFF) })
    static let warningContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x5C4300) : UIColor(hex: 0xFFDF9E) })
    static let onWarningContainer = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xFFDF9E) : UIColor(hex: 0x261900) })
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
