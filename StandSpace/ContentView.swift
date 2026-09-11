import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: DashboardStore

    var body: some View {
        ZStack {
            store.backgroundStyle.background
                .ignoresSafeArea()

            DashboardView()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = store.keepScreenAwake
        }
        .onChange(of: store.keepScreenAwake) { _, value in
            UIApplication.shared.isIdleTimerDisabled = value
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
