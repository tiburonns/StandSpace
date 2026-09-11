import SwiftUI

@main
struct StandSpaceApp: App {
    @StateObject private var store = DashboardStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
