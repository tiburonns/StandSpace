import Foundation

@main
struct LanguageIntegration {
    static func main() throws {
        try expect(
            StandSpaceAppLanguage.system.resolvedCode(
                preferredLanguages: ["es-MX", "en-US"]
            ) == "es",
            "System language did not resolve es-MX to Spanish"
        )
        try expect(
            StandSpaceAppLanguage.system.resolvedCode(
                preferredLanguages: ["fr-FR", "en-US"]
            ) == "en",
            "Unsupported system language did not fall back to English"
        )
        try expect(
            StandSpaceAppLanguage.english.text(
                english: "Clock",
                spanish: "Reloj"
            ) == "Clock",
            "Explicit English did not stay English"
        )
        try expect(
            StandSpaceAppLanguage.spanish.text(
                english: "Clock",
                spanish: "Reloj"
            ) == "Reloj",
            "Explicit Spanish did not stay Spanish"
        )

        try expect(
            ModuleKind.clock.title(language: .english) == "Clock"
                && ModuleKind.clock.title(language: .spanish) == "Reloj",
            "Module title localization is incomplete"
        )
        try expect(
            ModuleKind.storage.subtitle(language: .english)
                != ModuleKind.storage.subtitle(language: .spanish),
            "Module subtitle localization is incomplete"
        )
        try expect(
            StandSpaceKind.kitchen.title(language: .english) == "Kitchen"
                && StandSpaceKind.kitchen.title(language: .spanish) == "Cocina",
            "Space names are not bilingual"
        )
        try expect(
            LandscapePreset.adaptive.title(language: .english) == "Adaptive"
                && LandscapePreset.adaptive.title(language: .spanish) == "Adaptativo",
            "Landscape preset localization is incomplete"
        )
        try expect(
            ModuleStyle.glass.title(language: .english) == "Glass"
                && ModuleStyle.glass.title(language: .spanish) == "Cristal",
            "Module styles are not bilingual"
        )
        try expect(
            BoardBackgroundStyle.midnight.title(language: .english) == "Midnight"
                && BoardBackgroundStyle.midnight.title(language: .spanish) == "Medianoche",
            "Background names are not bilingual"
        )

        try expect(
            StandSpaceLocalizedCopy.batteryState(
                .charging,
                language: .english
            ) == "Charging"
                && StandSpaceLocalizedCopy.batteryState(
                    .charging,
                    language: .spanish
                ) == "Cargando",
            "Battery state copy is not bilingual"
        )
        try expect(
            StandSpaceLocalizedCopy.textModulePlaceholder(
                language: .english
            ) == "Your text here"
                && StandSpaceLocalizedCopy.textModulePlaceholder(
                    language: .spanish
                ) == "Tu texto aquí",
            "Text-module defaults are not bilingual"
        )
        try expect(
            StandSpaceLocalizedCopy.newerSchemaWarning(
                language: .english
            ) != StandSpaceLocalizedCopy.newerSchemaWarning(
                language: .spanish
            ),
            "Persistence warning is not bilingual"
        )

        print("PASS: StandSpace language resolution and bilingual model metadata")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) throws {
        guard condition() else {
            throw TestFailure(message)
        }
    }
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}
