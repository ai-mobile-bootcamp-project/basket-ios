import Foundation
import Combine

@MainActor final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var theme: BasketThemeMode = .system

    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    @Published var moveTickedDown: Bool {
        didSet { defaults.set(moveTickedDown, forKey: Keys.moveTickedDown) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let language = "settings.language"
        static let moveTickedDown = "settings.moveTickedDown"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedLanguage = defaults.string(forKey: Keys.language) ?? AppLanguage.system.rawValue
        self.language = AppLanguage(rawValue: storedLanguage) ?? .system
        self.moveTickedDown = defaults.object(forKey: Keys.moveTickedDown) as? Bool ?? true
    }

    var locale: Locale {
        language == .system ? .autoupdatingCurrent : Locale(identifier: language.rawValue)
    }
}
