import Foundation

enum StandSpaceAppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case spanish

    var id: String { rawValue }

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
            return "Sistema"
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }
}
