import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english = "en", spanish = "es", arabic = "ar"

    var id: String { rawValue }

    /// Locale identifier for an explicit choice; nil follows the device language.
    var localeIdentifier: String? {
        self == .system ? nil : rawValue
    }
}

enum L10n {
    /// Localization bundles for the languages the app ships, keyed by language code.
    private static let bundles: [String: Bundle] = {
        var result: [String: Bundle] = [:]
        for code in ["en", "es", "ar"] {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                result[code] = bundle
            }
        }
        return result
    }()

    private static func languageCode(for locale: Locale) -> String {
        let identifier = locale.identifier
        let end = identifier.firstIndex(where: { $0 == "_" || $0 == "-" || $0 == "@" }) ?? identifier.endIndex
        return String(identifier[..<end]).lowercased()
    }

    private static func bundle(for locale: Locale) -> Bundle {
        bundles[languageCode(for: locale)] ?? Bundle.main
    }

    /// Localized string for `key` in the language of `locale` (en/es/ar .lproj; anything else → Bundle.main).
    static func tr(_ key: String, _ locale: Locale) -> String {
        let fallback = bundles["en"]?.localizedString(forKey: key, value: key, table: nil) ?? key
        return bundle(for: locale).localizedString(forKey: key, value: fallback, table: nil)
    }

    /// String(format:) with the localized format for `key`; works for Localizable.stringsdict plural keys.
    /// Numbers are always Western digits.
    static func format(_ key: String, _ locale: Locale, _ args: CVarArg...) -> String {
        String(format: tr(key, locale), locale: BasketRules.latinDigitsLocale(locale), arguments: args)
    }
}
