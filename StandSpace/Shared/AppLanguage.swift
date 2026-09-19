import Foundation

enum StandSpaceAppLanguage: String, CaseIterable, Identifiable {
    static let storageKey = "standspace.app.language"

    case system
    case english
    case spanish

    var id: String { rawValue }

    static var current: StandSpaceAppLanguage {
        let raw = UserDefaults.standard.string(forKey: storageKey)
        return StandSpaceAppLanguage(rawValue: raw ?? system.rawValue) ?? .system
    }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .spanish:
            return Locale(identifier: "es")
        }
    }

    var optionTitle: String {
        switch self {
        case .system:
            return text(english: "System", spanish: "Sistema")
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }

    func resolvedCode(
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String {
        switch self {
        case .english:
            return "en"
        case .spanish:
            return "es"
        case .system:
            let first = preferredLanguages.first?.lowercased() ?? "en"
            return first.hasPrefix("es") ? "es" : "en"
        }
    }

    func text(
        english: String,
        spanish: String,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String {
        resolvedCode(preferredLanguages: preferredLanguages) == "es"
            ? spanish
            : english
    }
}
