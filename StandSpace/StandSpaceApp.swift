import SwiftUI

@main
struct StandSpaceApp: App {
    @StateObject private var store = DashboardStore()
    @AppStorage("standspace.app.language")
    private var languageRawValue = StandSpaceAppLanguage.system.rawValue

    private var language: StandSpaceAppLanguage {
        StandSpaceAppLanguage(rawValue: languageRawValue) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, language.locale)
                .preferredColorScheme(.dark)
        }
    }
}
