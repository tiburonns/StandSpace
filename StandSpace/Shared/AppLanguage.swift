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

enum StandSpaceBatteryCopyState: CaseIterable {
    case charging
    case full
    case unplugged
    case unknown
}

enum StandSpaceLocalizedCopy {
    static func batteryState(
        _ state: StandSpaceBatteryCopyState,
        language: StandSpaceAppLanguage
    ) -> String {
        switch state {
        case .charging:
            return language.text(
                english: "Charging",
                spanish: "Cargando"
            )
        case .full:
            return language.text(
                english: "Fully charged",
                spanish: "Carga completa"
            )
        case .unplugged:
            return language.text(
                english: "On battery",
                spanish: "Usando batería"
            )
        case .unknown:
            return language.text(
                english: "Unknown state",
                spanish: "Estado desconocido"
            )
        }
    }

    static func textModuleDefaultTitle(
        language: StandSpaceAppLanguage
    ) -> String {
        language.text(
            english: "Note",
            spanish: "Nota"
        )
    }

    static func textModulePlaceholder(
        language: StandSpaceAppLanguage
    ) -> String {
        language.text(
            english: "Your text here",
            spanish: "Tu texto aquí"
        )
    }

    static func newerSchemaWarning(
        language: StandSpaceAppLanguage
    ) -> String {
        language.text(
            english: "This configuration was created by a newer version. StandSpace will not overwrite it; update the app or explicitly reset Spaces.",
            spanish: "Se detectó una configuración creada por una versión más nueva. StandSpace no la sobrescribirá; actualiza la app o restablece los Spaces explícitamente."
        )
    }
}

