import SwiftUI

@main
struct StandSpaceApp: App {
    @StateObject private var store = DashboardStore()
    @AppStorage(StandSpaceAppLanguage.storageKey)
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
